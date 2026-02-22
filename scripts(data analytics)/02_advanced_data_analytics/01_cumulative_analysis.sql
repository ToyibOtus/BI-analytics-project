/*
================================================================================
Cumulative Analysis
================================================================================
Script Purpose:
	This script draws insight into the rate of the business progression,
	by measuring the cumulation of relevant business metrics over time.
================================================================================
*/
-- How much is the business progressing over the years?
SELECT
	order_date_year,
	SUM(total_orders) OVER(ORDER BY order_date_year) AS cumulative_total_orders,
	SUM(total_quantity) OVER(ORDER BY order_date_year) AS cumulative_total_quantity,
	SUM(total_gross_sales) OVER(ORDER BY order_date_year) AS cumulative_total_gross_sales,
	SUM(total_net_sales) OVER(ORDER BY order_date_year) AS cumulative_total_net_sales,
	SUM(total_profit) OVER(ORDER BY order_date_year) AS cumulative_total_profit,
	ROUND(CAST(SUM(total_gross_sales) OVER(ORDER BY order_date_year) AS FLOAT)
	/SUM(total_quantity) OVER(ORDER BY order_date_year), 2) AS cumulative_weighted_avg_price,
	ROUND(CAST(SUM(total_profit) OVER(ORDER BY order_date_year) AS FLOAT)
	/SUM(total_quantity) OVER(ORDER BY order_date_year), 2) AS cumulative_avg_profit_per_quantity,
	ROUND((CAST(SUM(total_profit) OVER(ORDER BY order_date_year) AS FLOAT)
	/SUM(total_gross_sales) OVER(ORDER BY order_date_year)) * 100, 2) AS cumulative_avg_profit_margin_pct,
	ROUND((CAST(SUM(discount_value) OVER(ORDER BY order_date_year) AS FLOAT)
	/SUM(total_gross_sales) OVER(ORDER BY order_date_year)) * 100, 2) AS cumulative_avg_discount_pct
FROM
(
SELECT
	YEAR(order_date) AS order_date_year,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(gross_sales) AS total_gross_sales,
	SUM(net_sales) AS total_net_sales,
	SUM(profit) AS total_profit,
	SUM(discount * gross_sales) AS discount_value
FROM gold.fact_orders 
GROUP BY YEAR(order_date)
)SUB;


-- How much is the business progressing month-over-month?
SELECT
	order_date_month,
	SUM(total_orders) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month) AS cumulative_total_orders,
	SUM(total_quantity) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month) AS cumulative_total_quantity,
	SUM(total_gross_sales) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month) AS cumulative_total_gross_sales,
	SUM(total_net_sales) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month) AS cumulative_total_net_sales,
	SUM(total_profit) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month) AS cumulative_total_profit,
	ROUND(CAST(SUM(total_gross_sales) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month) AS FLOAT)
	/SUM(total_quantity) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month), 2) AS cumulative_weighted_avg_price,
	ROUND(CAST(SUM(total_profit) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month) AS FLOAT)
	/SUM(total_quantity) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month), 2) AS cumulative_avg_profit_per_quantity,
	ROUND((CAST(SUM(total_profit) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month) AS FLOAT)
	/SUM(total_gross_sales) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month)) * 100, 2) AS cumulative_avg_profit_margin_pct,
	ROUND((CAST(SUM(discount_value) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month) AS FLOAT)
	/SUM(total_gross_sales) OVER(PARTITION BY YEAR(order_date_month) ORDER BY order_date_month)) * 100, 2) AS cumulative_avg_discount_pct
FROM
(
SELECT
	DATETRUNC(month, order_date) AS order_date_month,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(gross_sales) AS total_gross_sales,
	SUM(net_sales) AS total_net_sales,
	SUM(profit) AS total_profit,
	SUM(discount * gross_sales) AS discount_value
FROM gold.fact_orders 
GROUP BY DATETRUNC(month, order_date)
)SUB;
