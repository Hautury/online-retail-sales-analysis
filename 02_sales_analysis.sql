-- Online Retail Sales Analysis | SQLite / DBeaver
-- Source: UCI Online Retail dataset (2010-12 to 2011-12)
-- Prerequisites: retail_cleaned and retail_sales tables created in the data-cleaning script.
-- Gross/positive sales exclude cancellations; net transaction value includes negative
-- cancellation lines where UnitPrice > 0. Monetary values are GBP.
-- The RFM segments are illustrative business-rule segments, not quintile RFM scores.
-- Execute statements in order. DROP VIEW refreshes any existing segmentation view.

-- ============================================================
-- Q1 | MONTHLY SALES ANALYSIS
-- ============================================================

SELECT

    strftime('%Y-%m', InvoiceDate) AS month,

    ROUND(SUM(Revenue), 2) AS monthly_revenue

FROM retail_sales

GROUP BY month

ORDER BY month;

-- BUSINESS INSIGHTS:
-- 1. November 2011 recorded the highest monthly positive sales (£1,509,496.33).
-- 2. February 2011 was the lowest complete month (£523,631.89).
-- 3. December 2010 and December 2011 are partial months and are not directly comparable.
-- BUSINESS RECOMMENDATIONS:
-- 1. Investigate drivers of the September-November sales increase.
-- 2. Exclude incomplete months when comparing full-month performance.

-- ============================================================
-- Q2 | MONTH-OVER-MONTH SALES GROWTH
-- ============================================================

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

    ROUND(

        (revenue - previous_month) * 100.0

        / NULLIF(previous_month, 0),

        2

    ) AS mom_growth_pct

FROM sales_with_lag

ORDER BY month;

-- BUSINESS INSIGHTS:
-- 1. September, October and November 2011 had consecutive positive month-over-month growth.
-- 2. September grew 39.45% and November grew 30.69% versus their preceding months.
-- 3. The December 2011 decline cannot be interpreted as a full-month decline.
-- BUSINESS RECOMMENDATIONS:
-- 1. Investigate promotions and product mix as possible drivers, not proven causes.
-- 2. Flag partial months in time-series reporting.

-- ============================================

-- Q3: Top 10 Countries by Revenue

-- ============================================

SELECT

    Country,

    ROUND(SUM(Revenue), 2) AS total_revenue,

    COUNT(DISTINCT InvoiceNo) AS total_orders,

    ROUND(

        SUM(Revenue) * 100.0 /

        (SELECT SUM(Revenue) FROM retail_sales),

        2

    ) AS revenue_share_pct

FROM retail_sales

GROUP BY Country

ORDER BY total_revenue DESC

LIMIT 10;


-- BUSINESS INSIGHTS:

-- 1. The United Kingdom generated £9.03 million in gross

--    sales, accounting for 84.61% of total revenue.

-- 2. The Netherlands and EIRE were the next largest

--    markets, contributing 2.68% and 2.66%, respectively.

-- 3. Revenue is highly concentrated in the UK market,

--    indicating significant geographic concentration risk.

-- BUSINESS RECOMMENDATIONS:

-- 1. Maintain a strong focus on the UK market because

--    it is the company's primary revenue contributor.

-- 2. Investigate growth opportunities in the Netherlands,

--    EIRE, Germany, and France to diversify revenue.

-- 3. Monitor revenue concentration across countries

--    to identify changes in geographic exposure.

-- ============================================

-- Q4: Top 10 Customers by Revenue

-- ============================================

SELECT

    CustomerID,

    ROUND(SUM(Revenue), 2) AS total_revenue,

    COUNT(DISTINCT InvoiceNo) AS total_orders

FROM retail_sales

WHERE CustomerID IS NOT NULL

GROUP BY CustomerID

ORDER BY total_revenue DESC

LIMIT 10;

-- BUSINESS INSIGHTS:

-- 1. Customer 14646 generated the highest gross sales

--    among identified customers, reaching £280,206.02

--    across 73 orders.

-- 2. Customer 16446 generated £168,472.50 from only

--    2 orders, indicating unusually high order values.

-- 3. Customer 14911 placed 201 orders, demonstrating

--    that high purchase frequency does not necessarily

--    correspond to the highest total spending.

-- BUSINESS RECOMMENDATIONS:

-- 1. Consider targeted retention strategies for

--    high-value customers to protect important revenue.

-- 2. Investigate unusually large orders to understand

--    whether they represent wholesale purchases.

-- 3. Segment customers by both purchase frequency

--    and monetary value instead of revenue alone.

-- ============================================

-- Q5: Customer Repeat Purchase Rate

-- ============================================

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

    SUM(

        CASE

            WHEN order_count >= 2 THEN 1

            ELSE 0

        END

    ) AS repeat_customers,

    ROUND(

        SUM(

            CASE

                WHEN order_count >= 2 THEN 1

                ELSE 0

            END

        ) * 100.0 / NULLIF(COUNT(*), 0),

        2

    ) AS repeat_purchase_rate_pct

