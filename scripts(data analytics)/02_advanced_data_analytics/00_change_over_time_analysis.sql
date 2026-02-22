/*
===================================================================
Change-Over-Time Analysis
===================================================================
Script Purpose:
	This script measures how much relevant business metrics change
	over time.
===================================================================
*/
-- Is profit consistently increasing over the years,
-- and what other metrics are responsible for this performance?
SELECT
	YEAR(order_date) AS order_date_year,
	COUNT(DISTINCT customer_key) AS total_customers_ordered,
	COUNT(DISTINCT product_key) AS total_products_ordered,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(gross_sales) AS total_gross_sales,
	SUM(net_sales) AS total_net_sales,
	SUM(profit) AS total_profit,
	ROUND(CAST(SUM(gross_sales) AS FLOAT)/COUNT(DISTINCT order_id), 2) AS avg_gross_sales_per_order,
	ROUND(CAST(SUM(gross_sales) AS FLOAT)/SUM(quantity), 2) AS weighted_avg_price,
	ROUND(CAST(SUM(profit) AS FLOAT)/SUM(quantity), 2) AS avg_profit_per_quantity,
	ROUND((CAST(SUM(profit) AS FLOAT)/SUM(gross_sales)) * 100, 2) AS profit_margin_pct,
	ROUND((CAST(SUM(gross_sales * discount) AS FLOAT)/SUM(gross_sales)) * 100, 2) AS weighted_discount_pct
FROM gold.fact_orders
GROUP BY YEAR(order_date)
ORDER BY order_date_year;


