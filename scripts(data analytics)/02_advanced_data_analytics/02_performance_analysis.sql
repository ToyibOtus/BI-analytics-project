/*
==========================================================================
Performance Analysis
==========================================================================
Script Purpose:
	This script retrieves data that shows insight in the business
	performance.
==========================================================================
*/
-- What is the imapact of each discount tier on profit?
WITH discount_tier AS
(
SELECT
	order_id,
	quantity,
	gross_sales,
	net_sales,
	profit,
	discount,
	CASE
		WHEN discount = 0 THEN '0%'
		WHEN discount > 0 AND discount <= 0.10 THEN '1-10%'
		WHEN discount > 0.10 AND discount <= 0.20 THEN '11-20%'
		WHEN discount > 0.20 AND discount <= 0.30 THEN '21-30%'
		WHEN discount > 0.30 AND discount <= 0.40 THEN '31-40%'
		ELSE '41%+'
	END AS discount_tier,
	CASE
		WHEN discount = 0 THEN 0
		WHEN discount > 0 AND discount <= 0.10 THEN 1
		WHEN discount > 0.10 AND discount <= 0.20 THEN 2
		WHEN discount > 0.20 AND discount <= 0.30 THEN 3
		WHEN discount > 0.30 AND discount <= 0.40 THEN 4
		ELSE 5
	END AS tier_sort_order
FROM gold.fact_orders
)
, metrics AS
(
SELECT
	discount_tier,
	tier_sort_order,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(quantity) AS total_quantity,
	SUM(gross_sales) AS total_gross_sales,
	SUM(net_sales) AS total_net_sales,
	SUM(profit) AS total_profit,
	SUM(discount * gross_sales) AS discount_cost
FROM discount_tier
GROUP BY discount_tier, tier_sort_order
)
, roi AS
(
SELECT
	discount_tier,
	tier_sort_order,
	total_orders,
	total_quantity,
	total_gross_sales,
	total_net_sales,
	total_profit,
	ROUND(CAST(discount_cost AS FLOAT), 2) AS discount_cost,
	ROUND(CAST(total_profit AS FLOAT)/total_quantity, 2) AS profit_per_quantity,
	ROUND((CAST(total_profit AS FLOAT)/total_gross_sales) * 100, 2) AS profit_margin_pct,
	ROUND((CAST(total_profit AS FLOAT)/NULLIF(discount_cost, 0)) * 100, 2) AS roi_on_discount_pct
FROM metrics
)
SELECT
	discount_tier,
	tier_sort_order,
	total_orders,
	total_quantity,
	total_gross_sales,
	total_net_sales,
	total_profit,
	discount_cost,
	profit_per_quantity,
	profit_margin_pct,
	roi_on_discount_pct,
	CASE
		WHEN roi_on_discount_pct IS NULL THEN 'Baseline'
		WHEN roi_on_discount_pct <= 0 THEN 'Unprofitable'
		WHEN roi_on_discount_pct > 0 AND roi_on_discount_pct <= 50 THEN 'Low ROI'
		WHEN roi_on_discount_pct > 50 AND roi_on_discount_pct < 100 THEN 'Moderate ROI'
		WHEN roi_on_discount_pct > 100 THEN 'High ROI'
	END AS tier_health
FROM roi
ORDER BY tier_sort_order;


