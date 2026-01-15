/*
=======================================================================================
Ranking Analysis
=======================================================================================
Script Purpose:
	This script performs ranking analysis. It ranks various dimensions based on several
	business metrics.
=======================================================================================
*/
-- What is our top 3 countries based on customer volume?
SELECT
	country,
	total_customers,
	rank_count_customers
FROM
(
SELECT
	country,
	COUNT(customer_key) AS total_customers,
	DENSE_RANK() OVER(ORDER BY COUNT(customer_key) DESC) AS rank_count_customers
FROM gold.dim_customers
GROUP BY country
)SUB
WHERE rank_count_customers <= 3;

-- Which country has the highest portion of customers who have placed orders?
SELECT
	country,
	percent_customers_ordered,
	DENSE_RANK() OVER(ORDER BY percent_customers_ordered DESC) AS rank_percent_cust_ordered
FROM
(
SELECT
	dc.country,
	COUNT(DISTINCT dc.customer_key) AS total_customers,
	COUNT(DISTINCT fo.customer_key) AS total_customers_ordered,
	(CAST(COUNT(DISTINCT fo.customer_key) AS FLOAT))/COUNT(DISTINCT dc.customer_key) * 100 AS percent_customers_ordered
FROM gold.dim_customers dc
LEFT JOIN gold.fact_orders fo
ON dc.customer_key = fo.customer_key
GROUP BY dc.country
)SUB;

-- What are the top 3 countries with the highest orders?
SELECT
	country,
	total_orders,
	rank_orders
FROM
(
SELECT
	dc.country,
	COUNT(DISTINCT fo.order_id) AS total_orders,
	DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT fo.order_id) DESC) AS rank_orders
FROM gold.fact_orders fo 
LEFT JOIN gold.dim_customers dc
ON dc.customer_key = fo.customer_key
GROUP BY dc.country
)SUB
WHERE rank_orders <=3;

-- How does the rank differ based on total quantity of products purchased?
SELECT
	country,
	total_quantity,
	rank_quantity
FROM
(
SELECT
	dc.country,
	SUM(fo.quantity) AS total_quantity,
	DENSE_RANK() OVER(ORDER BY SUM(fo.quantity) DESC) AS rank_quantity
FROM gold.fact_orders fo 
LEFT JOIN gold.dim_customers dc
ON dc.customer_key = fo.customer_key
GROUP BY dc.country
)SUB
WHERE rank_quantity <=3;

-- Which country sits at the top of the sales rank?
SELECT
	country,
	total_sales,
	rank_sales
FROM
(
SELECT
	dc.country,
	SUM(fo.sales) AS total_sales,
	DENSE_RANK() OVER(ORDER BY SUM(fo.sales) DESC) AS rank_sales
FROM gold.fact_orders fo 
LEFT JOIN gold.dim_customers dc
ON dc.customer_key = fo.customer_key
GROUP BY dc.country
)SUB
WHERE rank_sales <=3;

-- What are the top 3 countries with the highest profit?
SELECT
	country,
	total_profit,
	rank_profit
FROM
(
SELECT
	dc.country,
	SUM(fo.profit) AS total_profit,
	DENSE_RANK() OVER(ORDER BY SUM(fo.profit) DESC) AS rank_profit
FROM gold.fact_orders fo 
LEFT JOIN gold.dim_customers dc
ON dc.customer_key = fo.customer_key
GROUP BY dc.country
)SUB
WHERE rank_profit <=3;


-- Are ranks consistent across key business metrics?
SELECT
	country,
	DENSE_RANK() OVER(ORDER BY total_customers DESC) AS rank_count_customers,
	DENSE_RANK() OVER(ORDER BY percent_customers_ordered DESC) AS rank_percent_cust_ordered,
	DENSE_RANK() OVER(ORDER BY total_orders DESC) AS rank_orders,
	DENSE_RANK() OVER(ORDER BY total_quantity DESC) AS rank_quantity,
	DENSE_RANK() OVER(ORDER BY total_sales DESC) AS rank_sales,
	DENSE_RANK() OVER(ORDER BY total_profit DESC) AS rank_profit
FROM
(
SELECT
	dc.country,
	COUNT(DISTINCT dc.customer_key) AS total_customers,
	(CAST(COUNT(DISTINCT fo.customer_key) AS FLOAT))/COUNT(DISTINCT dc.customer_key) * 100 AS percent_customers_ordered,
	COUNT(DISTINCT fo.order_id) AS total_orders,
	SUM(COALESCE(fo.quantity, 0)) AS total_quantity,
	SUM(COALESCE(fo.sales, 0)) AS total_sales,
	SUM(COALESCE(fo.profit, 0)) AS total_profit
FROM gold.dim_customers dc
LEFT JOIN gold.fact_orders fo
ON dc.customer_key = fo.customer_key
GROUP BY dc.country
)SUB;

-- What are the top categories by orders?
SELECT
	dp.category,
	COUNT(DISTINCT fo.order_id) AS total_orders,
	DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT fo.order_id) DESC) AS rank_orders
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category;