-- What drives profit change year-over-year?
WITH current_yr_metrics AS
(
SELECT
	YEAR(order_date) AS order_date_year,
	SUM(profit) AS profit,
	SUM(net_sales) AS net_sales,
	SUM(quantity) AS qty,
	SUM(gross_sales)/SUM(quantity) AS gross_price,
	SUM(net_sales)/SUM(quantity) AS net_price,
	SUM(profit)/SUM(quantity) AS profit_per_qty,
	SUM(net_sales - profit)/SUM(quantity) AS cost_per_qty,
	SUM(discount * gross_sales)/SUM(gross_sales) AS discount_rate
FROM gold.fact_orders
GROUP BY YEAR(order_date)
)
, previous_yr_metric AS
(
SELECT
	order_date_year,
	LAG(profit) OVER(ORDER BY order_date_year) AS prev_profit,
	LAG(qty) OVER(ORDER BY order_date_year) AS prev_qty,
	LAG(profit_per_qty) OVER(ORDER BY order_date_year) AS prev_profit_per_qty,
	LAG(cost_per_qty) OVER(ORDER BY order_date_year) AS prev_cost_per_qty,
	LAG(gross_price) OVER(ORDER BY order_date_year) AS prev_gross_price,
	LAG(discount_rate) OVER(ORDER BY order_date_year) AS prev_discount_rate
FROM current_yr_metrics
)
, profit_bridge AS
(
SELECT
	c.order_date_year,
	c.profit,
	c.profit - p.prev_profit AS profit_change,
	(c.qty - p.prev_qty) * p.prev_profit_per_qty AS volume_effect,
	(c.gross_price - p.prev_gross_price) * (1 - c.discount_rate) * (c.qty) AS price_effect,
	-(c.discount_rate - p.prev_discount_rate) * p.prev_gross_price * c.qty AS discount_effect,
	-(c.cost_per_qty - p.prev_cost_per_qty) * c.qty AS cost_effect
FROM current_yr_metrics c 
LEFT JOIN previous_yr_metric p
ON p.order_date_year = c.order_date_year
)
, profit_change_diff AS
(
SELECT
	order_date_year,
	profit_change,
	volume_effect,
	price_effect,
	discount_effect,
	cost_effect,
	ROUND(CAST(volume_effect + price_effect + discount_effect + cost_effect AS FLOAT), 2) AS total_effects,
	ROUND(CAST(profit_change - (volume_effect + price_effect + discount_effect + cost_effect) AS FLOAT), 2) AS variance
FROM profit_bridge
)
, classified AS
(
SELECT
	order_date_year,
	profit_change,
	volume_effect,
	price_effect,
	discount_effect,
	cost_effect,
	total_effects,
	variance,
	CASE
		WHEN ABS(volume_effect) >= ABS(price_effect) 
		AND ABS(volume_effect) >= ABS(discount_effect) 
		AND ABS(volume_effect) >= ABS(cost_effect)
		THEN 'Volume'

		WHEN ABS(price_effect) >= ABS(discount_effect)
		AND ABS(price_effect) >= ABS(cost_effect)
		THEN 'Price'

		WHEN ABS(discount_effect) >= ABS(cost_effect)
		THEN 'Discount'

		WHEN profit_change IS NULL THEN NULL

		ELSE 'Cost'
	END AS highest_driver
FROM profit_change_diff
)
SELECT
	c.order_date_year,
	cy.profit,
	cy.net_sales,
	cy.qty,
	ROUND(CAST(cy.profit_per_qty AS FLOAT), 2) AS profit_per_qty,
	ROUND(CAST(cy.cost_per_qty AS FLOAT), 2) AS cost_per_qty,
	ROUND(CAST(cy.gross_price AS FLOAT), 2) AS gross_price,
	ROUND(CAST(cy.discount_rate AS FLOAT), 2) AS discount_rate,
	c.profit_change,
	ROUND(CAST(c.volume_effect AS FLOAT), 2) AS volume_effect,
	ROUND(CAST(c.price_effect AS FLOAT), 2) AS price_effect,
	ROUND(CAST(c.discount_effect AS FLOAT), 2) AS discount_effect,
	ROUND(CAST(c.cost_effect AS FLOAT), 2) AS cost_effect,
	c.total_effects,
	c.highest_driver,
	CASE
		WHEN c.profit_change IS NULL THEN NULL
		WHEN ABS(c.profit_change) < 0.01 THEN 'Stable'

		WHEN c.profit_change > 0 AND c.highest_driver = 'Volume' AND c.volume_effect > 0 THEN 'Volume-Led Growth'
		WHEN c.profit_change > 0 AND c.highest_driver = 'Volume' AND c.volume_effect < 0 THEN 'Growth Despite Volume Decline'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Volume' AND c.volume_effect < 0 THEN 'Volume-Led Decline'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Volume' AND c.volume_effect > 0 THEN 'Decline Despite Volume Growth'

		WHEN c.profit_change > 0 AND c.highest_driver = 'Price' AND c.price_effect > 0 THEN 'Price-Led Growth'
		WHEN c.profit_change > 0 AND c.highest_driver = 'Price' AND c.price_effect < 0 THEN 'Growth Despite Price Decline'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Price' AND c.price_effect < 0 THEN 'Price Erosion'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Price' AND c.price_effect > 0 THEN 'Decline Despite Price Increase'

		WHEN c.profit_change > 0 AND c.highest_driver = 'Discount' AND c.discount_effect > 0 THEN 'Discount-Reduction Growth'
		WHEN c.profit_change > 0 AND c.highest_driver = 'Discount' AND c.discount_effect < 0 THEN 'Growth Despite Discount Erosion'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Discount' AND c.discount_effect < 0 THEN 'Discount-Driven Erosion'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Discount' AND c.discount_effect > 0 THEN 'Decline Despite Discount Reduction'

		WHEN c.profit_change > 0 AND c.highest_driver = 'Cost' AND c.cost_effect > 0 THEN 'Cost-Reduction Growth'
		WHEN c.profit_change > 0 AND c.highest_driver = 'Cost' AND c.cost_effect < 0 THEN 'Growth Despite Cost Inflation'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Cost' AND c.cost_effect < 0 THEN 'Cost-Inflation Impact'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Cost' AND c.cost_effect > 0 THEN 'Decline Despite Cost Reduction'

		WHEN c.highest_driver IS NULL THEN NULL
	END AS profit_driver
FROM classified c
LEFT JOIN current_yr_metrics cy
ON c.order_date_year = cy.order_date_year
ORDER BY c.order_date_year;


