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
	total_gross_sales,
	rank_sales
FROM
(
SELECT
	dc.country,
	SUM(fo.gross_sales) AS total_gross_sales,
	DENSE_RANK() OVER(ORDER BY SUM(fo.gross_sales) DESC) AS rank_sales
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
	DENSE_RANK() OVER(ORDER BY total_gross_sales DESC) AS rank_sales,
	DENSE_RANK() OVER(ORDER BY total_profit DESC) AS rank_profit
FROM
(
SELECT
	dc.country,
	COUNT(DISTINCT dc.customer_key) AS total_customers,
	(CAST(COUNT(DISTINCT fo.customer_key) AS FLOAT))/COUNT(DISTINCT dc.customer_key) * 100 AS percent_customers_ordered,
	COUNT(DISTINCT fo.order_id) AS total_orders,
	SUM(COALESCE(fo.quantity, 0)) AS total_quantity,
	SUM(COALESCE(fo.gross_sales, 0)) AS total_gross_sales,
	SUM(COALESCE(fo.profit, 0)) AS total_profit
FROM gold.dim_customers dc
LEFT JOIN gold.fact_orders fo
ON dc.customer_key = fo.customer_key
GROUP BY dc.country
)SUB;


-- What is the top category based on orders?
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


-- What category of product has the highest customer volume?
SELECT
	dp.category,
	COUNT(DISTINCT fo.customer_key) AS total_customers_ordered,
	DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT fo.customer_key) DESC) AS rank_customer_ordered
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category;


-- Which category has it's highest proportion of products ordered?
SELECT
	dp.category,
	COUNT(DISTINCT dp.product_key) AS total_products,
	COUNT(DISTINCT fo.product_key) AS total_products_ordered,
	ROUND(CAST(COUNT(DISTINCT fo.product_key) AS FLOAT)/COUNT(DISTINCT dp.product_key) * 100, 2) AS percent_products_ordered,
	DENSE_RANK() OVER(ORDER BY ROUND(CAST(COUNT(DISTINCT fo.product_key) AS FLOAT)/COUNT(DISTINCT dp.product_key) * 100, 2) DESC) AS 
	rank_percent_products_ordered
FROM gold.dim_products dp
LEFT JOIN gold.fact_orders fo 
ON fo.product_key = dp.product_key
GROUP BY dp.category;


-- Which category brings in the most revenue?
SELECT
	dp.category,
	SUM(fo.gross_sales) AS total_gross_sales,
	DENSE_RANK() OVER(ORDER BY SUM(fo.gross_sales) DESC) AS rank_sales
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


-- How do the ranks correlate to one another?
SELECT
	category,
	DENSE_RANK() OVER(ORDER BY total_orders DESC) AS rank_orders,
	DENSE_RANK() OVER(ORDER BY total_quantity DESC) AS rank_quantity,
	DENSE_RANK() OVER(ORDER BY total_customers_ordered DESC) AS rank_customers_ordered,
	DENSE_RANK() OVER(ORDER BY percent_products_ordered DESC) AS rank_percent_products_ordered,
	DENSE_RANK() OVER(ORDER BY total_gross_sales DESC) AS rank_sales,
	DENSE_RANK() OVER(ORDER BY total_profit DESC) AS rank_profit
FROM
(
SELECT
	dp.category,
	COUNT(DISTINCT fo.order_id) AS total_orders,
	SUM(fo.quantity) AS total_quantity,
	COUNT(DISTINCT fo.customer_key) AS total_customers_ordered,
	ROUND(CAST(COUNT(DISTINCT fo.product_key) AS FLOAT)/COUNT(DISTINCT dp.product_key) * 100, 2) AS percent_products_ordered,
	SUM(fo.gross_sales) AS total_gross_sales,
	SUM(fo.profit) AS total_profit
FROM gold.dim_products dp 
LEFT JOIN gold.fact_orders fo
ON fo.product_key = dp.product_key
GROUP BY dp.category
)SUB;


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


