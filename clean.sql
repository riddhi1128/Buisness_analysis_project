CREATE TABLE raw_retail_sales (
    order_id VARCHAR(50),
    order_date DATE,
    customer_id VARCHAR(50),
    product_id VARCHAR(50),
    product_name VARCHAR(150),
    category VARCHAR(100),
    quantity INTEGER,
    unit_price NUMERIC(12,2),
    discount_pct NUMERIC(5,4),
    city VARCHAR(100),
    state VARCHAR(100),
    sales_channel VARCHAR(50),
    payment_method VARCHAR(50),
    order_status VARCHAR(50)
);

SELECT * 
FROM raw_retail_sales
LIMIT 10;

SELECT COUNT(*) AS total_rows
FROM raw_retail_sales;

/*
from here, we start to clean the data
*/

--finding duplicate data
SELECT order_id, COUNT(*) AS occurrences
FROM raw_retail_sales
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC;

--checking missing values
SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL) AS missing_order_id,
    COUNT(*) FILTER (WHERE order_date IS NULL) AS missing_order_date,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (WHERE discount_pct IS NULL) AS missing_discount
FROM raw_retail_sales;

--find invalid quantities and prices
SELECT *
FROM raw_retail_sales
WHERE quantity <= 0
   OR unit_price <= 0;

--check order statuses
SELECT order_status, COUNT(*) AS total
FROM raw_retail_sales
GROUP BY order_status
ORDER BY total DESC;

-- This displays the raw data
SELECT * FROM raw_retail_sales; 


-- Step 1: Create a cleaned table
DROP TABLE IF EXISTS cleaned_retail_sales;

CREATE TABLE cleaned_retail_sales AS
WITH standardized AS (
    SELECT DISTINCT
        TRIM(order_id) AS order_id,
        order_date,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        TRIM(product_id) AS product_id,
        INITCAP(TRIM(product_name)) AS product_name,
        INITCAP(TRIM(category)) AS category,
        quantity,
        unit_price,
        COALESCE(discount_pct, 0) AS discount_pct,
        INITCAP(TRIM(city)) AS city,
        INITCAP(TRIM(state)) AS state,
        INITCAP(TRIM(sales_channel)) AS sales_channel,
        INITCAP(TRIM(payment_method)) AS payment_method,
        INITCAP(TRIM(order_status)) AS order_status
    FROM raw_retail_sales
),
valid_rows AS (
    SELECT *
    FROM standardized
    WHERE order_id IS NOT NULL
      AND order_id <> ''
      AND order_date IS NOT NULL
      AND product_id IS NOT NULL
      AND product_id <> ''
      AND quantity > 0
      AND unit_price > 0
      AND discount_pct BETWEEN 0 AND 1
)
SELECT
    *,
    quantity * unit_price AS gross_sales,
    quantity * unit_price * (1 - discount_pct) AS net_sales,
    DATE_TRUNC('month', order_date)::DATE AS order_month
FROM valid_rows;

-- Count cleaned records
SELECT COUNT(*) AS cleaned_rows
FROM cleaned_retail_sales;

-- Check the raw table
SELECT COUNT(*) AS total_rows
FROM raw_retail_sales;

-- Remove the table if it already exists
DROP TABLE IF EXISTS cleaned_retail_sales;

-- Create the cleaned table
CREATE TABLE cleaned_retail_sales AS
WITH standardized AS (
    SELECT DISTINCT
        TRIM(order_id) AS order_id,
        order_date,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        TRIM(product_id) AS product_id,
        INITCAP(TRIM(product_name)) AS product_name,
        INITCAP(TRIM(category)) AS category,
        quantity,
        unit_price,
        COALESCE(discount_pct, 0) AS discount_pct,
        INITCAP(TRIM(city)) AS city,
        INITCAP(TRIM(state)) AS state,
        INITCAP(TRIM(sales_channel)) AS sales_channel,
        INITCAP(TRIM(payment_method)) AS payment_method,
        INITCAP(TRIM(order_status)) AS order_status
    FROM raw_retail_sales
),
valid_rows AS (
    SELECT *
    FROM standardized
    WHERE order_id IS NOT NULL
      AND order_id <> ''
      AND order_date IS NOT NULL
      AND product_id IS NOT NULL
      AND product_id <> ''
      AND quantity > 0
      AND unit_price > 0
      AND discount_pct BETWEEN 0 AND 1
)
SELECT
    *,
    quantity * unit_price AS gross_sales,
    quantity * unit_price * (1 - discount_pct) AS net_sales,
    DATE_TRUNC('month', order_date)::DATE AS order_month
FROM valid_rows;

-- Check for duplicate rows
SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT order_id, order_date, customer_id, product_id,
           product_name, category, quantity, unit_price,
           discount_pct, city, state, sales_channel,
           payment_method, order_status, gross_sales,
           net_sales, order_month
    FROM cleaned_retail_sales
    GROUP BY order_id, order_date, customer_id, product_id,
             product_name, category, quantity, unit_price,
             discount_pct, city, state, sales_channel,
             payment_method, order_status, gross_sales,
             net_sales, order_month
    HAVING COUNT(*) > 1
) AS duplicates;

-- Count cleaned records
SELECT COUNT(*) AS cleaned_rows
FROM cleaned_retail_sales;

-- Preview cleaned sales data
SELECT *
FROM cleaned_retail_sales
LIMIT 10;

-- 1. Overall sales summary
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(net_sales), 2) AS total_net_sales,
    ROUND(AVG(net_sales), 2) AS average_line_sales
FROM cleaned_retail_sales;

-- 2. Monthly sales performance
SELECT
    order_month,
    ROUND(SUM(net_sales), 2) AS monthly_sales
FROM cleaned_retail_sales
GROUP BY order_month
ORDER BY order_month;

-- 3. Category performance
SELECT
    category,
    ROUND(SUM(net_sales), 2) AS total_sales,
    SUM(quantity) AS units_sold
FROM cleaned_retail_sales
GROUP BY category
ORDER BY total_sales DESC;

-- 4. Top 10 products by net sales
SELECT
    product_name,
    ROUND(SUM(net_sales), 2) AS total_sales
FROM cleaned_retail_sales
GROUP BY product_name
ORDER BY total_sales DESC
LIMIT 10;

-- 5. City-wise sales
SELECT
    city,
    state,
    ROUND(SUM(net_sales), 2) AS total_sales
FROM cleaned_retail_sales
GROUP BY city, state
ORDER BY total_sales DESC;

-- 6. Orders by status
SELECT
    order_status,
    COUNT(*) AS total_records,
    ROUND(SUM(net_sales), 2) AS total_sales
FROM cleaned_retail_sales
GROUP BY order_status
ORDER BY total_records DESC;
