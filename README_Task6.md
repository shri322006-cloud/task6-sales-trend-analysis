# Task 6: Sales Trend Analysis Using Aggregations

## Overview
This repository contains the SQL script for **Task 6: Sales Trend Analysis** from the Data Analyst Internship project.  
The script is designed to work across **PostgreSQL**, **MySQL 8+**, and **SQLite 3**.

## Features
- **Monthly Revenue & Order Volume** aggregation.
- **Time-Window Filtering** for specific analysis periods.
- **Top 3 Months by Revenue** extraction.
- **View Creation** (`monthly_sales_summary`) and **Materialized Table** (`monthly_sales_results`).
- **Index Recommendations** to improve query performance.

## File
- `task6_sales_trend.sql` – The complete SQL script, including versions for PostgreSQL, MySQL, and SQLite.

## How to Use
1. **Select your database type** (PostgreSQL, MySQL, or SQLite).
2. **Modify table/schema names** (`online_sales.orders`) if needed.
3. **Run queries** to:
   - Generate monthly summaries
   - Filter by a specific date range
   - Identify top months by revenue
4. **Optional:** Create indexes for faster aggregation.

## Example Run (PostgreSQL)
```sql
-- Monthly revenue and order volume
WITH base AS (
  SELECT 
    date_trunc('month', order_date)::date AS month_start,
    EXTRACT(YEAR FROM order_date)::int AS year,
    EXTRACT(MONTH FROM order_date)::int AS month,
    COALESCE(amount, 0) AS amount,
    order_id
  FROM online_sales.orders
)
SELECT 
  month_start,
  year,
  month,
  SUM(amount) AS monthly_revenue,
  COUNT(DISTINCT order_id) AS order_count
FROM base
GROUP BY month_start, year, month
ORDER BY month_start;
```

## License
This project is open-source and can be used for educational and training purposes.