-- Across products, what is the impact of discount on profit?
WITH product_metrics AS
(
SELECT
	dp.product_name,
	SUM(CASE WHEN fo.discount = 0 THEN fo.net_sales ELSE 0 END) AS total_net_sales_full_price,
	SUM(CASE WHEN fo.discount = 0 THEN fo.profit ELSE 0 END) AS total_profit_full_price,
	SUM(CASE WHEN fo.discount = 0 THEN fo.quantity ELSE 0 END) AS total_quantity_full_price,
	SUM(CASE WHEN fo.discount > 0 THEN fo.gross_sales ELSE 0 END) AS total_gross_sales_disc,
	SUM(CASE WHEN fo.discount > 0 THEN fo.net_sales ELSE 0 END) AS total_net_sales_disc,
	SUM(CASE WHEN fo.discount > 0 THEN fo.profit ELSE 0 END) AS total_profit_disc,
	SUM(CASE WHEN fo.discount > 0 THEN fo.quantity ELSE 0 END) AS total_quantity_disc,
	SUM(CASE WHEN fo.discount > 0 THEN fo.discount * fo.gross_sales ELSE 0 END) AS discount_cost
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.product_name
)
, product_performance AS
(
SELECT
	product_name,
	total_net_sales_full_price,
	total_profit_full_price,
	total_quantity_full_price,
	total_gross_sales_disc,
	total_net_sales_disc,
	total_profit_disc,
	total_quantity_disc,
	ROUND(CAST(discount_cost AS FLOAT), 2) AS discount_cost,
	total_profit_full_price/NULLIF(total_quantity_full_price, 0) AS ppq_full_price,
	total_profit_disc/NULLIF(total_quantity_disc, 0) AS ppq_disc,
	ROUND((CAST(discount_cost AS FLOAT)/NULLIF(total_gross_sales_disc, 0)) * 100, 2) AS avg_discount_pct,
	ROUND((CAST(total_quantity_disc AS FLOAT)/(total_quantity_full_price + total_quantity_disc)) * 100, 2) AS volume_share_disc_pct
FROM product_metrics
)
, product_roi AS
(
SELECT
	product_name,
	total_net_sales_full_price,
	total_profit_full_price,
	total_quantity_full_price,
	total_gross_sales_disc,
	total_net_sales_disc,
	total_profit_disc,
	total_quantity_disc,
	discount_cost,
	ROUND(CAST(ppq_full_price AS FLOAT), 2) AS ppq_full_price,
	ROUND(CAST(ppq_disc AS FLOAT), 2) AS ppq_disc,
	avg_discount_pct,
	volume_share_disc_pct,
	ROUND((CAST((ppq_disc - ppq_full_price) AS FLOAT)/NULLIF(ppq_full_price, 0)) * 100, 2) AS ppq_disc_diff_pct,
	ROUND((CAST(total_profit_disc AS FLOAT)/NULLIF(discount_cost, 0)) * 100, 2) AS roi_discount_pct
FROM product_performance
)
SELECT
	product_name,
	total_profit_full_price AS profit_base_price,
	total_profit_disc AS discounted_profit,
	discount_cost,
	ppq_full_price ppq_base_price,
	ppq_disc AS discounted_ppq,
	ppq_disc_diff_pct AS discounted_ppq_pct_diff,
	avg_discount_pct,
	volume_share_disc_pct AS discounted_vol_pct_share,
	roi_discount_pct,
	CASE
		WHEN volume_share_disc_pct = 0 THEN 'Never Discounted'
		WHEN volume_share_disc_pct = 100 THEN 'Always Discounted'
		WHEN total_profit_disc < 0 THEN 'Discount Destroys Profit'
		WHEN volume_share_disc_pct <= 20 THEN 'Discount Wasted'
		WHEN volume_share_disc_pct > 20 AND roi_discount_pct <= 50 THEN 'Low ROI'
		WHEN volume_share_disc_pct > 20 AND roi_discount_pct > 50 AND roi_discount_pct <= 100 THEN 'Moderate ROI'
		WHEN volume_share_disc_pct > 20 AND roi_discount_pct > 100 THEN 'High ROI'
	END AS promo_classification
FROM product_roi
ORDER BY total_profit_full_price + total_profit_disc DESC;


-- Is the yearly sales of each product greater than their average sales?
WITH sales_aggregation AS
(
SELECT
	YEAR(fo.order_date) AS order_date_year,
	dp.product_name,
	SUM(fo.net_sales) AS total_net_sales,
	ROUND(CAST(AVG(SUM(fo.net_sales)) OVER(PARTITION BY dp.product_name) AS FLOAT), 2) AS avg_sales
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY YEAR(order_date), dp.product_name
)
, sales_diff AS
(
SELECT
	order_date_year,
	product_name,
	total_net_sales,
	avg_sales,
	ROUND(CAST(total_net_sales - avg_sales AS FLOAT), 2) AS sales_diff,
	ROUND((CAST(total_net_sales - avg_sales AS FLOAT)/NULLIF(avg_sales, 0)) * 100, 2) AS pct_sales_diff
FROM sales_aggregation
)
SELECT
	order_date_year,
	product_name,
	total_net_sales,
	avg_sales,
	sales_diff,
	pct_sales_diff,
	CASE	
		WHEN pct_sales_diff > 0 THEN 'Above Average'
		WHEN pct_sales_diff < 0 THEN 'Below Average'
		ELSE 'Equal to Average'
	END AS product_sales_status