-- Does the rank differ by quantity of products ordered?
SELECT
	dp.category,
	SUM(fo.quantity) AS total_quantity,
	DENSE_RANK() OVER(ORDER BY SUM(fo.quantity) DESC) AS rank_quantity
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category;

-- Which category drives in the most revenue?
SELECT
	dp.category,
	SUM(fo.sales) AS total_sales,
	DENSE_RANK() OVER(ORDER BY SUM(fo.sales) DESC) AS rank_sales
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category;

-- Which category sits at the top of the profit rank?
SELECT
	dp.category,
	SUM(fo.profit) AS total_profit,
	DENSE_RANK() OVER(ORDER BY SUM(fo.profit) DESC) AS rank_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category;

-- Within each category, what are the top 3 subcategory of products based on orders?
SELECT
	category,
	sub_category,
	total_orders,
	rank_orders
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	COUNT(DISTINCT order_id) AS total_orders,
	DENSE_RANK() OVER(PARTITION BY dp.category ORDER BY COUNT(DISTINCT order_id) DESC) AS rank_orders
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category
)SUB
WHERE rank_orders <= 3;

-- Within each category, what are the top 3 subcategory of products by quantity?
SELECT
	category,
	sub_category,
	total_quantity,
	rank_quantity
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	SUM(fo.quantity) AS total_quantity,
	DENSE_RANK() OVER(PARTITION BY dp.category ORDER BY SUM(fo.quantity) DESC) AS rank_quantity
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category
)SUB
WHERE rank_quantity <= 3;

-- Does the rank differ with total revenue?
SELECT
	category,
	sub_category,
	total_sales,
	rank_sales
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	SUM(fo.sales) AS total_sales,
	DENSE_RANK() OVER(PARTITION BY dp.category ORDER BY SUM(fo.sales) DESC) AS rank_sales
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category
)SUB
WHERE rank_sales <= 3;

-- Within each category, what are the top 3 subcategory of products that contribute most to the total profit?
SELECT
	category,
	sub_category,
	total_profit,
	rank_profit
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	SUM(fo.profit) AS total_profit,
	DENSE_RANK() OVER(PARTITION BY dp.category ORDER BY SUM(fo.profit) DESC) AS rank_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category
)SUB
WHERE rank_profit <= 3;

-- Within each category & sub category, what are the top 3 products based on orders?
SELECT
	category,
	sub_category,
	product_name,
	total_orders,
	rank_orders
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	dp.product_name,
	COUNT(DISTINCT order_id) AS total_orders,
	DENSE_RANK() OVER(PARTITION BY dp.category, dp.sub_category ORDER BY COUNT(DISTINCT order_id) DESC) AS rank_orders
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category, dp.product_name
)SUB
WHERE rank_orders = 1;

-- Within each category & sub category, what are the top 3 products by quantity?
SELECT
	category,
	sub_category,
	product_name,
	total_quantity,
	rank_quantity
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	dp.product_name,
	SUM(fo.quantity) AS total_quantity,
	DENSE_RANK() OVER(PARTITION BY dp.category, dp.sub_category ORDER BY SUM(fo.quantity) DESC) AS rank_quantity
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category, dp.product_name
)SUB
WHERE rank_quantity = 1;

-- Does the rank differ with total revenue?
SELECT
	category,
	sub_category,
	product_name,
	total_sales,
	rank_sales
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	dp.product_name,
	SUM(fo.sales) AS total_sales,
	DENSE_RANK() OVER(PARTITION BY dp.category, dp.sub_category ORDER BY SUM(fo.sales) DESC) AS rank_sales
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category, dp.product_name
)SUB
WHERE rank_sales = 1;

-- Within each category & sub category, what are the top products that contribute most to the total profit?
SELECT
	category,
	sub_category,
	product_name,
	total_profit,
	rank_profit
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	dp.product_name,
	SUM(fo.profit) AS total_profit,
	DENSE_RANK() OVER(PARTITION BY dp.category, dp.sub_category ORDER BY SUM(fo.profit) DESC) AS rank_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category, dp.product_name
)SUB
WHERE rank_profit = 1;

-- What are the top 10 products by profit?
SELECT
	product_name,
	total_profit,
	rank_profit
FROM
(
SELECT
	dp.product_name,
	SUM(fo.profit) AS total_profit,
	ROW_NUMBER() OVER(ORDER BY SUM(fo.profit) DESC) AS rank_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.product_name
)SUB
WHERE rank_profit <= 10;

-- What are our top 10 customers by profit?
SELECT
	first_name,
	last_name,
	total_profit,
	rank_profit
FROM
(
SELECT
	dc.customer_key,
	dc.first_name,
	dc.last_name,
	SUM(fo.profit) AS total_profit,
	ROW_NUMBER() OVER(ORDER BY SUM(fo.profit) DESC) AS rank_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key
GROUP BY 
	dc.customer_key,
	dc.first_name,
	dc.last_name
)SUB
WHERE rank_profit <= 10;