-- How much are relevant business metrics changing month-over-month?
SELECT
	DATETRUNC(month, order_date) AS order_date_month,
	COUNT(DISTINCT customer_key) AS total_customers_ordered,
	COUNT(DISTINCT product_key) AS total_products_ordered,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(gross_sales) AS total_gross_sales,
	SUM(net_sales) AS total_net_sales,
	SUM(profit) AS total_profit,
	ROUND(CAST(SUM(gross_sales) AS FLOAT)/COUNT(DISTINCT order_id), 2) AS avg_gross_sales_per_order,
	ROUND(CAST(SUM(gross_sales) AS FLOAT)/SUM(quantity), 2) AS weighted_avg_price,
	ROUND(CAST(SUM(profit) AS FLOAT)/SUM(quantity), 2) AS avg_profit_per_quantity,
	ROUND((CAST(SUM(profit) AS FLOAT)/SUM(gross_sales)) * 100, 2) AS profit_margin_pct,
	ROUND((CAST(SUM(gross_sales * discount) AS FLOAT)/SUM(gross_sales)) * 100, 2) AS weighted_discount_pct
FROM gold.fact_orders
GROUP BY DATETRUNC(month, order_date)
ORDER BY order_date_month;


-- Is the profit generated by each category increasing consistently over the years,
-- and what other metrics play a role in the observed trend in profit?
SELECT
	YEAR(fo.order_date) AS order_date_year,
	dp.category,
	COUNT(DISTINCT fo.customer_key) AS total_customers_ordered,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(gross_sales) AS total_gross_sales,
	SUM(net_sales) AS total_net_sales,
	SUM(profit) AS total_profit,
	ROUND(CAST(SUM(gross_sales) AS FLOAT)/COUNT(DISTINCT order_id), 2) AS avg_gross_sales_per_order,
	ROUND(CAST(SUM(gross_sales) AS FLOAT)/SUM(quantity), 2) AS weighted_avg_price,
	ROUND(CAST(SUM(profit) AS FLOAT)/SUM(quantity), 2) AS avg_profit_per_quantity,
	ROUND((CAST(SUM(profit) AS FLOAT)/SUM(gross_sales)) * 100, 2) AS profit_margin_pct,
	ROUND((CAST(SUM(gross_sales * discount) AS FLOAT)/SUM(gross_sales)) * 100, 2) AS weighted_discount_pct
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY YEAR(fo.order_date), dp.category
ORDER BY dp.category, order_date_year;