FROM sales_diff;


-- Is the yearly sales of each product greater than the previous year's?
WITH sales_aggregation AS
(
SELECT
	YEAR(order_date) AS order_date_year,
	dp.product_name,
	SUM(net_sales) AS current_net_sales,
	LAG(SUM(net_sales)) OVER(PARTITION BY dp.product_name ORDER BY YEAR(order_date)) AS previous_net_sales
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY YEAR(order_date), dp.product_name
)
, sales_diff AS
(
SELECT
	order_date_year,
	product_name,
	current_net_sales,
	previous_net_sales,
	current_net_sales - previous_net_sales AS sales_diff,
	ROUND(((CAST(current_net_sales - previous_net_sales AS FLOAT))/NULLIF(previous_net_sales, 0)) * 100, 2) AS pct_sales_diff
FROM sales_aggregation
)
SELECT
	order_date_year,
	product_name,
	current_net_sales,
	previous_net_sales,
	sales_diff,
	pct_sales_diff,
	CASE 
		WHEN pct_sales_diff > 0 THEN 'Above Previous Sales'
		WHEN pct_sales_diff < 0 THEN 'Below Previous Sales' 
		WHEN pct_sales_diff = 0 THEN 'Equal to Previous Sales'
		ELSE NULL
	END AS product_sales_status
FROM sales_diff;


-- Across the years, is the profit generated by each product increasing consistently?
WITH profit_aggregation AS
(
SELECT
	YEAR(order_date) AS order_date_year,
	dp.product_name,
	SUM(profit) AS current_profit,
	LAG(SUM(profit)) OVER(PARTITION BY dp.product_name ORDER BY YEAR(order_date)) AS previous_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY YEAR(order_date), dp.product_name
)
, profit_diff AS
(
SELECT
	order_date_year,
	product_name,
	current_profit,
	previous_profit,
	current_profit - previous_profit AS profit_diff,
	ROUND(((CAST(current_profit - previous_profit AS FLOAT))/NULLIF(previous_profit, 0)) * 100, 2) AS pct_profit_diff
FROM profit_aggregation
)
SELECT
	order_date_year,
	product_name,
	current_profit,
	previous_profit,
	profit_diff,
	pct_profit_diff,
	CASE 
		WHEN pct_profit_diff > 0 THEN 'Above Previous Profit'
		WHEN pct_profit_diff < 0 THEN 'Below Previous Profit' 
		WHEN pct_profit_diff = 0 THEN 'Equal to Previous Profit'
		ELSE NULL
	END AS product_profit_status
FROM profit_diff;



-- How many of our products from each category haven't been ordered?
SELECT
	category,
	total_products,
	total_products_ordered,
	total_products - total_products_ordered AS product_count_diff,
	ROUND(((CAST(total_products - total_products_ordered AS FLOAT))/total_products) * 100, 2) AS pct_product_count_diff
FROM
(
SELECT
	dp.category,
	COUNT(DISTINCT dp.product_key) AS total_products,
	COUNT(DISTINCT fo.product_key) AS total_products_ordered
FROM gold.dim_products dp
LEFT JOIN gold.fact_orders fo
ON dp.product_key = fo.product_key
GROUP BY dp.category
)SUB;


-- Retrieve all products not ordered from each category
SELECT
	dp.category,
	dp.product_name
FROM gold.dim_products dp
WHERE dp.product_key NOT IN(SELECT product_key FROM gold.fact_orders)
ORDER BY dp.category;


