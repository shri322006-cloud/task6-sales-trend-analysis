-- ===============================================================
-- DATA ANALYST INTERNSHIP - TASK 6: Sales Trend Analysis
-- Target DBs: PostgreSQL / MySQL 8+ / SQLite 3
-- Assumptions:
--   Schema: online_sales
--   Table : orders(order_date DATE/TIMESTAMP, amount NUMERIC, product_id INT [, order_id INT])
-- Notes:
--   - If your table does NOT have order_id, use COUNT(*) for order volume.
--   - All queries use COALESCE(amount,0) to handle NULLs.
--   - Replace :year_from / :year_to or the literal dates as needed.
-- ===============================================================

-- 0) OPTIONAL: use database/schema (uncomment if needed)
-- PostgreSQL:   SET search_path TO online_sales;
-- MySQL:        USE online_sales;
-- SQLite:       -- no schema switch

/* =============================================================
   1) Monthly Revenue & Order Volume (PostgreSQL syntax)
   ============================================================= */
-- Preferred version when orders.order_id exists
-- (PostgreSQL)
WITH base AS (
  SELECT 
    date_trunc('month', order_date)::date AS month_start,
    EXTRACT(YEAR FROM order_date)::int       AS year,
    EXTRACT(MONTH FROM order_date)::int      AS month,
    COALESCE(amount, 0)                      AS amount,
    order_id
  FROM online_sales.orders
)
SELECT 
  month_start,
  year,
  month,
  SUM(amount)                              AS monthly_revenue,
  COUNT(DISTINCT order_id)                 AS order_count
FROM base
GROUP BY month_start, year, month
ORDER BY month_start;

-- Fallback if orders.order_id does NOT exist (PostgreSQL)
WITH base AS (
  SELECT 
    date_trunc('month', order_date)::date AS month_start,
    EXTRACT(YEAR FROM order_date)::int       AS year,
    EXTRACT(MONTH FROM order_date)::int      AS month,
    COALESCE(amount, 0)                      AS amount
  FROM online_sales.orders
)
SELECT 
  month_start,
  year,
  month,
  SUM(amount)      AS monthly_revenue,
  COUNT(*)         AS order_count
FROM base
GROUP BY month_start, year, month
ORDER BY month_start;

 
/* =============================================================
   2) Same analysis limited to a specific time window (PostgreSQL)
   Replace the dates as needed.
   ============================================================= */
WITH filtered AS (
  SELECT *
  FROM online_sales.orders
  WHERE order_date >= DATE '2024-01-01'
    AND order_date <  DATE '2025-01-01'
)
SELECT 
  date_trunc('month', order_date)::date     AS month_start,
  EXTRACT(YEAR FROM order_date)::int        AS year,
  EXTRACT(MONTH FROM order_date)::int       AS month,
  SUM(COALESCE(amount,0))                   AS monthly_revenue,
  COUNT(*)                                  AS order_count -- swap to COUNT(DISTINCT order_id) if available
FROM filtered
GROUP BY month_start, year, month
ORDER BY month_start;


/* =============================================================
   3) Top 3 months by revenue (PostgreSQL)
   ============================================================= */
WITH m AS (
  SELECT 
    date_trunc('month', order_date)::date AS month_start,
    SUM(COALESCE(amount,0))               AS monthly_revenue
  FROM online_sales.orders
  GROUP BY 1
)
SELECT *
FROM m
ORDER BY monthly_revenue DESC
LIMIT 3;


/* =============================================================
   4) MATERIALIZE results to a table + CREATE VIEW (PostgreSQL)
   ============================================================= */
DROP VIEW IF EXISTS online_sales.monthly_sales_summary;
CREATE VIEW online_sales.monthly_sales_summary AS
SELECT 
  date_trunc('month', order_date)::date     AS month_start,
  EXTRACT(YEAR FROM order_date)::int        AS year,
  EXTRACT(MONTH FROM order_date)::int       AS month,
  SUM(COALESCE(amount,0))                   AS monthly_revenue,
  COUNT(*)                                  AS order_count -- or COUNT(DISTINCT order_id)
FROM online_sales.orders
GROUP BY month_start, year, month;

-- Materialize to a table (creates once; rerun with DROP TABLE IF you want to refresh)
CREATE TABLE IF NOT EXISTS online_sales.monthly_sales_results AS
SELECT * FROM online_sales.monthly_sales_summary;


/* =============================================================
   5) Index recommendation (PostgreSQL)
   ============================================================= */
-- Speeds up grouping/filtering by month/year
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON online_sales.orders(order_date);
-- If you have order_id and query DISTINCT often:
-- CREATE INDEX IF NOT EXISTS idx_orders_order_id ON online_sales.orders(order_id);


/* =============================================================
   6) MySQL 8+ equivalents
   ============================================================= */
-- Overall monthly revenue & volume (order_id version)
SELECT 
  DATE_FORMAT(order_date, '%Y-%m-01')                AS month_start,
  YEAR(order_date)                                   AS year,
  MONTH(order_date)                                  AS month,
  SUM(COALESCE(amount,0))                            AS monthly_revenue,
  COUNT(DISTINCT order_id)                           AS order_count
