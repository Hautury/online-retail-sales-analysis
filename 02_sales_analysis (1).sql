-- 02_sales_analysis.sql
-- Online Retail project | SQLite / DBeaver
-- These queries use the tables from 01_data_cleaning.sql.
-- Money is in GBP. Positive sales exclude cancellations.

-- Q1. How did monthly gross sales change?
SELECT
    strftime('%Y-%m', InvoiceDate) AS month,
    ROUND(SUM(Revenue), 2) AS monthly_revenue
FROM retail_sales
GROUP BY month
ORDER BY month;

-- Insight: November 2011 was the strongest month at GBP 1,509,496.33.
-- February 2011 was the lowest complete month at GBP 523,631.89.
-- Recommendation: Compare complete months only. Both Decembers are partial months.

-- Q2. Which months had the highest month-over-month growth?
WITH monthly_sales AS (
    SELECT
        strftime('%Y-%m', InvoiceDate) AS month,
        SUM(Revenue) AS revenue
    FROM retail_sales
    GROUP BY month
),
sales_with_lag AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_month
    FROM monthly_sales
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_month, 2) AS previous_month,
    ROUND((revenue - previous_month) * 100.0 /
          NULLIF(previous_month, 0), 2) AS mom_growth_pct
FROM sales_with_lag
ORDER BY month;

-- Insight: Sales grew for three months in a row from September to November 2011.
-- September increased by 39.45%, and November increased by 30.69%.
-- Recommendation: Check product mix and promotions to understand the increase.
-- The December 2011 drop should not be treated as a full-month decline.

-- Q3. Which countries brought in the most revenue?
SELECT
    Country,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    COUNT(DISTINCT InvoiceNo) AS total_orders,
    ROUND(SUM(Revenue) * 100.0 /
          (SELECT SUM(Revenue) FROM retail_sales), 2) AS revenue_share_pct
FROM retail_sales
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 10;

-- Insight: The UK contributed about GBP 9.03 million, or 84.61% of gross sales.
-- The Netherlands (2.68%) and EIRE (2.66%) came next.
-- Recommendation: Keep tracking the UK market while exploring other markets.

-- Q4. Who were the highest-spending customers based on positive sales?
SELECT
    CustomerID,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    COUNT(DISTINCT InvoiceNo) AS total_orders
FROM retail_sales
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY total_revenue DESC
LIMIT 10;

-- Insight: Customer 14646 had GBP 280,206.02 in positive sales from 73 orders.
-- Customer 16446 had GBP 168,472.50 from just two orders.
-- Recommendation: Look at both order frequency and spending, not spending alone.
-- These figures do not yet include canceled purchases.

-- Q5. What percentage of identified customers bought more than once?
WITH customer_orders AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS order_count
    FROM retail_sales
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN order_count >= 2 THEN 1 ELSE 0 END) /
          NULLIF(COUNT(*), 0), 2) AS repeat_purchase_rate_pct
FROM customer_orders;

-- Insight: 2,845 of 4,338 identified customers made at least two orders (65.58%).
-- Recommendation: Study one-time buyers to see how a second purchase might be encouraged.
-- This is an observed repeat-purchase rate, not a time-based retention rate.

-- Q6. What do recency, frequency and monetary value tell us?
SELECT
    CustomerID,
    CAST(JULIANDAY((SELECT MAX(InvoiceDate) FROM retail_sales)) -
         JULIANDAY(MAX(InvoiceDate)) AS INTEGER) AS recency_days,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    ROUND(SUM(Revenue), 2) AS monetary
FROM retail_sales
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY monetary DESC
LIMIT 10;

-- Insight: Customer 14646 had 73 orders and purchased one day before the data ended.
-- Customer 14911 had 201 orders among these top-spending customers.
-- Customer 12346 looked valuable in gross sales but had been inactive for 325 days.
-- Recommendation: Check cancellations before deciding who the most valuable customers are.

-- Q6A. Why does customer 12346 appear to be a high-value customer?
SELECT
    InvoiceNo,
    InvoiceDate,
    Quantity,
    UnitPrice,
    ROUND(Quantity * UnitPrice, 2) AS line_amount
FROM retail_cleaned
WHERE CustomerID = 12346
ORDER BY InvoiceDate;

-- Insight: This customer placed a GBP 77,183.60 order and canceled it on the same day.
-- The two transactions cancel out, leaving a net value of GBP 0.
-- Recommendation: Use cancellation-adjusted values for customer monetary analysis.