FROM customer_orders;

-- BUSINESS INSIGHTS:

-- 1. Among 4,338 identified customers, 2,845 placed

--    at least two distinct orders during the study period.

-- 2. The repeat purchase rate was 65.58%, indicating

--    that repeat buyers represent a majority of

--    identified customers.

-- 3. The remaining 1,493 customers placed only one

--    order, representing 34.42% of identified customers.

-- BUSINESS RECOMMENDATIONS:

-- 1. Investigate opportunities to encourage first-time

--    customers to make a second purchase.

-- 2. Segment repeat customers by purchase frequency

--    and monetary value to identify valuable groups.

-- 3. Conduct cohort analysis to understand whether

--    customers continue purchasing over time.

-- ============================================

-- Q6: RFM Customer Analysis

-- ============================================

SELECT

    CustomerID,

    CAST(

        JULIANDAY(

            (SELECT MAX(InvoiceDate) FROM retail_sales)

        ) - JULIANDAY(MAX(InvoiceDate))

        AS INTEGER

    ) AS recency_days,

    COUNT(DISTINCT InvoiceNo) AS frequency,

    ROUND(SUM(Revenue), 2) AS monetary

FROM retail_sales

WHERE CustomerID IS NOT NULL

GROUP BY CustomerID

ORDER BY monetary DESC

LIMIT 10;

-- BUSINESS INSIGHTS:

-- 1. Customer 14646 generated the highest gross sales

--    (£280,206.02) across 73 orders, with a recency

--    of only 1 day.

-- 2. Customer 14911 placed 201 orders, showing the

--    highest purchase frequency among the top 10

--    customers ranked by monetary value.

-- 3. Customer 12346 generated £77,183.60 from one

--    order but had not purchased for 325 days

--    before the dataset's final transaction date.

-- 4. High monetary value does not always correspond

--    to high purchase frequency or recent activity.

-- BUSINESS RECOMMENDATIONS:

-- 1. Consider retention initiatives for customers

--    with high monetary value and high frequency.

-- 2. Investigate high-spending customers with long

--    periods of inactivity before designing

--    reactivation campaigns.

-- 3. Review returns and cancellations before

--    treating gross sales as net customer value.

-- ============================================

-- Q6A: Investigate Customer 12346

-- ============================================

SELECT

    InvoiceNo,

    InvoiceDate,

    Quantity,

    UnitPrice,

    ROUND(Quantity * UnitPrice, 2) AS line_amount

FROM retail_cleaned

WHERE CustomerID = 12346

ORDER BY InvoiceDate;

-- BUSINESS INSIGHTS:

-- 1. Customer 12346 placed an order worth £77,183.60,

--    which was fully canceled on the same day.

-- 2. The net transaction value of these two records

--    was £0.00.

-- 3. Excluding cancellations caused this customer

--    to appear as a high-value customer in the

--    gross sales RFM analysis.

-- BUSINESS RECOMMENDATIONS:

-- 1. Review cancellation transactions before

--    identifying high-value customers.

-- 2. Use net transaction value when assessing

--    customer monetary contribution.

-- 3. Distinguish gross sales from net sales

--    in reports and dashboards.

-- ============================================

-- Q6B: Cancellation Transaction Analysis

-- ============================================

SELECT

    COUNT(DISTINCT InvoiceNo) AS canceled_orders,

    COUNT(*) AS canceled_lines,

    ROUND(SUM(Quantity * UnitPrice), 2)

        AS cancellation_amount

FROM retail_cleaned

WHERE InvoiceNo LIKE 'C%'
  AND Quantity < 0
  AND UnitPrice > 0;

-- BUSINESS INSIGHTS:

-- 1. The dataset contains 3,836 distinct cancellation

--    invoices and 9,288 cancellation line items.

-- 2. Cancellation transactions represent a total

--    negative value of £896,812.49.

-- 3. Excluding cancellations from gross sales

--    may overstate customer monetary value.

-- BUSINESS RECOMMENDATIONS:

-- 1. Report positive sales and cancellations

--    separately to improve transparency.

-- 2. Investigate cancellation patterns by customer

--    and product before calculating net customer value.

-- 3. Validate all negative transactions before

--    finalizing net revenue metrics.

-- ============================================

-- Q6C: Negative Transactions Without C Prefix

-- ============================================

SELECT

    COUNT(*) AS negative_lines,

    ROUND(SUM(Quantity * UnitPrice), 2)

        AS negative_amount

FROM retail_cleaned

WHERE Quantity < 0
  AND InvoiceNo NOT LIKE 'C%'
  AND UnitPrice > 0;

-- BUSINESS INSIGHTS:

