/*
========================================================================================
Data Integration Check
========================================================================================
Script Purpose:
	This script checks the integration capabilities between fact and dimension tables.
========================================================================================
*/
-- Check integration capabilities between fact orders & dim products
SELECT
	fo.product_key,
	dp.product_key,
	dp.product_id,
	dp.product_name
FROM gold.fact_orders fo
LEFT JOIN gold.dim_products dp
ON fo.product_key = dp.product_key;

-- Check integration capabilities between fact orders & dim customers
SELECT
	fo.customer_key,
	dc.customer_key,
	dc.customer_id,
	dc.first_name,
	dc.last_name
FROM gold.fact_orders fo
LEFT JOIN gold.dim_customers dc
ON fo.customer_key = dc.customer_key;
