/*
==========================================================================
Data Segmentation
==========================================================================
Script Purpose:
	This script segments products and customers into various categories
	based on relevant business metrics.
==========================================================================
*/
-- How many of our products are high performers?
WITH product_metrics AS
(
SELECT
	dp.product_name,
	SUM(fo.net_sales) AS total_sales,
	SUM(fo.quantity) AS total_quantity,
	SUM(fo.profit) AS total_profit,
	SUM(fo.profit)/SUM(fo.gross_sales) AS profit_margin,
	SUM(fo.discount * fo.gross_sales)/SUM(fo.gross_sales) AS weighted_discount
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.product_name
)
, scored AS
(
SELECT
	product_name,
	total_sales,
	total_quantity,
	total_profit,
	profit_margin,
	weighted_discount,
	PERCENT_RANK() OVER(ORDER BY total_sales) AS revenue_score,
	PERCENT_RANK() OVER(ORDER BY total_quantity) AS demand_score,
	PERCENT_RANK() OVER(ORDER BY total_profit) AS profit_score,
	PERCENT_RANK() OVER(ORDER BY profit_margin) AS margin_score,
	PERCENT_RANK() OVER(ORDER BY weighted_discount DESC) AS discount_penalty
FROM product_metrics
)
, performance_score AS
(
SELECT
	product_name,
	total_sales,
	total_quantity,
	total_profit,
	profit_margin,
	weighted_discount,
	revenue_score,
	demand_score,
	profit_score,
	margin_score,
	discount_penalty,
	(profit_score * 0.40) + (revenue_score * 0.20) + (demand_score * 0.15) + (margin_score * 0.15) + (discount_penalty * 0.10) AS performance_score
FROM scored
)
, product_segment AS
(
SELECT
	product_name,
	total_sales,
	total_quantity,
	total_profit,
	profit_margin,
	weighted_discount,
	performance_score,
	CASE
		WHEN performance_score >= 0.80 THEN 'High Performers'
		WHEN performance_score >= 0.40 THEN 'Mid Performers'
		ELSE 'Low Performers'
	END product_segment
FROM performance_score
)
SELECT
	product_segment,
	COUNT(product_segment) AS total_products
FROM product_segment
GROUP BY product_segment
ORDER BY total_products DESC;


-- How many net negative-profit products do we have?
WITH metrics AS
(
SELECT
	dp.product_name,
	SUM(fo.profit) AS total_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.product_key, dp.product_name
)
, product_segmentation AS
(
SELECT
	product_name,
	total_profit,
	CASE
		WHEN total_profit > 0 THEN 'Positive-Profit Product'
		WHEN total_profit < 0 THEN 'Negative-Profit Product'
		ELSE 'Zero-Profit Product'
	END AS product_segment
FROM metrics
)
SELECT
	product_segment,
	COUNT(product_segment) AS total_products
FROM product_segmentation
GROUP BY product_segment
ORDER BY total_products DESC;