-- Within each category, which subcategory of products has the highest customer volume?
SELECT
	category,
	sub_category,
	total_customers_ordered,
	rank_customer_ordered
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	COUNT(DISTINCT fo.customer_key) AS total_customers_ordered,
	DENSE_RANK() OVER(PARTITION BY dp.category ORDER BY COUNT(DISTINCT fo.customer_key) DESC) AS rank_customer_ordered
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category
)SUB
WHERE rank_customer_ordered <= 3;


-- Within each category, which subcategory of products has it's highest proportion of products ordered?
SELECT
	category,
	sub_category,
	total_products,
	total_products_ordered,
	percent_products_ordered,
	rank_percent_products_ordered
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	COUNT(DISTINCT dp.product_key) AS total_products,
	COUNT(DISTINCT fo.product_key) AS total_products_ordered,
	ROUND(CAST(COUNT(DISTINCT fo.product_key) AS FLOAT)/COUNT(DISTINCT dp.product_key) * 100, 2) AS percent_products_ordered,
	DENSE_RANK() OVER(PARTITION BY dp.category ORDER BY ROUND(CAST(COUNT(DISTINCT fo.product_key) AS FLOAT)
	/COUNT(DISTINCT dp.product_key) * 100, 2) DESC) AS rank_percent_products_ordered
FROM gold.dim_products dp
LEFT JOIN gold.fact_orders fo 
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category
)SUB
WHERE rank_percent_products_ordered <= 3;


-- Does the rank differ with total revenue?
SELECT
	category,
	sub_category,
	total_gross_sales,
	rank_sales
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	SUM(fo.gross_sales) AS total_gross_sales,
	DENSE_RANK() OVER(PARTITION BY dp.category ORDER BY SUM(fo.gross_sales) DESC) AS rank_sales
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


-- What is the difference in sales and profit ranks in each subcategory of product?

SELECT
	category,
	sub_category,
	total_gross_sales,
	total_profit,
	rank_sales,
	rank_profit,
	ABS(rank_sales - rank_profit) AS rank_diff
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	SUM(fo.gross_sales) AS total_gross_sales,
	SUM(fo.profit) AS total_profit,
	DENSE_RANK() OVER(PARTITION BY dp.category ORDER BY SUM(fo.gross_sales) DESC) AS rank_sales,
	DENSE_RANK() OVER(PARTITION BY dp.category ORDER BY SUM(fo.profit) DESC) AS rank_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category
)SUB
WHERE rank_sales <= 3;


-- Within each category & sub category, what is the top product based on orders?
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


-- Within each category & sub category, what is the top product by quantity?
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


-- Within each category & subcategory, which product has the highest customer volume?
SELECT
	category,
	sub_category,
	product_name,
	total_customers_ordered,
	rank_customer_ordered
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	dp.product_name,
	COUNT(DISTINCT fo.customer_key) AS total_customers_ordered,
	DENSE_RANK() OVER(PARTITION BY dp.category, dp.sub_category ORDER BY COUNT(DISTINCT fo.customer_key) DESC) AS rank_customer_ordered
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY
	dp.category,
	dp.sub_category,
	dp.product_name
)SUB
WHERE rank_customer_ordered <= 1;


-- Does the rank differ with total revenue?
SELECT
	category,
	sub_category,
	product_name,
	total_gross_sales,
	rank_sales
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	dp.product_name,
	SUM(fo.gross_sales) AS total_gross_sales,
	DENSE_RANK() OVER(PARTITION BY dp.category, dp.sub_category ORDER BY SUM(fo.gross_sales) DESC) AS rank_sales
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category, dp.product_name
)SUB
WHERE rank_sales = 1;


-- Within each category & sub category, what is the top product that contribute most to the total profit?
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



-- How much do top revenue generating products in each subcategory differ from the profit rank?
SELECT
	category,
	sub_category,
	product_name,
	total_gross_sales,
	total_profit,
	rank_sales,
	rank_profit,
	ABS(rank_sales - rank_profit) AS rank_diff
