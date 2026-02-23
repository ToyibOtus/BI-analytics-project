/*
========================================================================================================
Product Report
========================================================================================================
Script Purpose:
	This report consolidates key product metrics and behaviour. It performs the following:

	* Retrieves relevant fields
	* Performs relevant aggregations
	* Generates valuable KPIs
	* Assigns scores to products based on performace on key metrics
	* Assigns a performance score to each product
	* Segments products into High Performer, Mid Performer, & Low Performer based on performance score.
========================================================================================================
*/
IF OBJECT_ID('gold.vw_products_report', 'V') IS NOT NULL
DROP VIEW gold.vw_products_report;
GO

CREATE VIEW gold.vw_products_report AS
WITH base_query AS
(
SELECT
	dp.product_key,
	dp.product_id,
	dp.product_name,
	dp.category,
	dp.sub_category,
	fo.order_id,
	fo.order_date,
	fo.shipping_date,
	fo.gross_sales,
	fo.net_sales,
	fo.quantity,
	fo.discount,
	fo.profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
)
, product_aggregations AS
(
SELECT
	product_key,
	product_id,
	product_name,
	category,
	sub_category,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan_month,
	AVG(DATEDIFF(day, order_date, shipping_date)) AS avg_shipping_days,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(net_sales) AS total_sales,
	SUM(quantity) AS total_quantity,
	SUM(profit) AS total_profit,
	SUM(discount * gross_sales)/SUM(gross_sales) AS avg_discount
FROM base_query
GROUP BY
	product_key,
	product_id,
	product_name,
	category,
	sub_category
)
, product_kpi AS
(
SELECT
	product_key,
	product_id,
	product_name,
	category,
	sub_category,
	last_order_date,
	lifespan_month,
	avg_shipping_days,
	total_orders,
	total_sales,
	total_quantity,
	total_profit,
	avg_discount,
	DATEDIFF(month, last_order_date, GETDATE()) AS recency_month,
	CASE 
		WHEN total_orders = 0 THEN 0
		ELSE total_sales/total_orders 
	END AS avg_order_revenue,
	CASE
		WHEN lifespan_month = 0 THEN total_sales
		ELSE total_sales/lifespan_month 
	END AS avg_monthly_revenue,
	CASE 
		WHEN total_sales = 0 THEN 0
		ELSE total_profit/total_sales
	END AS avg_profit_per_revenue
FROM product_aggregations
)
, product_score AS
(
SELECT
	product_key,
	product_id,
	product_name,
	category,
	sub_category,
	last_order_date,
	lifespan_month,
	avg_shipping_days,
	total_orders,
	total_sales,
	total_quantity,
	total_profit,
	avg_discount,
	recency_month,
	avg_order_revenue,
	avg_monthly_revenue,
	avg_profit_per_revenue,
	PERCENT_RANK() OVER(ORDER BY avg_discount DESC) AS discount_reliance,
	PERCENT_RANK() OVER(ORDER BY recency_month DESC) AS recency_score,
	PERCENT_RANK() OVER(ORDER BY lifespan_month) AS lifespan_score,
	PERCENT_RANK() OVER(ORDER BY total_quantity) AS quantity_score,
	PERCENT_RANK() OVER(ORDER BY total_sales) AS revenue_score,
	PERCENT_RANK() OVER(ORDER BY total_profit) AS profit_score
FROM product_kpi
)
, product_performance AS
(
SELECT
	product_key,
	product_id,
	product_name,
	category,
	sub_category,
	last_order_date,
	lifespan_month,
	avg_shipping_days,
	total_orders,
	total_sales,
	total_quantity,
	total_profit,
	ROUND(CAST(avg_discount AS FLOAT), 2) AS avg_discount,
	recency_month,
	ROUND(CAST(avg_order_revenue AS FLOAT), 2) AS avg_order_revenue,
	ROUND(CAST(avg_monthly_revenue AS FLOAT), 2) AS avg_monthly_revenue,
	ROUND(CAST(avg_profit_per_revenue AS FLOAT), 2) AS avg_profit_per_revenue,
	ROUND(CAST((profit_score * 0.40) + (revenue_score * 0.20) + (quantity_score * 0.15) 
	+ (recency_score * 0.10) + (discount_reliance * 0.10) + (lifespan_score * 0.05) AS FLOAT), 2) AS performance_score
FROM product_score
)
SELECT
	product_id,
	product_key,
	product_name,
	category,
	sub_category,
	last_order_date,
	lifespan_month,
	recency_month,
	avg_shipping_days,
	total_orders,
	total_quantity,
	total_sales,
	total_profit,
	avg_discount,
	avg_order_revenue,
	avg_monthly_revenue,
	avg_profit_per_revenue,
	performance_score,
	CASE
		WHEN avg_profit_per_revenue <= -0.10 THEN 'Severely Unprofitable'
		WHEN avg_profit_per_revenue < 0 THEN 'Slightly Unprofitable'
		WHEN avg_profit_per_revenue <= 0.10 THEN 'Low Margin'
		WHEN avg_profit_per_revenue > 0.10 AND avg_profit_per_revenue <= 0.20 THEN 'Healthy Margin'
		ELSE 'High Margin'
	END AS profit_margin_status,
	CASE
		WHEN performance_score >= 0.8 THEN 'High Performer'
		WHEN performance_score >= 0.20 THEN 'Mid Performer'
		ELSE 'Low Performer'
	END AS product_status
FROM product_performance;
