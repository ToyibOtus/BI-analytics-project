/*
============================================================================================
Customer Report
============================================================================================
Script Purpose:
	This report consolidates key customer metrics and behaviour. It performs the following:

	* Retrieves relevant fields
	* Performs relevant aggregations
	* Generates valuable KPIs
	* Assigns scores to customers based on performace on key metrics
	* Assigns a performance score to each customer
	* Segments customers into VIP, Regular, & New based on performance score.
============================================================================================
*/
IF OBJECT_ID('gold.vw_customers_report', 'V') IS NOT NULL
DROP VIEW gold.vw_customers_report;
GO

CREATE VIEW gold.vw_customers_report AS
WITH base_query AS
(
SELECT
	dc.customer_key,
	dc.customer_id,
	CONCAT_WS(' ', dc.first_name, dc.last_name) AS customer_name,
	dc.postal_code,
	dc.city,
	dc.country,
	dc.score,
	fo.order_id,
	fo.order_date,
	fo.gross_sales,
	fo.net_sales,
	fo.quantity,
	fo.discount,
	fo.profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key
)
, customer_aggregations AS
(
SELECT
	customer_key,
	customer_id,
	customer_name,
	postal_code,
	city,
	country,
	score,
	MIN(order_date) AS first_order_date,
	MAX(order_date) AS last_order_date,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) AS lifespan_month,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(net_sales) AS total_sales,
	SUM(profit) AS total_profit,
	SUM(discount * gross_sales)/SUM(gross_sales) AS avg_discount
FROM base_query
GROUP BY 
	customer_key,
	customer_id,
	customer_name,
	postal_code,
	city,
	country,
	score
)
, customer_kpi AS
(
SELECT
	customer_key,
	customer_id,
	customer_name,
	postal_code,
	city,
	country,
	score,
	first_order_date,
	last_order_date,
	lifespan_month,
	total_orders,
	total_quantity,
	total_sales,
	total_profit,
	avg_discount,
	CASE
		WHEN total_orders = 0 THEN 0
		ELSE total_sales/total_orders 
	END AS avg_order_value,
	CASE 
		WHEN lifespan_month = 0 THEN total_sales
		ELSE total_sales/lifespan_month 
	END AS avg_monthly_spend,
	DATEDIFF(month, last_order_date, GETDATE()) AS recency_month,
	total_profit/total_sales AS avg_profit_per_sales
FROM customer_aggregations
)
, customer_score AS
(
SELECT
	customer_key,
	customer_id,
	customer_name,
	postal_code,
	city,
	country,
	score,
	first_order_date,
	last_order_date,
	lifespan_month,
	total_orders,
	total_quantity,
	total_sales,
	total_profit,
	avg_discount,
	avg_order_value,
	avg_monthly_spend,
	recency_month,
	avg_profit_per_sales,
	PERCENT_RANK() OVER(ORDER BY avg_discount DESC) AS discount_reliance,
	PERCENT_RANK() OVER(ORDER BY recency_month DESC) AS recency_score,
	PERCENT_RANK() OVER(ORDER BY lifespan_month) AS loyalty_score,
	PERCENT_RANK() OVER(ORDER BY total_orders) AS order_score,
	PERCENT_RANK() OVER(ORDER BY total_sales) AS revenue_score,
	PERCENT_RANK() OVER(ORDER BY total_profit) AS profit_score
FROM customer_kpi
)
, customer_performance AS
(
SELECT
	customer_key,
	customer_id,
	customer_name,
	postal_code,
	city,
	country,
	score,
	first_order_date,
	last_order_date,
	lifespan_month,
	total_orders,
	total_quantity,
	total_sales,
	total_profit,
	avg_discount,
	avg_order_value,
	avg_monthly_spend,
	recency_month,
	avg_profit_per_sales,
	ROUND(CAST((profit_score * 0.40) + (revenue_score * 0.20) + (order_score * 0.10) + (loyalty_score * 0.10) 
	+ (recency_score * 0.10) + (discount_reliance * 0.10) AS FLOAT), 2) AS performance_score
FROM customer_score
)
SELECT
	customer_id,
	customer_key,
	customer_name,
	postal_code,
	city,
	country,
	score,
	first_order_date,
	last_order_date,
	lifespan_month,
	recency_month,
	total_orders,
	total_quantity,
	total_sales,
	total_profit,
	ROUND(CAST(avg_discount AS FLOAT), 2) AS avg_discount,
	ROUND(CAST(avg_order_value AS FLOAT), 2) AS avg_order_value,
	ROUND(CAST(avg_monthly_spend AS FLOAT), 2) AS avg_monthly_spend,
	ROUND(CAST(avg_profit_per_sales AS FLOAT), 2) AS avg_profit_per_sales,
	performance_score,
	CASE
		WHEN DAY(first_order_date) >= 90 THEN 'New' 
		WHEN performance_score >= 0.8 THEN 'High Performer'
		WHEN performance_score >= 0.20 THEN 'Mid Performer'
		ELSE 'Low Performer'
	END AS customer_status
FROM customer_performance
