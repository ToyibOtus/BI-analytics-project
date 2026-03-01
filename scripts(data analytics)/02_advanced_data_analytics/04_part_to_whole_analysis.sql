/*
==========================================================================
Part-to-Whole Analysis
==========================================================================
Script Purpose:
	This scripts performs part-to-whole analysis. It shows the percentage
	distributions or contibutions of metrics across various dimensions.
==========================================================================
*/
-- What is the biggest driver of profit margin erosion?
WITH product_metrics AS
(
SELECT
	dp.product_name,
	SUM(fo.gross_sales)/SUM(fo.quantity) AS avg_gross_price_per_qty,
	SUM(fo.net_sales)/SUM(fo.quantity) AS avg_net_sales_per_qty,
	(SUM(fo.net_sales) - SUM(fo.profit))/SUM(fo.quantity) AS avg_cost_per_qty,
	SUM(fo.profit)/NULLIF(SUM(fo.net_sales), 0) AS profit_margin,
	COUNT(*) OVER() AS total_products
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.product_name
)
, product_segmentation AS
(
SELECT
	product_name,
	avg_gross_price_per_qty,
	avg_net_sales_per_qty,
	avg_cost_per_qty,
	total_products,
	CASE
		WHEN avg_gross_price_per_qty < avg_cost_per_qty THEN 'Price-Driven Erosion'
		WHEN avg_gross_price_per_qty > avg_cost_per_qty AND avg_net_sales_per_qty < avg_cost_per_qty THEN 'Discount-Driven Erosion'
		ELSE 'Unknown'
	END AS product_segment
FROM product_metrics
WHERE profit_margin < 0
)
SELECT
	product_segment,
	COUNT(*) AS products_per_segment,
	ROUND((CAST(COUNT(*) AS FLOAT)/MAX(total_products)) * 100, 2) AS pct_product_count_cont
FROM product_segmentation
GROUP BY product_segment;


-- How much impact does discount have on key business metrics relative to full price?
WITH metrics AS
(
SELECT
	CASE
		WHEN discount = 0 THEN 'Full Price'
		ELSE 'Discounted'
	END AS sales_segment,
	SUM(gross_sales) AS total_gross_sales,
	SUM(net_sales) AS total_net_sales,
	SUM(quantity) AS total_qty,
	SUM(profit) AS total_profit
FROM gold.fact_orders
GROUP BY 
	CASE
		WHEN discount = 0 THEN 'Full Price'
		ELSE 'Discounted'
	END
)
, pct_share AS
(
SELECT
	sales_segment,
	total_qty,
	total_gross_sales,
	total_net_sales,
	total_profit,
	ROUND(CAST(total_profit AS FLOAT)/total_qty, 2) AS profit_per_qty,
	ROUND((CAST(total_qty AS FLOAT)/SUM(total_qty) OVER()) * 100, 2) AS qty_pct_share,
	ROUND((CAST(total_net_sales AS FLOAT)/SUM(total_net_sales) OVER()) * 100, 2) AS sales_pct_share,
	ROUND((CAST(total_profit AS FLOAT)/SUM(total_profit) OVER()) * 100, 2) AS profit_pct_share,
	total_profit/total_gross_sales AS profit_margin
FROM metrics
)
SELECT
	sales_segment,
	total_qty,
	total_gross_sales,
	total_net_sales,
	total_profit,
	profit_per_qty,
	profit_margin,
	qty_pct_share,
	sales_pct_share,
	profit_pct_share,
	ROUND((CAST(profit_per_qty - MAX(profit_per_qty) OVER() AS FLOAT)/MAX(profit_per_qty) OVER()) * 100, 2) AS profit_per_qty_pct_diff,
	ROUND((CAST(profit_margin - MAX(profit_margin) OVER() AS FLOAT)/MAX(profit_margin) OVER()) * 100, 2) AS profit_margin_pct_diff
FROM pct_share;


-- Across categories, how much of our realized revenue & profit come from discount transactions?
WITH category_metrics AS
(
SELECT
	dp.category,
	CASE
		WHEN fo.discount = 0 THEN 'Full Price'
		ELSE 'Discounted'
	END AS sales_segment,
	SUM(fo.net_sales) AS total_net_sales,
	SUM(fo.profit) AS total_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY 
	dp.category,
	CASE
		WHEN discount = 0 THEN 'Full Price'
		ELSE 'Discounted'
	END
)
SELECT
	category,
	sales_segment,
	total_net_sales,
	total_profit,
	ROUND((CAST(total_net_sales AS FLOAT)/SUM(total_net_sales) OVER(PARTITION BY category)) * 100, 2) AS sales_pct_share,
	ROUND((CAST(total_profit AS FLOAT)/SUM(total_profit) OVER(PARTITION BY category)) * 100, 2) AS profit_pct_share
