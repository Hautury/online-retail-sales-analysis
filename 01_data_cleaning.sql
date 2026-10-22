-- ============================================================================
-- 01_data_cleaning.sql
-- Project: Online Retail Sales & Customer Analytics
-- Database: SQLite (DBeaver)
-- Source table: Online_Retail_DBeaver (UCI Online Retail dataset)
-- Period: December 2010 - December 2011
-- Purpose: Validate raw transactions, normalize CustomerID, and create a
--          positive-sales fact table for downstream sales and RFM analysis.

-- ============================================================================
-- STEP 1. RAW DATA QUALITY CHECKS
-- Business question: How much raw data do we have, and which issues need
-- attention before calculating sales?
-- ============================================================================

SELECT COUNT(*) AS raw_line_items
FROM Online_Retail_DBeaver;
-- EXPECTED RESULT (original project import): 541,909 line items.

SELECT
    SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END) AS cancellation_lines,
    SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS non_positive_quantity_lines,
    SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS non_positive_price_lines,
    SUM(CASE WHEN CustomerID IS NULL
              OR TRIM(CAST(CustomerID AS TEXT)) = ''
             THEN 1 ELSE 0 END) AS missing_customer_id_lines
FROM Online_Retail_DBeaver;
-- DATA QUALITY NOTES:
-- * Cancellation, quantity, and price categories can overlap. Do NOT add
--   these counts together to estimate removed rows.
-- * The original import contained blank CustomerID values; these should be
--   normalized to SQL NULL before customer-level analysis.
-- * In the original project, 135,080 raw rows had missing CustomerID.

-- ============================================================================
-- STEP 2. STANDARDIZE FIELD TYPES AND MISSING CUSTOMER IDS
-- Business question: Can customer identifiers be made consistent without
-- losing transaction rows?
-- ============================================================================

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

-- DATA CLEANING DECISIONS:
-- * InvoiceNo is text because cancellations use a leading 'C'.
-- * Empty/whitespace-only CustomerID values become NULL.
-- * CustomerID is converted to INTEGER for consistent customer grouping.
-- * All original line items are retained in retail_cleaned for traceability.

SELECT
    COUNT(*) AS cleaned_line_items,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS missing_customer_id_lines
FROM retail_cleaned;
-- EXPECTED RESULT: 541,909 cleaned line items (same as source).

-- ============================================================================
-- STEP 3. CREATE THE POSITIVE-SALES ANALYSIS TABLE
-- Business question: Which transaction lines represent valid positive sales?
-- ============================================================================

DROP TABLE IF EXISTS retail_sales;

CREATE TABLE retail_sales AS
SELECT
    *,
    ROUND(Quantity * UnitPrice, 2) AS Revenue
FROM retail_cleaned
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%';

-- BUSINESS LOGIC:
-- * Keep only positive quantities and positive unit prices.
-- * Exclude invoices marked as cancellations (InvoiceNo starts with 'C').
-- * Revenue is calculated at LINE-ITEM level as Quantity * UnitPrice.
-- * Revenue here represents POSITIVE GROSS SALES, not net sales after refunds.
-- * Missing CustomerID does not invalidate a sale; retain these rows for
--   overall sales and country-level reporting.

-- ============================================================================
-- STEP 4. VERIFY THE OUTPUT
-- Business question: Does the sales table contain the expected volume and
-- value, and are invalid transaction lines excluded?
-- ============================================================================

SELECT
    COUNT(*) AS valid_sales_line_items,
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    ROUND(SUM(Revenue), 2) AS gross_sales,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS unidentified_sales_lines
FROM retail_sales;
-- EXPECTED (original project):
-- valid_sales_line_items = 530,104
-- gross_sales = 10,666,684.54 (GBP)
-- Order count and unidentified sales lines should be read from query output.

SELECT
    SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS invalid_quantity_lines,
    SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS invalid_price_lines,
    SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END) AS cancellation_lines
FROM retail_sales;
-- EXPECTED RESULT: all three counts = 0.

SELECT
    (SELECT COUNT(*) FROM retail_cleaned) AS cleaned_line_items,
    (SELECT COUNT(*) FROM retail_sales) AS valid_sales_line_items,
    (SELECT COUNT(*) FROM retail_cleaned)
      - (SELECT COUNT(*) FROM retail_sales) AS excluded_line_items;
-- EXPECTED RESULT: 541,909 - 530,104 = 11,805 excluded line items.

-- ============================================================================
-- STEP 5. OPTIONAL: VALIDATE CUSTOMER COVERAGE FOR FUTURE RFM ANALYSIS
-- Business question: How many identified customers can be analyzed?
-- ============================================================================

SELECT
    COUNT(DISTINCT CustomerID) AS identified_customers,
    COUNT(DISTINCT CASE WHEN CustomerID IS NOT NULL THEN InvoiceNo END)
        AS identified_customer_orders
FROM retail_sales
WHERE CustomerID IS NOT NULL;

-- BUSINESS INSIGHTS:
-- * Raw transaction lines are not the same as unique orders: one invoice can
--   contain multiple products, so order KPIs use COUNT(DISTINCT InvoiceNo).
-- * The positive-sales table supports monthly, country, and order analysis.
-- * RFM / customer segmentation should use only identified customers.
--
-- BUSINESS RECOMMENDATIONS:
-- * Use retail_sales for Gross Sales and Total Orders KPIs in Power BI.
-- * Filter CustomerID IS NOT NULL in customer-level queries and RFM views.
-- * Analyze cancellations/returns separately if net revenue is required.
-- * Preserve the raw source table for reproducibility and auditing.
-- ============================================================================