-- Q6B. How large were the recorded cancellations?
SELECT
    COUNT(DISTINCT InvoiceNo) AS canceled_orders,
    COUNT(*) AS canceled_lines,
    ROUND(SUM(Quantity * UnitPrice), 2) AS cancellation_amount
FROM retail_cleaned
WHERE InvoiceNo LIKE 'C%'
  AND Quantity < 0
  AND UnitPrice > 0;

-- Insight: I found 3,836 cancellation invoices and 9,288 cancellation lines.
-- Their combined transaction value was GBP -896,812.49.
-- Recommendation: Show gross sales and cancellation values separately in reports.

-- Q6C. Are there negative-quantity transactions without the C prefix?
SELECT
    COUNT(*) AS negative_lines,
    ROUND(SUM(Quantity * UnitPrice), 2) AS negative_amount
FROM retail_cleaned
WHERE Quantity < 0
  AND InvoiceNo NOT LIKE 'C%'
  AND UnitPrice > 0;

-- Insight: This check returned zero matching rows.
-- Recommendation: Keep this validation in the workflow when importing new data.

-- Q7. Which customers have the highest cancellation-adjusted value?
WITH customer_transactions AS (
    SELECT
        CustomerID,
        ROUND(SUM(Quantity * UnitPrice), 2) AS net_transaction_value
    FROM retail_cleaned
    WHERE CustomerID IS NOT NULL
      AND UnitPrice > 0
    GROUP BY CustomerID
)
SELECT
    CustomerID,
    net_transaction_value
FROM customer_transactions
ORDER BY net_transaction_value DESC
LIMIT 10;

-- Insight: Customer 14646 ranked first at GBP 279,489.02, followed by 18102.
-- Customer 16446 dropped out of the top ten after cancellations were included.
-- Recommendation: Use adjusted value when comparing customers.
-- This is a transaction-based measure, not an audited accounting net-sales figure.

-- Q8. Group customers using simple RFM rules
-- Recency and frequency use positive orders; monetary includes cancellations.
-- These are custom rules, not standard RFM quintile scores.
DROP VIEW IF EXISTS customer_rfm;

CREATE VIEW customer_rfm AS
WITH customer_activity AS (
    SELECT
        CustomerID,
        CAST(JULIANDAY((SELECT MAX(InvoiceDate) FROM retail_sales)) -
             JULIANDAY(MAX(InvoiceDate)) AS INTEGER) AS recency_days,
        COUNT(DISTINCT InvoiceNo) AS frequency
    FROM retail_sales
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),
customer_monetary AS (
    SELECT
        CustomerID,
        ROUND(SUM(Quantity * UnitPrice), 2) AS monetary
    FROM retail_cleaned
    WHERE CustomerID IS NOT NULL
      AND UnitPrice > 0
    GROUP BY CustomerID
),
rfm AS (
    SELECT
        a.CustomerID,
        a.recency_days,
        a.frequency,
        COALESCE(m.monetary, 0) AS monetary
    FROM customer_activity a
    LEFT JOIN customer_monetary m ON a.CustomerID = m.CustomerID
)
SELECT
    CustomerID,
    recency_days,
    frequency,
    monetary,
    CASE
        WHEN monetary <= 0 THEN 'No Net Value'
        WHEN recency_days <= 30 AND frequency >= 5 AND monetary >= 1000
            THEN 'High Value Active'
        WHEN recency_days > 90 AND monetary >= 1000
            THEN 'High Value Inactive'
        WHEN frequency = 1 THEN 'One-Time Buyer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM rfm;

-- Insight: Customer 14646 is High Value Active under these rules.
-- Customer 16029 is a Regular Customer even with substantial spending,
-- because its last positive purchase was more than 30 days before the end date.
-- Recommendation: Test different cutoffs before using these groups for campaigns.

-- Q9. How much value comes from each customer segment?
SELECT
    customer_segment,
    COUNT(*) AS total_customers,
    ROUND(SUM(monetary), 2) AS total_net_value,
    ROUND(AVG(monetary), 2) AS avg_customer_value
FROM customer_rfm
GROUP BY customer_segment
ORDER BY total_net_value DESC;

-- Insight: High Value Active has 757 customers and about GBP 5.22 million
-- in adjusted transaction value (about 62.8% of the identified-customer total).
-- Regular Customer is the largest group, with 1,901 customers.
-- High Value Inactive has 219 customers.
-- Recommendation: Explore retention for active customers and reactivation for
-- inactive high-value customers. The segment thresholds are my starting assumptions.
