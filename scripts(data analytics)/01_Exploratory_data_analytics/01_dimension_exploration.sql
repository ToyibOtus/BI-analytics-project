/*
====================================================================================
Dimension Exploration
====================================================================================
Script Purpose:
	This script explores dimensions in relevant datasets.
====================================================================================
*/
SELECT DISTINCT country, city, postal_code FROM gold.dim_customers;

SELECT DISTINCT category, sub_category, product_name FROM gold.dim_products
ORDER BY category, sub_category, product_name;
