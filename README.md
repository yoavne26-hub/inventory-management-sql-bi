
# Inventory Management SQL & Business Intelligence Project

A relational database and analytics system built using Microsoft SQL Server and Power BI.

The project simulates an e-commerce platform for customizable sports products and demonstrates the full lifecycle of a data system including database design, relational schema implementation, advanced SQL analytics, data integrity enforcement, and business intelligence dashboards.

The system stores and analyzes information about customers, products, designs, orders, reviews, and shopping carts in order to generate business insights.

---

# Project Goals

The main goals of the project were to design a relational database architecture, implement data integrity constraints, build analytical SQL queries, detect business patterns and anomalies, and create Power BI dashboards for decision support.

The system simulates realistic data to analyze customer purchasing behavior, product performance, and potential reseller activity.

---

# Database Architecture

The system is designed as a relational database composed of several main entities including customers, user accounts, addresses, shopping carts, orders, products, designs, reviews, and product roster entries.

The schema enforces relationships using primary keys, foreign keys, and constraints to maintain data integrity.

Entity Relationship Diagram:

![ERD](screenshots/erd/erd.jpg)

---

# Database Constraints and Integrity

Several constraints were implemented to ensure valid and consistent data.

Foreign keys enforce referential integrity between related tables such as Orders and Carts, Rosters and Designs, Products and SportFields, and Reviews and Products.

Check constraints validate different types of input including phone number format, email format, positive quantities for product items, and valid credit card expiration dates.

These constraints prevent inconsistent or invalid records from entering the system.

---

# SQL Analytical Queries

The project includes multiple analytical queries designed to answer business questions.

One query identifies the sport categories generating the highest revenue by aggregating quantities sold and total earnings per category.

Another query detects high value customers by counting the number of orders placed and calculating total spending over the last five years.

Another analysis identifies products whose average rating is below the average rating of their sport category.

Example query result:

![Low Rated Products](screenshots/sql_results/query_low_rated_products.jpg)

---

# Window Functions

Window functions were used to analyze revenue trends over time.

The query calculates monthly revenue, compares it with the previous month’s sales, and computes the average revenue of the previous three months. This allows identifying growth and decline patterns in sales performance.

---

# Common Table Expressions (CTE)

Common table expressions were used to build multi stage analytical pipelines.

One example identifies VIP customers by first calculating order totals, then computing the average order value, identifying customers with orders above that average, and finally detecting countries with the highest number of VIP customers.

Example output:

![VIP Countries](screenshots/sql_results/cte_vip_countries.jpg)

---

# SQL Views

Several views were created to simplify business analytics.

One view combines customers, products, orders, and addresses to provide a detailed representation of customer purchase activity.

Another view identifies abandoned shopping carts that were created but never converted into orders.

Another view summarizes customer activity to detect suspicious reseller behavior based on the number of sport categories ordered, the number of product designs purchased, and total quantity ordered.

---

# SQL Functions

Custom SQL functions were implemented to support advanced analysis.

One function calculates how frequently customers place orders using their saved addresses.

![Saved Address Usage](screenshots/sql_results/function_saved_address_usage.jpg)

Another function detects customers with unusual ordering behavior such as purchasing across multiple sport categories or ordering many different product designs.

![Suspicious Resellers](screenshots/sql_results/function_suspicious_resellers.jpg)

---

# Trigger Implementation

A trigger was implemented to ensure review integrity.

Users are only allowed to submit a review if they have previously purchased the product. If a review is inserted for a product that was not purchased, the trigger automatically removes the record. This ensures the reliability of the review system.

---

# Stored Procedure

A stored procedure was developed to maintain database hygiene by cleaning abandoned carts.

The procedure removes carts that contain no items and carts that contain items but were never converted into orders.

Before cleanup:

![Before Cleanup](screenshots/sql_results/procedure_before_cleanup.jpg)

After cleanup:

![After Cleanup](screenshots/sql_results/procedure_after_cleanup.jpg)

---

# Business Intelligence Dashboard

Power BI dashboards were created to visualize insights extracted from the database.

The dashboards analyze revenue trends over time, sales distribution by sport category, customer purchasing behavior, and potential reseller activity.

Example dashboard:

![Power BI Dashboard](screenshots/powerbi/dashboard_overview.png)

---

# Repository Structure

inventory-management-sql-bi

sql  
01_build_database.sql  
02_business_queries_and_analytics.sql  

data  
sample_data.xlsx  

powerbi  
inventory_analytics_dashboard.pbix  

screenshots  
erd  
powerbi  
sql_results  

docs  
project_part1_business_analysis.docx  
project_part2_database_design.docx  
project_part3_sql_bi.docx  

---

# Technologies Used

Microsoft SQL Server  
T-SQL  
Power BI  
Relational Database Design  
Business Intelligence Analytics  

---

# How to Run the Project

Open SQL Server Management Studio.

Run the script:

sql/01_build_database.sql

This creates the full database schema and constraints.

Import the dataset from:

data/sample_data.xlsx

Run the analytical queries:

sql/02_business_queries_and_analytics.sql

Finally open the Power BI dashboard:

powerbi/inventory_analytics_dashboard.pbix

---

# Author

Yoav Nesher  
Industrial Engineering and Management  
Ben Gurion University
"""

output_path = "/mnt/data/README.md"
pypandoc.convert_text(text, 'md', format='md', outputfile=output_path, extra_args=['--standalone'])

output_path