-- Is 20 percent of our products contributing 80 percent of our total revenue?
WITH product_sales AS
(
SELECT
	dp.product_name,
	SUM(fo.net_sales) AS total_sales
FROM gold.fact_orders fo 
LEFT JOIN gold.dim_products dp
ON dp.product_key = fo.product_key
GROUP BY dp.product_name
)
, window_aggregations AS 
(
SELECT
	product_name,
	total_sales,
	SUM(total_sales) OVER(ORDER BY total_sales DESC) AS running_total_sales,
	ROW_NUMBER() OVER(ORDER BY total_sales DESC) AS rank_product_sales
FROM product_sales
)
SELECT
	product_name,
	total_sales,
	running_total_sales,
	ROUND((CAST(running_total_sales AS FLOAT)/SUM(total_sales) OVER()) * 100, 2) AS percent_cumulative_sales_dist,
	ROUND((CAST(rank_product_sales AS FLOAT)/MAX(rank_product_sales) OVER()) * 100, 2) AS percent_product_rank_dist,
	rank_product_sales
FROM window_aggregations;


-- Is 20 percent of our products contributing 80 percent of our total profit?
WITH product_profit AS
(
SELECT
	dp.product_name,
	SUM(fo.profit) AS total_profit
FROM gold.fact_orders fo 
LEFT JOIN gold.dim_products dp
ON dp.product_key = fo.product_key
GROUP BY dp.product_name
)
, window_aggregations AS 
(
SELECT
	product_name,
	total_profit,
	SUM(total_profit) OVER(ORDER BY total_profit DESC) AS running_total_profit,
	ROW_NUMBER() OVER(ORDER BY total_profit DESC) AS rank_product_profit
FROM product_profit
WHERE total_profit > 0
)
SELECT
	product_name,
	total_profit,
	running_total_profit,
	ROUND((CAST(running_total_profit AS FLOAT)/SUM(total_profit) OVER()) * 100, 2) AS percent_cumulative_profit_dist,
	ROUND((CAST(rank_product_profit AS FLOAT)/MAX(rank_product_profit) OVER()) * 100, 2) AS percent_product_rank_dist,
	rank_product_profit
FROM window_aggregations;


-- Categorize products based on cumulative percentage contribution to total_profit
WITH product_profit AS
(
SELECT
	dp.product_name,
	SUM(fo.profit) AS total_profit
FROM gold.fact_orders fo 
LEFT JOIN gold.dim_products dp
ON dp.product_key = fo.product_key
GROUP BY dp.product_name
)
, cumulative_aggregations AS 
(
SELECT
	product_name,
	total_profit,
	SUM(total_profit) OVER(ORDER BY total_profit DESC) AS running_total_profit,
	ROW_NUMBER() OVER(ORDER BY total_profit DESC) AS rank_product_profit
FROM product_profit
WHERE total_profit > 0
)
, percent_cumulative_aggregations AS
(
SELECT
	product_name,
	total_profit,
	running_total_profit,
	ROUND((CAST(running_total_profit AS FLOAT)/SUM(total_profit) OVER()) * 100, 2) AS percent_cumulative_profit_dist,
	ROUND((CAST(rank_product_profit AS FLOAT)/MAX(rank_product_profit) OVER()) * 100, 2) AS percent_product_dist,
	rank_product_profit
FROM cumulative_aggregations
)
SELECT
	product_name,
	total_profit,
	percent_cumulative_profit_dist,
	CASE	
		WHEN percent_cumulative_profit_dist <= 80 THEN 'Top Pareto Profit Group'
		WHEN percent_cumulative_profit_dist > 80 AND percent_cumulative_profit_dist <= 95  THEN 'Mid Pareto Profit Group'
		ELSE 'Low Pareto Profit Group'
	END AS product_group
FROM percent_cumulative_aggregations;


-- Why do some of our products generate a net-negative proft?
SELECT
	dp.product_name,
	SUM(fo.gross_sales) AS total_gross_sales,
	SUM(fo.quantity) AS total_quantity,
	SUM(fo.profit) AS total_profit,
	ROUND(CAST(SUM(fo.gross_sales) AS FLOAT)/SUM(fo.quantity), 2) AS weighted_avg_gross_price,
	ROUND(CAST(SUM(fo.profit) AS FLOAT)/SUM(fo.quantity), 2) AS avg_profit_per_quantity,
	ROUND((CAST(SUM(fo.profit) AS FLOAT)/SUM(fo.gross_sales)) * 100, 2) AS pct_profit_margin,
	ROUND((CAST(SUM(fo.discount * fo.gross_sales) AS FLOAT)/SUM(fo.gross_sales)) * 100, 2) AS pct_weighted_discount
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.product_name
HAVING SUM(fo.profit) < 0
ORDER BY total_gross_sales DESC;