FROM category_metrics
ORDER BY category, sales_segment DESC;


-- Which discount level brings the most revenue?
WITH discount_tier AS
(
SELECT
	net_sales,
	discount,
	CASE 
		WHEN discount = 0.00 THEN '0%'
		WHEN discount > 0.00 AND discount <= 0.10 THEN '1-10%'
		WHEN discount > 0.10 AND discount <= 0.20 THEN '11-20%'
		WHEN discount > 0.20 AND discount <= 0.30 THEN '21-30%'
		WHEN discount > 0.30 AND discount <= 0.40 THEN '31-40%'
		ELSE '41%+'
	END AS discount_tier
FROM gold.fact_orders
)
SELECT
	discount_tier,
	SUM(net_sales) AS total_sales,
	ROUND((CAST(SUM(net_sales) AS FLOAT)/SUM(SUM(net_sales)) OVER()) * 100, 2) AS sales_share_pct
FROM discount_tier
GROUP BY discount_tier
ORDER BY sales_share_pct DESC;


-- Which discount level brings the most profit?
WITH discount_tier AS
(
SELECT
	profit,
	discount,
	CASE 
		WHEN discount = 0.00 THEN '0%'
		WHEN discount > 0.00 AND discount <= 0.10 THEN '1-10%'
		WHEN discount > 0.10 AND discount <= 0.20 THEN '11-20%'
		WHEN discount > 0.20 AND discount <= 0.30 THEN '21-30%'
		WHEN discount > 0.30 AND discount <= 0.40 THEN '31-40%'
		ELSE '41%+'
	END AS discount_tier
FROM gold.fact_orders
)
SELECT
	discount_tier,
	SUM(profit) AS total_sales,
	ROUND((CAST(SUM(profit) AS FLOAT)/SUM(SUM(profit)) OVER()) * 100, 2) AS profit_share_pct
FROM discount_tier
GROUP BY discount_tier
ORDER BY profit_share_pct DESC;


-- Across categories, which discount dominates revenue? 
WITH category_metrics AS
(
SELECT
	dp.category,
	profit,
	CASE 
		WHEN discount = 0.00 THEN '0%'
		WHEN discount > 0.00 AND discount <= 0.10 THEN '1-10%'
		WHEN discount > 0.10 AND discount <= 0.20 THEN '11-20%'
		WHEN discount > 0.20 AND discount <= 0.30 THEN '21-30%'
		WHEN discount > 0.30 AND discount <= 0.40 THEN '31-40%'
		ELSE '41%+'
	END AS discount_tier
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
)
SELECT
	category,
	discount_tier,
	SUM(profit) AS total_profit,
	ROUND((CAST(SUM(profit) AS FLOAT)/SUM(SUM(profit)) OVER(PARTITION BY category)) * 100, 2) AS profit_share_pct
FROM category_metrics
GROUP BY category, discount_tier
ORDER BY category, profit_share_pct DESC;


-- Which market rely on discounting?
WITH country_sales_segment AS
(
SELECT
	dc.country,
	CASE
		WHEN discount = 0 THEN 'Full Price'
		ELSE 'Discounted'
	END AS sales_segment,
	net_sales
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key
)
SELECT
	country,
	sales_segment,
	SUM(net_sales) AS total_sales,
	ROUND((CAST(SUM(net_sales) AS FLOAT)/SUM(SUM(net_sales)) OVER(PARTITION BY country)) * 100, 2) AS sales_share_pct
FROM country_sales_segment
GROUP BY country, sales_segment
ORDER BY country, sales_share_pct DESC;


-- Are discounts driving our top-revenue generating customers?
WITH customer_rank AS
(
SELECT
	dc.customer_key,
	dc.first_name,
	dc.last_name,
	SUM(net_sales) AS total_sales,
	SUM(CASE WHEN discount = 0 THEN net_sales ELSE 0 END) AS full_priced_sales,
	SUM(CASE WHEN discount > 0 THEN net_sales ELSE 0 END) AS discounted_sales,
	ROUND(CAST(PERCENT_RANK() OVER(ORDER BY SUM(net_sales) DESC) AS FLOAT), 2) AS sales_rank
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key
GROUP BY
	dc.customer_key,
	dc.first_name,
	dc.last_name
)
, customer_segmentation AS
(
SELECT
	CONCAT_WS(' ', first_name, last_name) AS customer_name,
	full_priced_sales,
	discounted_sales,
	total_sales,
	CASE
		WHEN sales_rank <= 0.20 THEN 'Top 20%'
		WHEN sales_rank <= 0.50 THEN '21-50%'
		WHEN sales_rank <= 0.80 THEN '51-80%'
		ELSE '81+%'
	END AS customer_segment
FROM customer_rank
)
, percent_share AS
(
SELECT
	customer_segment,
	SUM(full_priced_sales) AS full_priced_sales,
	SUM(discounted_sales) AS discounted_sales,
	SUM(total_sales) AS total_sales,
	ROUND((CAST(SUM(full_priced_sales) AS FLOAT)/SUM(total_sales)) * 100, 2) AS full_priced_sales_share_pct,
	ROUND((CAST(SUM(discounted_sales) AS FLOAT)/SUM(total_sales)) * 100, 2) AS discounted_sales_share_pct
FROM customer_segmentation
GROUP BY customer_segment
)
SELECT
	customer_segment,
	full_priced_sales,
	discounted_sales,
	total_sales,
	full_priced_sales_share_pct,
	discounted_sales_share_pct,
	CASE
		WHEN full_priced_sales_share_pct > discounted_sales_share_pct THEN 'Full-Priced Driven'
		ELSE 'Discount Driven'
	END AS sales_segment
