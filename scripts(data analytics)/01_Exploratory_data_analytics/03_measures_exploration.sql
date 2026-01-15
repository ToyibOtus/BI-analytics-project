/*
=======================================================================================
Measures Exploration
=======================================================================================
Script Purpose:
	This script explores key business metrics, giving an overview of the business
	performance.
=======================================================================================
*/
-- How much revenue has been generated within the span of 4 years?
SELECT SUM(sales) AS total_sales FROM gold.fact_orders;

-- How many quantity of products were sold to generate this revenue?
SELECT SUM(quantity) AS total_quantity FROM gold.fact_orders;

-- How many orders generated this revenue?
SELECT COUNT(DISTINCT order_id) AS total_orders FROM gold.fact_orders;

-- What is the total profit made from this revenue?
SELECT SUM(profit) AS total_profit FROM gold.fact_orders;

-- What is the average selling price of our products?
SELECT AVG(unit_price) AS avg_selling_price FROM gold.fact_orders;

-- What is the highest price?
SELECT MAX(unit_price) AS highest_price FROM gold.fact_orders;

-- What is the lowest price?
SELECT MIN(unit_price) AS lowest_price FROM gold.fact_orders;

-- What is the average discount?
SELECT AVG(discount) AS avg_discount FROM gold.fact_orders;

-- What is the highest discount?
SELECT MAX(discount) AS highest_discount FROM gold.fact_orders;

-- What is the lowest discount?
SELECT MIN(discount) AS lowest_discount FROM gold.fact_orders;

-- What is the average shipping days
SELECT AVG(DATEDIFF(day, order_date, shipping_date)) AS avg_days_to_ship FROM gold.fact_orders;

-- How many customers do we have?
SELECT COUNT(customer_key) AS total_customers FROM gold.dim_customers;

-- How many of these customers have ordered?
SELECT COUNT(DISTINCT customer_key) AS total_customers_ordered FROM gold.fact_orders;

-- What is the avearge customer score?
SELECT AVG(score) AS avg_score FROM gold.dim_customers;

-- What is the highest score?
SELECT MAX(score) AS highest_score FROM gold.dim_customers;

-- What is the lowest score?
SELECT MIN(score) AS lowest_score FROM gold.dim_customers;

-- How many products do we have?
SELECT COUNT(product_key) AS total_products FROM gold.dim_products;

-- How many of these products have been ordered?
SELECT COUNT(DISTINCT product_key) AS total_products_ordered FROM gold.fact_orders;


-- Report consolidating all business metrics
SELECT 'Total Sales' AS measure_name, SUM(sales) AS measure_value FROM gold.fact_orders
UNION ALL
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_orders
UNION ALL
SELECT 'Total Orders', COUNT(DISTINCT order_id) FROM gold.fact_orders
UNION ALL
SELECT 'Total Profit', SUM(profit) FROM gold.fact_orders
UNION ALL
SELECT 'Avg Selling Price', AVG(unit_price) FROM gold.fact_orders
UNION ALL
SELECT 'Highest Selling Price', MAX(unit_price) FROM gold.fact_orders
UNION ALL
SELECT 'Lowest Selling Price', MIN(unit_price) FROM gold.fact_orders
UNION ALL
SELECT 'Avg Discount', AVG(discount) FROM gold.fact_orders
UNION ALL
SELECT 'Highest Discount', MAX(discount) FROM gold.fact_orders
UNION ALL
SELECT 'Lowest Discount', MIN(discount) FROM gold.fact_orders
UNION ALL
SELECT 'Average Days to Ship', AVG(DATEDIFF(day, order_date, shipping_date)) FROM gold.fact_orders
UNION ALL
SELECT 'Total Customers', COUNT(customer_key) FROM gold.dim_customers
UNION ALL
SELECT 'Total Customers Ordered', COUNT(DISTINCT customer_key) FROM gold.fact_orders
UNION ALL
SELECT 'Average Score', AVG(score) FROM gold.dim_customers
UNION ALL
SELECT 'Highest Score', MAX(score) FROM gold.dim_customers
UNION ALL
SELECT 'Lowest Score', MIN(score) FROM gold.dim_customers
UNION ALL
SELECT 'Total Products', COUNT(product_key) FROM gold.dim_products
UNION ALL
SELECT 'Total Products Ordered', COUNT(DISTINCT product_key) FROM gold.fact_orders;
