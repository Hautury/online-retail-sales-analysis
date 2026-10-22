-- 01_data_cleaning.sql
-- Online Retail project | SQLite
-- I use this script to check the original data and prepare it for analysis.
-- Raw data was imported from the UCI Online Retail dataset into Online_Retail_DBeaver.

-- 1. Check the original data
SELECT COUNT(*) AS raw_rows
FROM Online_Retail_DBeaver;
-- Result: 541,909 rows. Each row is a product line, not necessarily one order.

SELECT
    SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END) AS cancellation_lines,
    SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS nonpositive_quantity,
    SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS nonpositive_price,
    SUM(CASE WHEN CustomerID IS NULL OR TRIM(CAST(CustomerID AS TEXT)) = ''
             THEN 1 ELSE 0 END) AS missing_customer_ids
FROM Online_Retail_DBeaver;
-- I found 135,080 rows with missing customer IDs.
-- Some problem categories overlap, so their counts should not be added together.

-- 2. Make a cleaned copy
DROP TABLE IF EXISTS retail_cleaned;

CREATE TABLE retail_cleaned AS
SELECT
    CAST(InvoiceNo AS TEXT) AS InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CAST(NULLIF(TRIM(CAST(CustomerID AS TEXT)), '') AS INTEGER) AS CustomerID,
    Country
FROM Online_Retail_DBeaver;

-- InvoiceNo stays as text because canceled invoices start with C.
-- Blank CustomerID values are converted to NULL.
-- I keep all original rows here so I can still study cancellations later.

SELECT
    COUNT(*) AS cleaned_rows,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS missing_customer_ids
FROM retail_cleaned;
-- Check: the row count should still be 541,909.

-- 3. Create a table for positive sales
DROP TABLE IF EXISTS retail_sales;

CREATE TABLE retail_sales AS
SELECT
    *,
    ROUND(Quantity * UnitPrice, 2) AS Revenue
FROM retail_cleaned
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%';

-- I exclude cancellations and nonpositive quantities/prices for gross sales.
-- This is positive gross sales, NOT net revenue after cancellations.
-- Missing CustomerID rows are still useful for overall sales analysis.

-- 4. Check the final sales table
SELECT
    COUNT(*) AS sales_lines,
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    ROUND(SUM(Revenue), 2) AS gross_sales,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS missing_customer_ids
FROM retail_sales;
-- Results: 530,104 sales lines and GBP 10,666,684.54 in gross sales.

SELECT
    SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS bad_quantity,
    SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS bad_price,
    SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END) AS cancellations
FROM retail_sales;
-- All three values should be zero.

SELECT
    (SELECT COUNT(*) FROM retail_cleaned) AS original_rows,
    (SELECT COUNT(*) FROM retail_sales) AS sales_rows,
    (SELECT COUNT(*) FROM retail_cleaned) -
    (SELECT COUNT(*) FROM retail_sales) AS excluded_rows;
-- 11,805 lines are excluded from the positive-sales table.

-- 5. Check how many customers can be used in customer analysis
SELECT
    COUNT(DISTINCT CustomerID) AS identified_customers,
    COUNT(DISTINCT InvoiceNo) AS identified_orders
FROM retail_sales
WHERE CustomerID IS NOT NULL;

-- What I learned:
-- Counting rows is different from counting orders, so I use DISTINCT InvoiceNo.
-- Customer-level analysis needs CustomerID IS NOT NULL.
-- For customer value, I will also look at cancellations instead of only gross sales.