-- Across the years, what drives profit change in each category of product?
WITH current_metrics AS
(	
SELECT
	YEAR(fo.order_date) AS order_date_year,
	dp.category,
	SUM(profit) AS profit,
	SUM(net_sales) AS net_sales,
	SUM(quantity) AS qty,
	SUM(gross_sales)/SUM(quantity) AS gross_price,
	SUM(net_sales)/SUM(quantity) AS net_price,
	SUM(profit)/SUM(quantity) AS profit_per_qty,
	SUM(net_sales - profit)/SUM(quantity) AS cost_per_qty,
	SUM(discount * gross_sales)/SUM(gross_sales) AS discount_rate
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY YEAR(fo.order_date), dp.category
)
, previous_metrics AS
(
SELECT
	order_date_year,
	category,
	LAG(profit) OVER(PARTITION BY category ORDER BY order_date_year) AS prev_profit,
	LAG(qty) OVER(PARTITION BY category ORDER BY order_date_year) AS prev_qty,
	LAG(profit_per_qty) OVER(PARTITION BY category ORDER BY order_date_year) AS prev_profit_per_qty,
	LAG(cost_per_qty) OVER(PARTITION BY category ORDER BY order_date_year) AS prev_cost_per_qty,
	LAG(gross_price) OVER(PARTITION BY category ORDER BY order_date_year) AS prev_gross_price,
	LAG(discount_rate) OVER(PARTITION BY category ORDER BY order_date_year) AS prev_discount_rate
FROM current_metrics
)
, profit_bridge AS
(
SELECT
	c.order_date_year,
	c.category,
	c.profit,
	c.profit - p.prev_profit AS profit_change,
	(c.qty - p.prev_qty) * p.prev_profit_per_qty AS volume_effect,
	(c.gross_price - p.prev_gross_price) * (1 - c.discount_rate) * (c.qty) AS price_effect,
	-(c.discount_rate - p.prev_discount_rate) * p.prev_gross_price * c.qty AS discount_effect,
	-(c.cost_per_qty - p.prev_cost_per_qty) * c.qty AS cost_effect
FROM current_metrics c
LEFT JOIN previous_metrics p
ON c.order_date_year = p.order_date_year
AND c.category = p.category
)
, profit_change_diff AS
(
SELECT
	order_date_year,
	category,
	profit_change,
	volume_effect,
	price_effect,
	discount_effect,
	cost_effect,
	ROUND(CAST(volume_effect + price_effect + discount_effect + cost_effect AS FLOAT), 2) AS total_effects,
	ROUND(CAST(profit_change - (volume_effect + price_effect + discount_effect + cost_effect) AS FLOAT), 2) AS variance
FROM profit_bridge
)
, classified AS
(
SELECT
	order_date_year,
	category,
	profit_change,
	volume_effect,
	price_effect,
	discount_effect,
	cost_effect,
	total_effects,
	variance,
	CASE
		WHEN ABS(volume_effect) >= ABS(price_effect)
		AND ABS(volume_effect) >= ABS(discount_effect)
		AND ABS(volume_effect) >= ABS(cost_effect)
		THEN 'Volume'

		WHEN ABS(price_effect) >= ABS(discount_effect)
		AND ABS(price_effect) >= ABS(cost_effect)
		THEN 'Price'

		WHEN ABS(discount_effect) >= ABS(cost_effect)
		THEN 'Discount'

		WHEN profit_change IS NULL THEN NULL

		ELSE 'Cost'
	END AS highest_driver
FROM profit_change_diff
)
SELECT
	c.order_date_year,
	c.category,
	cm.profit,
	cm.net_sales,
	cm.qty,
	ROUND(CAST(cm.profit_per_qty AS FLOAT), 2) AS profit_per_qty,
	ROUND(CAST(cm.cost_per_qty AS FLOAT), 2) AS cost_per_qty,
	ROUND(CAST(cm.gross_price AS FLOAT), 2) AS gross_price,
	ROUND(CAST(cm.discount_rate AS FLOAT), 2) AS discount_rate,
	c.profit_change,
	ROUND(CAST(c.volume_effect AS FLOAT), 2) AS volume_effect,
	ROUND(CAST(c.price_effect AS FLOAT), 2) AS price_effect,
	ROUND(CAST(c.discount_effect AS FLOAT), 2) AS discount_effect,
	ROUND(CAST(c.cost_effect AS FLOAT), 2) AS cost_effect,
	c.total_effects,
	c.highest_driver,
	CASE
		WHEN c.profit_change IS NULL THEN NULL
		WHEN ABS(c.profit_change) < 0.01 THEN 'Stable'

		WHEN c.profit_change > 0 AND c.highest_driver = 'Volume' AND c.volume_effect > 0 THEN 'Volume-Led Growth'
		WHEN c.profit_change > 0 AND c.highest_driver = 'Volume' AND c.volume_effect < 0 THEN 'Growth Despite Volume Decline'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Volume' AND c.volume_effect < 0 THEN 'Volume-Led Decline'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Volume' AND c.volume_effect > 0 THEN 'Decline Despite Volume Growth'

		WHEN c.profit_change > 0 AND c.highest_driver = 'Price' AND c.price_effect > 0 THEN 'Price-Led Growth'
		WHEN c.profit_change > 0 AND c.highest_driver = 'Price' AND c.price_effect < 0 THEN 'Growth Despite Price Decline'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Price' AND c.price_effect < 0 THEN 'Price Erosion'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Price' AND c.price_effect > 0 THEN 'Decline Despite Price Increase'

		WHEN c.profit_change > 0 AND c.highest_driver = 'Discount' AND c.discount_effect > 0 THEN 'Discount-Reduction Growth'
		WHEN c.profit_change > 0 AND c.highest_driver = 'Discount' AND c.discount_effect < 0 THEN 'Growth Despite Discount Erosion'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Discount' AND c.discount_effect < 0 THEN 'Discount-Driven Erosion'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Discount' AND c.discount_effect > 0 THEN 'Decline Despite Discount Reduction'

		WHEN c.profit_change > 0 AND c.highest_driver = 'Cost' AND c.cost_effect > 0 THEN 'Cost-Reduction Growth'
		WHEN c.profit_change > 0 AND c.highest_driver = 'Cost' AND c.cost_effect < 0 THEN 'Growth Despite Cost Inflation'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Cost' AND c.cost_effect < 0 THEN 'Cost-Inflation Impact'
		WHEN c.profit_change < 0 AND c.highest_driver = 'Cost' AND c.cost_effect > 0 THEN 'Decline Despite Cost Reduction'

		WHEN c.highest_driver IS NULL THEN NULL
	END AS profit_driver