FROM percent_share
ORDER BY total_sales DESC;


-- Across the years & quarters, how much profit comes from discounted transactions?
WITH yearly_metrics AS
(
SELECT
	YEAR(order_date) AS order_date_year,
	DATEPART(quarter, order_date) AS quarters,
	SUM(CASE WHEN discount = 0 THEN profit ELSE 0 END) AS full_priced_profit,
	SUM(CASE WHEN discount > 0 THEN profit ELSE 0 END) AS discounted_profit,
	ROUND(CAST(SUM(CASE WHEN discount > 0 THEN discount * gross_sales ELSE 0 END) AS FLOAT)/
	SUM(CASE WHEN discount > 0 THEN gross_sales ELSE 0 END), 2) AS avg_discount,
	SUM(profit) AS total_profit
FROM gold.fact_orders
GROUP BY YEAR(order_date), DATEPART(quarter, order_date)
)
SELECT
	order_date_year,
	quarters,
	full_priced_profit,
	discounted_profit,
	total_profit,
	avg_discount,
	ROUND((CAST(full_priced_profit AS FLOAT)/total_profit) * 100, 2) AS full_priced_profit_share_pct,
	ROUND((CAST(discounted_profit AS FLOAT)/total_profit) * 100, 2) AS discounted_profit_share_pct
FROM yearly_metrics
ORDER BY order_date_year, quarters;


-- What is the percent contribution of profit by each category across the years & quarters?
WITH base AS
(
SELECT
	YEAR(order_date) AS order_date_year,
	DATEPART(quarter, order_date) AS quarters,
	dp.category,
	profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
)
SELECT
	order_date_year,
	quarters,
	category,
	SUM(SUM(profit)) OVER(PARTITION BY category) AS total_profit,
	SUM(profit) AS current_profit,
	LAG(SUM(profit)) OVER(PARTITION BY category ORDER BY order_date_year, quarters) AS previous_profit,
	SUM(profit) - LAG(SUM(profit)) OVER(PARTITION BY category ORDER BY order_date_year, quarters) AS incremental_profit,
	ROUND((CAST(SUM(profit) - LAG(SUM(profit)) OVER(PARTITION BY category ORDER BY order_date_year, quarters) AS FLOAT)/
	SUM(SUM(profit)) OVER(PARTITION BY category)) * 100, 2) AS incremental_profit_cont_pct
FROM base
GROUP BY 
	order_date_year,
	quarters,
	category;


-- Which products consume most discount budget?
WITH discount_cost AS
(
SELECT
	dp.product_name,
	SUM(fo.discount * fo.gross_sales) AS discount_cost,
	SUM(fo.discount * fo.gross_sales)/SUM(fo.gross_sales) AS weighted_discount
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
WHERE discount > 0
GROUP BY dp.product_name
)
, product_metrics AS
(
SELECT
	product_name,
	discount_cost,
	SUM(discount_cost) OVER(ORDER BY discount_cost DESC) AS cumulative_discount_cost,
	ROW_NUMBER() OVER(ORDER BY discount_cost DESC) AS product_rank,
	weighted_discount
FROM discount_cost
)
SELECT
	product_name,
	ROUND(CAST(discount_cost AS FLOAT), 2) AS discount_cost,
	ROUND(CAST(cumulative_discount_cost AS FLOAT), 2) AS cumulative_discount_cost,
	ROUND((CAST(cumulative_discount_cost AS FLOAT)/SUM(discount_cost) OVER()) * 100, 2) AS cumulative_discount_cost_dist_pct,
	ROUND((CAST(product_rank AS FLOAT)/MAX(product_rank) OVER()) * 100, 2) AS product_count_dist_pct,
	ROUND(CAST(weighted_discount AS FLOAT), 2) AS weighted_discount
FROM product_metrics;
