# Business Intelligence Analytics Project

Welcome to my **Business Intelligence Analytics Project**! This project walks you through how to build an sql-end-to-end-data warehouse. Designed as a portfolio project, it serves as 
an excellent resource to both data engineers and analysts, as it provides industry-best data engineering and analytics solutions, from building a data warehouse to generating analytical
reports, and thus enabling data-driven decisions by stakeholders.

---

## Project Overview

This project performs two main tasks:
* Build a data warehouse using the **Medallion Architecture (Bronze, Silver, Gold)**.
* Generate SQL & BI analytical reports.

It aims to support easy data access and retrieval, and guide business stake-holders to make informed-decisions.

---

## Skills Showcased
This project is for students and professionals seeking to enhance their skills in:

* **Data Architecture**
* **ETL Designing**
* **SQL Development**
* **Data Engineering**
* **Data Analytics**
* **BI Development**

---

## Project Requirements

This section walks you through what is expected from this project.

### Specifications: 

* **Data sources**: The source system that stores the raw data, which are presented as CSV files.
* **Build ETL Log Table**: Build log tables that track every ETL step, enabling easy monitoring, traceability, and debugging.
* **Data Ingestion**: Load raw data into the data warehouse.
* **Data Transformation**: Transform raw data into cleaned and prepared data.
* **Data Quality Check**: Verify and resolve existing data quality issues after transformations, and prior to data integration.
* **Data Integration**: Consolidate sales data into a single point of truth (data warehouse), enabling easy analytics & reporting.
* **Scope**: Latest data only; no historization allowed.
* **Documentation**: Provide clear documentation for analytics team and business stake-holders.
* **Data Analysis**: Generate insightful and actionable information from the data.

---

## 01. Build a Data Warehouse (Data Engineering)

### Objective
Build a data warehouse that consolidates sales data, and supports data analytics and BI reporting.

### Data Architecture
This data warehouse is built using the Medallion Architecture **Bronze**, **Silver**, and **Gold**.

![data_architecture.png](docs/00_data_architecture.png)

* **Bronze**: Stores raw data as-is.
* **Silver**: Houses cleaned and prepared data.
* **Gold**: Houses business-ready data.

## 02. Analytics & BI Reporting (Data Analytics)

This section of the project is divided into two phases **Exploratory Data Analytics (EDA)** and **Advanced Data Analytics**.

### Objectives
Generate SQL and BI reports that draw insight into:

* **Product Performance**
* **Customer Performance**
* **Sales Trends**

---

## Executive Dashboards
These dashboards provide an executive-level view of product and customer performance, focusing on profitability, pricing discipline, and revenue contribution to support data-driven strategic decisions.

### Product Performance Dashboard

![product_performance_dashboard.png](reports/product_performance_dashboard.png)

**Purpose**: Evaluate product profitability, revenue contribution, and margin erosion.

Key Business Questions Answered:

* Which subcategory of products drive the most profit?
* Did all subcategory of products generate more revenue relative to the previous year?
* Which products drive the most profit?
* Where is margin leakage occurring?

**Core Metrics**:

* Sales
* Profit
* Quantity Sold
* Profit Margin
* Avg Discount

### Customer Performance Dashboard

![customer_performance_dashboard.png](reports/customer_performance_dashboard.png)

**Purpose:** Assess customer profitability, revenue contribution, and discount dependence.

Key Business Questions Answered:

* What is the average sales per customers?
* Which customers erode margin through discount usage?
* Who are our most profitable customers?

**Core Metrics**:

* Customer Profit Margin
* Avg Discount
* Revenue Contribution

**Live Version of Dashboards**: https://public.tableau.com/views/ProductPerformanceDashboard_17719349195140/ProductPerformanceDashboard?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

---


## Tools & Technologies Used

* **Notion**: Project Planning
* **SQL Server**: Database engine that stores data.
* **SQL Server Management Studio (SSMS)**: Interface for interacting with SQL server.
* **Draw.io**: For designing the data architecture, data flow, integration model, and data model.
* **Git Hub**: For committing codes.
* **Tableau**: For data visualization.
---

## License
This project is licensed under **MIT License**. You are free to use, modify, or share with proper attribution.

---

## About Me
Hi there! I'm **Otusanya Toyib Oluwatimilehin**. I'm an aspiring **Data Engineer and Analyst** passionate about building reliable data pipelines, efficient data models, and generating data-driven business decisions. 

<img src="https://cdn-icons-png.flaticon.com/128/724/724664.png" width="18" alt="Phone"/> **07082154436** 
<img src="https://cdn-icons-png.flaticon.com/128/732/732200.png" width="18" alt="E-mail"/> **toyibotusanya@gmail.com**











