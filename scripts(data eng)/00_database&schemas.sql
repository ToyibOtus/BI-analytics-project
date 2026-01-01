/*
===================================================================================
Build Database and Schemas
===================================================================================
Script Purpose:
	This script builds database [SalesDatabase]. Additionally, it builds 5 
	schemas [bronze], [silver], [silver_stg], [gold], and [metadata].

Warning:
	Running this script permanently deletes the database [SalesDatabase], along
	with all data in it.
	Ensure to have proper back up before running.
===================================================================================
*/
-- Use master database
USE master;
GO

-- Drop [SalesDatabase] if exist
IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'SalesDatabase')
BEGIN
	ALTER DATABASE SalesDatabase
	SET SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE SalesDatabase;
END;
GO

-- Create [SalesDatabase]
CREATE DATABASE SalesDatabase;
GO

-- Use newly created database [SalesDatabase]
USE SalesDatabase;
GO

-- Create schema [bronze]
CREATE SCHEMA bronze;
GO

-- Create schema [silver]
CREATE SCHEMA silver;
GO

-- Create schema [silver_stg]
CREATE SCHEMA silver_stg;
GO

-- Create schema [gold]
CREATE SCHEMA gold;
GO

-- Create schema [metadata]
CREATE SCHEMA metadata;
GO