-- At what point did these products start to generate a net-negative profit, and why?
SELECT
	YEAR(fo.order_date) AS order_date_year,
	dp.product_name,
	SUM(fo.net_sales) AS total_net_sales,
	SUM(fo.quantity) AS total_quantity,
	SUM(fo.profit) AS total_profit,
	ROUND(CAST(SUM(fo.gross_sales) AS FLOAT)/SUM(fo.quantity), 2) AS weighted_avg_gross_price,
	ROUND(CAST(SUM(fo.net_sales) AS FLOAT)/SUM(fo.quantity), 2) AS weighted_avg_net_price,
	ROUND(ABS(CAST(SUM(fo.profit - fo.net_sales) AS FLOAT)/SUM(fo.quantity)), 2) AS avg_cost_per_quantity,
	ROUND(CAST(SUM(fo.profit) AS FLOAT)/SUM(fo.quantity), 2) AS avg_profit_per_quantity,
	ROUND((CAST(SUM(fo.profit) AS FLOAT)/SUM(fo.gross_sales)) * 100, 2) AS pct_profit_margin,
	ROUND((CAST(SUM(fo.discount * fo.gross_sales) AS FLOAT)/SUM(fo.gross_sales)) * 100, 2) AS pct_weighted_discount
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
WHERE dp.product_name IN (SELECT dp.product_name FROM gold.fact_orders fo LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key GROUP BY dp.product_name HAVING SUM(fo.profit) < 0)
GROUP BY YEAR(fo.order_date), dp.product_name
ORDER BY dp.product_name, order_date_year;


-- What major metric(s) erodes into the profit of these negative profit-generating products?
WITH base AS
(
SELECT
	YEAR(fo.order_date) AS order_date_year,
	dp.product_name,
	SUM(fo.net_sales) AS total_net_sales,
	SUM(fo.quantity) AS total_quantity,
	SUM(fo.profit) AS total_profit,
	SUM(fo.gross_sales)/SUM(fo.quantity) AS weighted_avg_gross_price,
	SUM(fo.net_sales)/SUM(fo.quantity) AS weighted_avg_net_price,
	ABS(SUM(fo.profit - fo.net_sales)/SUM(fo.quantity)) AS avg_cost_per_quantity,
	SUM(fo.profit)/SUM(fo.quantity) AS avg_profit_per_quantity,
	(SUM(fo.profit)/SUM(fo.gross_sales)) * 100 AS pct_profit_margin,
	(SUM(fo.discount * fo.gross_sales) /SUM(fo.gross_sales)) * 100 AS pct_weighted_discount
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
WHERE dp.product_name IN (SELECT dp.product_name FROM gold.fact_orders fo LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key GROUP BY dp.product_name HAVING SUM(fo.profit) < 0)
GROUP BY YEAR(fo.order_date), dp.product_name
)
SELECT
	order_date_year,
	product_name,
	total_profit,
	ROUND(CAST(weighted_avg_gross_price AS FLOAT), 2) AS weighted_avg_gross_price,
	ROUND(CAST(weighted_avg_net_price AS FLOAT), 2) AS weighted_avg_net_price,
	ROUND(CAST(avg_cost_per_quantity AS FLOAT), 2) AS avg_cost_per_quantity,
	ROUND(CAST(avg_profit_per_quantity AS FLOAT), 2) AS avg_profit_per_quantity,
	ROUND(CAST(pct_profit_margin AS FLOAT), 2) AS pct_profit_margin,
	ROUND(CAST(pct_weighted_discount AS FLOAT), 2) AS pct_weighted_discount,
	CASE
		WHEN weighted_avg_gross_price > avg_cost_per_quantity AND weighted_avg_net_price < avg_cost_per_quantity THEN 'Discount-Driven Erosion'
		WHEN weighted_avg_gross_price < avg_cost_per_quantity AND pct_weighted_discount = 0 THEN 'Price-Driven Erosion'
		WHEN weighted_avg_gross_price < avg_cost_per_quantity AND pct_weighted_discount > 0 THEN 'Price and Discount-Assisted Erosion'
		WHEN weighted_avg_gross_price = weighted_avg_net_price AND weighted_avg_net_price > avg_cost_per_quantity THEN 'Price-Led Growth'
		WHEN weighted_avg_gross_price > weighted_avg_net_price AND weighted_avg_net_price > avg_cost_per_quantity THEN 'Discount-Driven Growth'
		ELSE 'Mixed Impact'
	END AS profit_driver