FROM
(
SELECT
	dp.category,
	dp.sub_category,
	dp.product_name,
	SUM(fo.gross_sales) AS total_gross_sales,
	SUM(fo.profit) AS total_profit,
	DENSE_RANK() OVER(PARTITION BY dp.category, dp.sub_category ORDER BY SUM(fo.gross_sales) DESC) AS rank_sales,
	DENSE_RANK() OVER(PARTITION BY dp.category, dp.sub_category ORDER BY SUM(fo.profit) DESC) AS rank_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.category, dp.sub_category, dp.product_name
)SUB
WHERE rank_sales = 1;


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


-- What are the top 10 products by sales?
SELECT
	product_name,
	total_gross_sales,
	rank_sales
FROM
(
SELECT
	dp.product_name,
	SUM(fo.gross_sales) AS total_gross_sales,
	ROW_NUMBER() OVER(ORDER BY SUM(fo.gross_sales) DESC) AS rank_sales
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.product_name
)SUB
WHERE rank_sales <= 10;


-- Who are our top products revenue-wise, 
-- and how much does their sales rank differ from profit rank? 
SELECT
	product_name,
	total_gross_sales,
	total_profit,
	rank_sales,
	rank_profit,
	ABS(rank_sales - rank_profit) AS rank_diff
FROM
(
SELECT
	dp.product_name,
	SUM(fo.gross_sales) AS total_gross_sales,
	SUM(fo.profit) AS total_profit,
	ROW_NUMBER() OVER(ORDER BY SUM(fo.gross_sales) DESC) AS rank_sales,
	ROW_NUMBER() OVER(ORDER BY SUM(fo.profit) DESC) AS rank_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key
GROUP BY dp.product_name
)SUB
WHERE rank_sales <= 10;


-- Who are our top 10 customers by profit?
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


-- Who are our top 10 customers based on total revenue generated?
SELECT
	first_name,
	last_name,
	total_gross_sales,
	rank_sales
FROM
(
SELECT
	dc.customer_key,
	dc.first_name,
	dc.last_name,
	SUM(fo.gross_sales) AS total_gross_sales,
	ROW_NUMBER() OVER(ORDER BY SUM(fo.gross_sales) DESC) AS rank_sales
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key
GROUP BY 
	dc.customer_key,
	dc.first_name,
	dc.last_name
)SUB
WHERE rank_sales <= 10;


-- Who are our top customers revenue-wise, 
-- and how much does their sales rank differ from profit rank?
SELECT
	first_name,
	last_name,
	total_gross_sales,
	total_profit,
	rank_sales,
	rank_profit,
	ABS(rank_sales - rank_profit) AS rank_diff
FROM
(
SELECT
	dc.customer_key,
	dc.first_name,
	dc.last_name,
	SUM(fo.gross_sales) AS total_gross_sales,
	SUM(fo.profit) AS total_profit,
	ROW_NUMBER() OVER(ORDER BY SUM(fo.gross_sales) DESC) AS rank_sales,
	ROW_NUMBER() OVER(ORDER BY SUM(fo.profit) DESC) AS rank_profit
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key
GROUP BY 
	dc.customer_key,
	dc.first_name,
	dc.last_name
)SUB
WHERE rank_sales <= 10;


-- Who are our top customers based on number of orders?
SELECT
	first_name,
	last_name,
	total_orders,
	rank_orders
FROM
(
SELECT
	dc.customer_key,
	dc.first_name,
	dc.last_name,
	COUNT(DISTINCT order_id) AS total_orders,
	DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT order_id) DESC) AS rank_orders
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key
GROUP BY 
	dc.customer_key,
	dc.first_name,
	dc.last_name
)SUB
WHERE rank_orders <= 3;


-- Is the rank consistent with quantity of purchases?
SELECT
	first_name,
	last_name,
	total_quantity,
	rank_quantity
FROM
(
SELECT
	dc.customer_key,
	dc.first_name,
	dc.last_name,
	SUM(fo.quantity) AS total_quantity,
	DENSE_RANK() OVER(ORDER BY SUM(fo.quantity) DESC) AS rank_quantity
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key
GROUP BY 
	dc.customer_key,
	dc.first_name,
	dc.last_name
)SUB
WHERE rank_quantity <= 5;
