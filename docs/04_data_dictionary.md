# Data Dictionary for Gold Layer

---

## Overview
The gold layer is composed of business-ready data, structured to support easy data access and retrieval, and thus enabling BI analytics
and reporting. It contains two kinds of tables:
* **dimension table**
* **fact table**

---

## 01. gold.dim_customers
**Purpose:** Houses customer information, including geographic data.


Column                     |           Data Type               |         Description
|--------------------------|-----------------------------------|-----------------------------------|
customer_key               |INT                                |A surrogate key that uniquely identifies each customer record.
customer_id                |INT                                |A unique numerical identifier assigned to each customer.
first_name                 |NVARCHAR(50)                       |The first name of each customer.
last_name                  |NVARCHAR(50)                       |The last name of each customer.
postal_code                |INT                                |The geographical code of the customer delivery area.
city                       |NVARCHAR(50)                       |The customer city of residence (e,g., Versailles).
country                    |NVARCHAR(50)                       |The customer country of residence (e.g., France).
score                      |INT                                |The customer score, an indicator of customer performance.

---

## 02. gold.dim_products
**Purpose:** It holds product information, and their attributes.


Column                     |           Data Type               |         Description
|--------------------------|-----------------------------------|-----------------------------------|
product_key                |INT                                |A surrogate key that uniquely identifies each product record.
product_id                 |INT                                |A unique numerical identifier assigned to each product.
product_name               |NVARCHAR(200)                      |A descriptive name of each product (e,g., Bush Somerset Collection Bookcase). 
category                   |NVARCHAR(50)                       |A broad classification of each product (e.g., Furniture).
sub_category               |NVARCHAR(50)                       |A more detailed classification of each product (e.g., Bookcases).

---

## 03. gold.fact_orders
**Purpose:** It holds transactional records of customers and products.


Column                     |           Data Type               |         Description
|--------------------------|-----------------------------------|-----------------------------------|
order_id                   |INT                                |A numerical number assigned to each transaction.
customer_key               |INT                                |A surrogate key that connects fact table to dimension table, dim_customers.
product_key                |INT                                |A surrogate key that connects fact table to dimension table, dim_products.
order_date                 |DATE                               |The date an order was placed by each customer.
shipping_date              |DATE                               |The date the ordered product was shipped.
gross_sales                |DECIMAL(10,2)                      |Total revenue generated from an order assuming product(s) is sold at base price, calculated as quantity * unit_price.
net_sales                  |DECIMAL(10,2)                      |Actual realized revenue generated per order after gross_sales has been discounted, calculated as (1 - discount) * gross_sales.
quantity                   |INT                                |The quantity of products ordered.
discount                   |DECIMAL(10,2)                      |The percentage amount deducted from the original price of product, expressed as fraction.
profit                     |DECIMAL(10,2)                      |The total profit made each sale, after applying discount.
unit_price                 |DECIMAL(10,2)                      |The monetary value (dollars) of one unit of product. 

---

## 04. gold.vw_customers_report
**Purpose:** Provides a consolidated view of customer performance, profitability, and behavioral metrics.
Used for customer segmentation, retention analysis, discount dependency assessment, and executive reporting.


Column                     |           Data Type               |         Description
|--------------------------|-----------------------------------|-----------------------------------|
customer_id                |INT                                |A numerical unique identifier assigned to each customer.
customer_key               |INT                                |A surrogate key that uniquely identifies each customer.
customer_name              |NVARCHAR(101)                      |The first & last names of customer recorded in the system.
postal_code                |INT                                |The geographical code of the customer delivery area.
city                       |NVARCHAR(50)                       |The customer city of residence (e,g., Versailles).
country                    |NVARCHAR(50)                       |The customer country of residence (e.g., France). 
score                      |INT                                |The customer score, an indicator of customer performance.
first_order_date           |DATE                               |The date each customer placed their first order.
last_order_date            |DATE                               |The date each customer placed their last order.
lifespan_month             |INT                                |Months between first and last order dates. An indicator of customer's loyalty.
recency_month              |INT                                |The duration in month since each customer last placed an order.
total_orders               |INT                                |The total number of orders made between first and last order dates.
total_quantity             |INT                                |The total amount of products purchased between first and last order dates.
total_sales                |DECIMAL(38,2)                      |The total revenue generated between first and last order dates.
total_profit               |DECIMAL(38,2)                      |The total profit generated between first and last order dates.
avg_discount               |FLOAT                              |The weighted average discount. A metric to measure customer's reliance on discount.
avg_order_value            |FLOAT                              |The average revenue generated per order.
avg_monthly_spend          |FLOAT                              |The average revenue generated per month.
avg_profit_per_sales       |FLOAT                              |The average profit per revenue.
performance_score          |FLOAT                              |Weighted composite score (0-1). Overall customer value index.
customer_status            |VARCHAR(7)                         |Labels assigned to customer based on performance score. (e.g., VIP, Regular, & New).

## Performance Score Logic

Composite score calculated using weighted ranking of:

* Profit contribution (40%)
* Revenue contribution (20%)
* Order frequency (10%)
* Loyalty (10%)
* Recency (10%)
* Discount reliance (10%)

Score range: 0 (lowest) to 1 (highest)

---

## 04. gold.vw_products_report
**Purpose:** Provides aggregated product-level performance metrics for evaluating revenue, profitability, demand velocity, discount
exposure, and lifecycle status.


Column                     |           Data Type               |         Description
|--------------------------|-----------------------------------|-----------------------------------|
product_id                 |INT                                |A numerical unique identifier assigned to each product.
product_key                |INT                                |A surrogate key that uniquely identifies each product
product_name               |NVARCHAR(200)                      |A descriptive name of each product (e,g., Bush Somerset Collection Bookcase).
category                   |NVARCHAR(50)                       |A broad classification of each product (e.g., Furniture).
sub_category               |NVARCHAR(50)                       |A more detailed classification of each product (e.g., Bookcases).
last_order_date            |DATE                               |The last date each product was ordered.
lifespan_month             |INT                                |Active selling duration in months. An indicator of product maturity.
recency_month              |INT                                |The duration in month since each product was last ordered 
avg_shipping_days          |INT                                |The average shipping days.
total_orders               |INT                                |The total number of orders between first and last order dates.
total_quantity             |INT                                |The total amount of unites sold between first and last order dates.
total_sales                |DECIMAL(38,2)                      |The total revenue generated between first and last order dates.
total_profit               |DECIMAL(38,2)                      |The total profit generated between first and last order dates.
avg_discount               |FLOAT                              |The weighted average discount. A metric to measure dependency on discount.
avg_order_revenue          |FLOAT                              |Revenue generated per order.
avg_monthly_revenue        |FLOAT                              |Revenue generated per month.
avg_profit_per_revenue     |FLOAT                              |Profit generated per revenue.
performance_score          |FLOAT                              |Weighted composite score (0-1). Overall product performance index.
product_status             |NVARCHAR(14)                       |Labels assigned to product based on performance score(e.g, High, Mid, & Low Performers).


## Performance Score Logic

Composite score weighted by:

* Profit (40%)
* Revenue (20%)
* Quantity (15%)
* Recency (10%)
* Discount reliance (10%)
* Lifespan (5%)

Score range: 0 (lowest) to 1 (highest)