FROM classified c
LEFT JOIN current_metrics cm
ON c.order_date_year = cm.order_date_year
AND c.category = cm.category
ORDER BY cm.category, cm.order_date_year;


-- Within each category, Is the profit generated by each subcategory increasing consistently over the years,
-- and what other metrics play a role in the observed trend in profit?
SELECT
	YEAR(fo.order_date) AS order_date_year,
	dp.category,
	dp.sub_category,
	COUNT(DISTINCT fo.customer_key) AS total_customers_ordered,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(gross_sales) AS total_gross_sales,
	SUM(net_sales) AS total_net_sales,
	SUM(profit) AS total_profit,
	ROUND(CAST(SUM(gross_sales) AS FLOAT)/COUNT(DISTINCT order_id), 2) AS avg_gross_sales_per_order,
	ROUND(CAST(SUM(gross_sales) AS FLOAT)/SUM(quantity), 2) AS weighted_avg_price,
	ROUND(CAST(SUM(profit) AS FLOAT)/SUM(quantity), 2) AS avg_profit_per_quantity,
	ROUND((CAST(SUM(profit) AS FLOAT)/SUM(gross_sales)) * 100, 2) AS profit_margin_pct,
	ROUND((CAST(SUM(gross_sales * discount) AS FLOAT)/SUM(gross_sales)) * 100, 2) AS weighted_discount_pct
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY 
	YEAR(fo.order_date), 
	dp.category, 
	dp.sub_category
ORDER BY 
	dp.category, 
	dp.sub_category, 
	order_date_year;


-- Within each category & subcategory, Is the profit generated by each product increasing consistently over the years,
-- and what other metrics play a role in the observed trend in profit?
SELECT
	YEAR(fo.order_date) AS order_date_year,
	dp.category,
	dp.sub_category,
	dp.product_name,
	COUNT(DISTINCT fo.customer_key) AS total_customers_ordered,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(gross_sales) AS total_gross_sales,
	SUM(net_sales) AS total_net_sales,
	SUM(profit) AS total_profit,
	ROUND(CAST(SUM(gross_sales) AS FLOAT)/COUNT(DISTINCT order_id), 2) AS avg_gross_sales_per_order,
	ROUND(CAST(SUM(gross_sales) AS FLOAT)/SUM(quantity), 2) AS weighted_avg_price,
	ROUND(CAST(SUM(profit) AS FLOAT)/SUM(quantity), 2) AS avg_profit_per_quantity,
	ROUND((CAST(SUM(profit) AS FLOAT)/SUM(gross_sales)) * 100, 2) AS profit_margin_pct,
	ROUND((CAST(SUM(gross_sales * discount) AS FLOAT)/SUM(gross_sales)) * 100, 2) AS weighted_discount_pct
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY 
	YEAR(fo.order_date), 
	dp.category, 
	dp.sub_category,
	dp.product_name
ORDER BY 
	dp.category, 
	dp.sub_category,
	dp.product_name,
	order_date_year; 
