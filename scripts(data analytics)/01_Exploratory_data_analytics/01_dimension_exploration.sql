/*
=============================================================================
Dimension Exploration
=============================================================================
Script Purpose:
	This script explores relevant dimensions in gold layer, with the purpose
	of getting some level of familiarity with the business.
=============================================================================
*/
-- Explore geographical locations/hierarchy
SELECT DISTINCT country, city, postal_code FROM gold.dim_customers;

-- Explore product hierarchy
SELECT DISTINCT category, sub_category, product_name FROM gold.dim_products
ORDER BY category, sub_category, product_name;
