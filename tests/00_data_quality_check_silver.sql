/*
====================================================================================
Data Quality Checks on Silver Layer
====================================================================================
Script Purpose:
	This script performs data quality checks on all silver tables.
====================================================================================
*/
-- ====================================================
-- Data Quality Checks on silver.customers
-- ====================================================

-- Check for NULLS and duplicates in primary key
-- Expectation: No Result
SELECT
	customer_id,
	COUNT(*) AS duplicate_check
FROM silver.customers
GROUP BY customer_id
HAVING customer_id IS NULL OR COUNT(*) > 1;

-- Check for unwanted spaces in string fields
-- Expectation: No Result
SELECT
	first_name
FROM silver.customers
WHERE first_name != TRIM(first_name);

SELECT
	last_name
FROM silver.customers
WHERE last_name != TRIM(last_name);

SELECT
	city
FROM silver.customers
WHERE city != TRIM(city);

-- Check for NULLS in postal code
-- Expectation: No Result
SELECT
	postal_code
FROM silver.customers
WHERE postal_code IS NULL;

-- Data Standardization & Data Consistency
-- Expectation: User Friendly Values & No NULLS
SELECT DISTINCT country
FROM silver.customers;

-- Check for Invalid Score
-- Expectation: No Results
SELECT
	score
FROM silver.customers
WHERE score IS NULL OR score < 0;


-- ====================================================
-- Data Quality Checks on silver.products
-- ====================================================

-- Check for Nulls & duplicates in primary key
-- Expectation: No Result
SELECT
	product_id,
	COUNT(*) AS duplicate_check
FROM silver.products
GROUP BY product_id
HAVING COUNT(*) > 1 AND product_id IS NULL;


-- Check for unwanted spaces in string fields
-- Expectation: No Result
SELECT
	product_name
FROM silver.products
WHERE product_name <> TRIM(product_name);


SELECT
	category
FROM silver.products
WHERE category <> TRIM(category);


SELECT
	sub_category
FROM silver.products
WHERE sub_category <> TRIM(sub_category);


-- Data Standardization & Data Consistency
-- Expectation: User Friendly Values & No NULLS
SELECT DISTINCT category
FROM silver.products;


-- ====================================================
-- Data Quality Checks on silver.orders
-- ====================================================

-- Check for NULLs and duplicates in primary key
-- Expectation: No Result
SELECT 
	order_id,
	COUNT(*) AS duplicate_chk
FROM silver.orders
GROUP BY order_id
HAVING order_id IS NULL OR COUNT(*) > 1;

-- Check for NULLs in foreign keys
-- Expectation: No Result
SELECT
	customer_id
FROM silver.orders
WHERE customer_id IS NULL;

SELECT
	product_id
FROM silver.orders
WHERE product_id IS NULL;

-- Check for invalid date
-- Expectation: No Result
SELECT
	order_date
FROM silver.orders
WHERE order_date IS NULL OR LEN(order_date) < 10;

SELECT
	order_date,
	shipping_date
FROM silver.orders
WHERE order_date > shipping_date;

-- Check for invalid business metrics
-- Expectation: No Result
SELECT
	gross_sales,
	quantity,
	unit_price,
	profit,
	discount
FROM silver.orders
WHERE gross_sales IS NULL OR gross_sales <= 0 OR gross_sales != quantity * unit_price
OR quantity IS NULL OR quantity <= 0 OR quantity != gross_sales/unit_price 
OR unit_price IS NULL OR unit_price <= 0 OR unit_price != gross_sales/quantity
OR discount < 0 OR discount IS NULL
OR profit IS NULL;