-- 1. No negative-quantity transactions with a

--    positive unit price were found outside

--    cancellation invoices.

-- 2. All negative-quantity transactions with

--    positive prices were associated with

--    invoice numbers starting with 'C'.

-- 3. This supports using the 'C' prefix to identify

--    cancellation transactions in this dataset.

-- BUSINESS RECOMMENDATIONS:

-- 1. Separate cancellation transactions from

--    positive sales in financial reporting.

-- 2. Include cancellation values when calculating

--    adjusted customer monetary value.

-- ============================================

-- Q7: Customer Net Transaction Value

-- ============================================

WITH customer_transactions AS (

    SELECT

        CustomerID,

        ROUND(SUM(Quantity * UnitPrice), 2)

            AS net_transaction_value

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

-- BUSINESS INSIGHTS:
-- 1. Customer 14646 led net transaction value at £279,489.02.
-- 2. Customer 18102 followed with £256,438.49.
-- 3. Customer 16446 ranked fourth by positive sales but fell outside
--    the top ten after cancellation amounts were included.
-- BUSINESS RECOMMENDATIONS:
-- 1. Use cancellation-adjusted transaction value to assess customer contribution.
-- 2. Investigate unusually large canceled orders before targeting customers.

-- ============================================

-- Q8: RFM Customer Segmentation

-- ============================================

DROP VIEW IF EXISTS customer_rfm;

CREATE VIEW customer_rfm AS

WITH customer_activity AS (

    SELECT

        CustomerID,

        CAST(

            JULIANDAY(

                (SELECT MAX(InvoiceDate) FROM retail_sales)

            ) - JULIANDAY(MAX(InvoiceDate))

            AS INTEGER

        ) AS recency_days,

        COUNT(DISTINCT InvoiceNo) AS frequency

    FROM retail_sales

    WHERE CustomerID IS NOT NULL

    GROUP BY CustomerID

),

customer_monetary AS (

    SELECT

        CustomerID,

        ROUND(SUM(Quantity * UnitPrice), 2)

            AS monetary

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

    LEFT JOIN customer_monetary m

        ON a.CustomerID = m.CustomerID

)

SELECT

    CustomerID,

    recency_days,

    frequency,

    monetary,

    CASE

        WHEN monetary <= 0 THEN 'No Net Value'
		WHEN recency_days <= 30
    	 AND frequency >= 5
     	AND monetary >= 1000
		THEN 'High Value Active'

        WHEN recency_days > 90

             AND monetary >= 1000

             THEN 'High Value Inactive'

        WHEN frequency = 1

             THEN 'One-Time Buyer'

        ELSE 'Regular Customer'

    END AS customer_segment

FROM rfm;

-- BUSINESS INSIGHTS:

-- 1. Customer 14646 was classified as High Value Active,

--    with £279,489.02 in net transaction value,

--    73 orders, and a recency of 1 day.

-- 2. Customer 14911 placed 201 orders and generated

--    £132,572.62 in net transaction value,

--    demonstrating high purchase frequency.

-- 3. Customer 16029 generated £50,992.61 across

--    63 orders but was classified as Regular Customer

--    because its recency exceeded 30 days.

-- 4. Rule-based segmentation is sensitive to

--    the selected recency and monetary thresholds.

-- BUSINESS RECOMMENDATIONS:

-- 1. Prioritize engagement with high-value,

--    recently active customers.

-- 2. Review customers with high monetary value

--    who fall outside the active segment.

-- 3. Validate segmentation thresholds against

--    the full customer distribution.

-- ============================================

-- Q9: Customer Segment Performance

-- ============================================

SELECT

    customer_segment,

    COUNT(*) AS total_customers,

    ROUND(SUM(monetary), 2) AS total_net_value,

    ROUND(AVG(monetary), 2) AS avg_customer_value

FROM customer_rfm

GROUP BY customer_segment

ORDER BY total_net_value DESC;

-- BUSINESS INSIGHTS:

-- 1. The High Value Active segment contains 757

--    customers, representing 17.45% of identified

--    customers.

-- 2. This segment generated £5,218,207.16 in net

--    transaction value, approximately 62.8% of

--    the total across identified customers.

-- 3. Regular Customers form the largest segment,

--    with 1,901 customers and £2,183,906.19

--    in net transaction value.

-- 4. The High Value Inactive segment contains

--    219 customers with a combined net transaction

--    value of £446,663.37.

-- BUSINESS RECOMMENDATIONS:

-- 1. Prioritize retention efforts for High Value

--    Active customers because of their substantial

--    contribution to net transaction value.

-- 2. Investigate reactivation opportunities among

--    High Value Inactive customers.

-- 3. Develop second-purchase campaigns for

--    One-Time Buyers and measure their effectiveness.

-- 4. Review segmentation thresholds periodically

--    to ensure customer groups remain meaningful.