FROM base
ORDER BY product_name, order_date_year;


-- Are sales increasing consistently year-over-year?
WITH yearly_sales AS
(
SELECT
	YEAR(order_date) AS order_date_year,
	SUM(net_sales) AS current_net_sales,
	LAG(SUM(net_sales)) OVER(ORDER BY YEAR(order_date)) AS previous_net_sales
FROM gold.fact_orders
GROUP BY YEAR(order_date)
)
, sales_comparison AS
(
SELECT
	order_date_year,
	current_net_sales,
	previous_net_sales,
	current_net_sales - previous_net_sales AS sales_diff,
	ROUND((CAST((current_net_sales - previous_net_sales) AS FLOAT)/previous_net_sales) * 100, 2) AS percent_sales_diff
FROM yearly_sales
)
SELECT
	order_date_year,
	current_net_sales,
	previous_net_sales,
	sales_diff,
	percent_sales_diff,
	CASE	
		WHEN sales_diff > 0 THEN 'Above Previous Sales'
		WHEN sales_diff < 0 THEN 'Below Previous Sales'
		WHEN sales_diff = 0 THEN 'Equal to Previous Sales'
		ELSE NULL
	END AS current_net_sales_status
FROM sales_comparison;


-- Is profit increasing consistently over the years?
WITH yearly_profit AS
(
SELECT
	YEAR(order_date) AS order_date_year,
	SUM(profit) AS current_profit,
	LAG(SUM(profit)) OVER(ORDER BY YEAR(order_date)) AS previous_profit
FROM gold.fact_orders
GROUP BY YEAR(order_date)
)
, profit_comparison AS
(
SELECT
	order_date_year,
	current_profit,
	previous_profit,
	current_profit - previous_profit AS profit_diff,
	ROUND((CAST((current_profit - previous_profit) AS FLOAT)/previous_profit) * 100, 2) AS percent_profit_diff
FROM yearly_profit
)
SELECT
	order_date_year,
	current_profit,
	previous_profit,
	profit_diff,
	percent_profit_diff,
	CASE	
		WHEN profit_diff > 0 THEN 'Above Previous Profit'
		WHEN profit_diff < 0 THEN 'Below Previous Profit'
		WHEN profit_diff = 0 THEN 'Equal to Previous Profit'
		ELSE NULL
	END AS current_profit_status
FROM profit_comparison;


-- How fast is the business progressing profit-wise?
WITH yearly_profit AS
(
SELECT
	YEAR(order_date) AS order_date_year,
	SUM(profit) AS total_profit
FROM gold.fact_orders
GROUP BY YEAR(order_date)
)
, running_total AS
(
SELECT
	order_date_year,
	total_profit,
	SUM(total_profit) OVER(ORDER BY order_date_year) AS running_total_profit
FROM yearly_profit
)
SELECT
	order_date_year,
	total_profit,
	running_total_profit AS current_cumulative_profit,
	LAG(running_total_profit) OVER(ORDER BY order_date_year) AS previous_cumulative_profit,
	ROUND(((CAST(running_total_profit - LAG(running_total_profit) OVER(ORDER BY order_date_year) AS FLOAT))
	/LAG(running_total_profit) OVER(ORDER BY order_date_year)) * 100, 2) AS percent_cumulative_profit_diff
FROM running_total;


-- Are our top-revenue generating customers promo driven or full priced?
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
WHERE rank_customers <= 20
ORDER BY total_Sales DESC;
