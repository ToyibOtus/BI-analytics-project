/*
==================================================================
DDL Script: Build Silver Tables
==================================================================
Script Purpose:
	This script builds and designs the structure of silver tables.
	Run this script to change the design of your silver tables.
==================================================================
*/
USE SalesDatabase;
GO

-- Drop table [silver.customers] if exists
IF OBJECT_ID('silver.customers', 'U') IS NOT NULL
DROP TABLE silver.customers;
GO

-- Create table [silver.customers]
CREATE TABLE silver.customers
(
	customer_id INT,
	first_name NVARCHAR(50),
	last_name NVARCHAR(50),
	postal_code INT,
	city NVARCHAR(50),
	country NVARCHAR(50),
	score INT,
	dwh_row_hash VARBINARY(64) NOT NULL,
	dwh_create_date DATETIME DEFAULT GETDATE() NOT NULL
);

-- Drop table [silver.orders] if exists
IF OBJECT_ID('silver.orders', 'U') IS NOT NULL
DROP TABLE silver.orders;
GO

-- Create table [silver.orders]
CREATE TABLE silver.orders
(
	order_id INT,
	customer_id INT,
	product_id INT,
	order_date NVARCHAR(50),
	shipping_date NVARCHAR(50),
	sales NVARCHAR(50),
	quantity INT,
	discount NVARCHAR(50),
	profit NVARCHAR(50),
	unit_price NVARCHAR(50),
	dwh_row_hash VARBINARY(64) NOT NULL,
	dwh_create_date DATETIME DEFAULT GETDATE() NOT NULL
);

-- Drop table [silver.products] if exists
IF OBJECT_ID('silver.products', 'U') IS NOT NULL
DROP TABLE silver.products;
GO

-- Create table [silver.products]
CREATE TABLE silver.products
(
	product_id INT,
	product_name NVARCHAR(200),
	category NVARCHAR(50),
	sub_category NVARCHAR(50),
	dwh_row_hash VARBINARY(64) NOT NULL,
	dwh_create_date DATETIME DEFAULT GETDATE() NOT NULL
);