FROM online_sales.orders
GROUP BY month_start, year, month
ORDER BY month_start;

-- Fallback without order_id (MySQL)
SELECT 
  DATE_FORMAT(order_date, '%Y-%m-01')                AS month_start,
  YEAR(order_date)                                   AS year,
  MONTH(order_date)                                  AS month,
  SUM(COALESCE(amount,0))                            AS monthly_revenue,
  COUNT(*)                                           AS order_count
FROM online_sales.orders
GROUP BY month_start, year, month
ORDER BY month_start;

-- Time window (MySQL) - edit dates as needed
SELECT 
  DATE_FORMAT(order_date, '%Y-%m-01')                AS month_start,
  YEAR(order_date)                                   AS year,
  MONTH(order_date)                                  AS month,
  SUM(COALESCE(amount,0))                            AS monthly_revenue,
  COUNT(*)                                           AS order_count
FROM online_sales.orders
WHERE order_date >= '2024-01-01'
  AND order_date <  '2025-01-01'
GROUP BY month_start, year, month
ORDER BY month_start;

-- Top 3 months by revenue (MySQL)
SELECT 
  DATE_FORMAT(order_date, '%Y-%m-01') AS month_start,
  SUM(COALESCE(amount,0))             AS monthly_revenue
FROM online_sales.orders
GROUP BY month_start
ORDER BY monthly_revenue DESC
LIMIT 3;

-- View + results table (MySQL)
DROP VIEW IF EXISTS online_sales.monthly_sales_summary;
CREATE VIEW online_sales.monthly_sales_summary AS
SELECT 
  DATE_FORMAT(order_date, '%Y-%m-01')                AS month_start,
  YEAR(order_date)                                   AS year,
  MONTH(order_date)                                  AS month,
  SUM(COALESCE(amount,0))                            AS monthly_revenue,
  COUNT(*)                                           AS order_count
FROM online_sales.orders
GROUP BY month_start, year, month;

CREATE TABLE IF NOT EXISTS online_sales.monthly_sales_results AS
SELECT * FROM online_sales.monthly_sales_summary;

-- Indexes (MySQL)
CREATE INDEX idx_orders_order_date ON online_sales.orders(order_date);
-- CREATE INDEX idx_orders_order_id  ON online_sales.orders(order_id);


/* =============================================================
   7) SQLite 3 equivalents
   ============================================================= */
-- Overall monthly revenue & volume (order_id version)
SELECT 
  DATE(strftime('%Y-%m-01', order_date))            AS month_start,
  CAST(strftime('%Y',  order_date) AS INT)          AS year,
  CAST(strftime('%m',  order_date) AS INT)          AS month,
  SUM(COALESCE(amount,0))                           AS monthly_revenue,
  COUNT(DISTINCT order_id)                          AS order_count
FROM online_sales_orders AS orders -- If your table name includes schema, rename or ATTACH DB accordingly
GROUP BY month_start, year, month
ORDER BY month_start;

-- Fallback without order_id (SQLite)
SELECT 
  DATE(strftime('%Y-%m-01', order_date))            AS month_start,
  CAST(strftime('%Y',  order_date) AS INT)          AS year,
  CAST(strftime('%m',  order_date) AS INT)          AS month,
  SUM(COALESCE(amount,0))                           AS monthly_revenue,
  COUNT(*)                                          AS order_count
FROM online_sales_orders AS orders
GROUP BY month_start, year, month
ORDER BY month_start;

-- Time window (SQLite)
SELECT 
  DATE(strftime('%Y-%m-01', order_date))            AS month_start,
  CAST(strftime('%Y',  order_date) AS INT)          AS year,
  CAST(strftime('%m',  order_date) AS INT)          AS month,
  SUM(COALESCE(amount,0))                           AS monthly_revenue,
  COUNT(*)                                          AS order_count
FROM online_sales_orders AS orders
WHERE DATE(order_date) >= DATE('2024-01-01')
  AND DATE(order_date) <  DATE('2025-01-01')
GROUP BY month_start, year, month
ORDER BY month_start;

-- Top 3 months by revenue (SQLite)
SELECT 
  DATE(strftime('%Y-%m-01', order_date)) AS month_start,
  SUM(COALESCE(amount,0))                AS monthly_revenue
FROM online_sales_orders AS orders
GROUP BY month_start
ORDER BY monthly_revenue DESC
LIMIT 3;

-- "View" + results table (SQLite)
DROP VIEW IF EXISTS monthly_sales_summary;
CREATE VIEW monthly_sales_summary AS
SELECT 
  DATE(strftime('%Y-%m-01', order_date))            AS month_start,
  CAST(strftime('%Y',  order_date) AS INT)          AS year,
  CAST(strftime('%m',  order_date) AS INT)          AS month,
  SUM(COALESCE(amount,0))                           AS monthly_revenue,
  COUNT(*)                                          AS order_count
FROM online_sales_orders AS orders
GROUP BY month_start, year, month;

CREATE TABLE IF NOT EXISTS monthly_sales_results AS
SELECT * FROM monthly_sales_summary;

-- Index (SQLite)
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON online_sales_orders(order_date);

-- ===============================================================
-- End of script
-- ===============================================================