-- How many of our customers only purchase on discounted prices?
WITH base AS
(
SELECT
	dc.customer_key,
	dc.first_name,
	dc.last_name,
	COUNT(DISTINCT CASE WHEN fo.discount = 0 THEN fo.order_id END) AS full_price_orders,
	COUNT(DISTINCT CASE WHEN fo.discount > 0 THEN fo.order_id END) AS disc_orders,
	COUNT(DISTINCT fo.order_id) AS total_orders,
	SUM(CASE WHEN fo.discount = 0 THEN fo.net_sales ELSE 0 END) AS full_price_sales,
	SUM(CASE WHEN fo.discount > 0 THEN fo.net_sales ELSE 0 END) AS disc_sales,
	SUM(fo.net_sales) AS total_sales,
	SUM(fo.discount * fo.gross_sales)/SUM(fo.gross_sales) AS avg_overall_discount,
	SUM(CASE WHEN fo.discount > 0 THEN fo.discount ELSE 0 END * fo.gross_sales)/
	NULLIF(SUM(CASE WHEN fo.discount > 0 THEN fo.gross_sales ELSE 0 END), 0) AS avg_discount
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key
GROUP BY
	dc.customer_key,
	dc.first_name,
	dc.last_name
)
, metrics AS
(
SELECT
	customer_key,
	CONCAT_WS(' ', first_name, last_name) AS customer_name,
	full_price_orders,
	disc_orders,
	total_orders,
	full_price_sales,
	disc_sales,
	total_sales,
	ROUND(CAST(avg_overall_discount AS FLOAT), 2) AS avg_overall_discount,
	ROUND(CAST(avg_discount AS FLOAT), 2) AS avg_discount,
	ROUND(CAST(full_price_orders AS FLOAT)/total_orders, 2) AS full_price_orders_share,
	ROUND(CAST(disc_orders AS FLOAT)/total_orders, 2) AS disc_orders_share,
	ROUND(CAST(full_price_sales AS FLOAT)/total_sales, 2) AS full_price_sales_share,
	ROUND(CAST(disc_sales AS FLOAT)/total_sales, 2) AS disc_sales_share,
	DENSE_RANK() OVER(ORDER BY total_sales DESC) AS rank_customers
FROM base
)
, customer_segmentation AS
(
SELECT
	customer_name,
	avg_overall_discount,
	avg_discount,
	full_price_orders_share,
	disc_orders_share,
	full_price_sales_share,
	disc_sales_share,
	CASE 
		WHEN disc_sales_share = 1 THEN 'Discount Only Customers'
		WHEN disc_sales_share > 0.8 THEN 'Promo Driven Customers'
		WHEN disc_sales_share BETWEEN 0.3 AND 0.8 THEN 'Hybrid Customers'
		WHEN disc_sales_share < 0.3 THEN 'Full Priced Customers'
		ELSE 'Unknown'
	END AS customer_segment
FROM metrics
)
SELECT
	customer_segment,
	COUNT(customer_segment) AS total_customers
FROM customer_segmentation
GROUP BY customer_segment
ORDER BY total_customers DESC;


-- How many of our customers are VIPs?
WITH base AS
(
SELECT
	dc.customer_key,
	dc.first_name,
	dc.last_name,
	SUM(fo.net_sales) AS total_sales,
	SUM(fo.quantity) AS total_quantity,
	SUM(fo.profit) AS total_profit,
	DATEDIFF(month, MIN(fo.order_date), MAX(fo.order_date)) AS lifespan,
	SUM(fo.net_sales)/COUNT(DISTINCT fo.order_id) AS order_value,
	SUM(fo.profit)/SUM(fo.gross_sales) AS profit_margin,
	SUM(fo.discount * fo.gross_sales)/SUM(fo.gross_sales) AS weighted_discount
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key
GROUP BY
	dc.customer_key,
	dc.first_name,
	dc.last_name
)
, metrics AS
(
SELECT
	customer_key,
	CONCAT_WS(' ', first_name, last_name) AS customer_name,
	total_sales,
	total_quantity,
	total_profit,
	lifespan,
	order_value,
	profit_margin,
	weighted_discount,
	PERCENT_RANK() OVER(ORDER BY total_sales) AS revenue_score,
	PERCENT_RANK() OVER(ORDER BY total_quantity) AS quantity_score,
	PERCENT_RANK() OVER(ORDER BY total_profit) AS profit_score,
	PERCENT_RANK() OVER(ORDER BY lifespan) AS lifespan_score,
	PERCENT_RANK() OVER(ORDER BY order_value) AS order_value_score,
	PERCENT_RANK() OVER(ORDER BY profit_margin) AS margin_score,
	PERCENT_RANK() OVER(ORDER BY weighted_discount DESC) AS discount_reliance
FROM base
)
, performance_score AS
(
SELECT
	customer_key,
	customer_name,
	total_sales,
	total_quantity,
	total_profit,
	lifespan,
	order_value,
	profit_margin,
	weighted_discount,
	(profit_score * 0.3) + (revenue_score * 0.2) + (lifespan_score * 0.1) + (margin_score * 0.1) + (order_value_score * 0.1) +
	(quantity_score * 0.1) + (discount_reliance * 0.1) AS performance_score
FROM metrics
)
, customer_segmentation AS
(
SELECT
	customer_name,
	total_sales,
	total_quantity,
	total_profit,
	lifespan,
	order_value,
	profit_margin,
	performance_score,
	CASE
		WHEN performance_score >= 0.80 THEN 'VIP'
		WHEN performance_score >= 0.40 THEN 'Regular'
		ELSE 'New'
	END AS customer_segment
FROM performance_score
)
SELECT
	customer_segment,
	COUNT(customer_segment) AS total_customers
FROM customer_segmentation
GROUP BY customer_segment
ORDER BY total_customers DESC;
