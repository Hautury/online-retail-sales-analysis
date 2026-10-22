# Online Retail Sales & Customer Analytics

**SQL (SQLite) | Power BI | Data Cleaning | Customer Segmentation | Business Intelligence**

An end-to-end retail analytics portfolio project using transactional data to investigate sales performance, customer purchasing behavior, geographic revenue concentration, and customer retention opportunities.

The project combines SQL-based data preparation and exploratory analysis with an interactive Power BI dashboard to translate transaction-level data into actionable business insights.

## 1. Project Overview

**Dataset:** UCI Online Retail Dataset  
**Period:** December 2010 – December 2011  
**Tools:** SQLite, DBeaver, Power BI Desktop  
**Focus:** Sales Analytics, Customer Behavior, RFM Segmentation

The dataset contains **541,909 transaction line items** from a UK-based online retailer.

The objective is to answer business questions such as:

- How does monthly sales revenue change over time?
- Which countries contribute the most revenue?
- Who are the highest-value customers?
- What percentage of customers make repeat purchases?
- How do cancellations affect customer value?
- How can RFM analysis support customer segmentation and retention strategies?

## 2. Project Workflow

**Raw Data → Data Cleaning → SQL Analysis → Customer Segmentation → Power BI Dashboard → Business Recommendations**

### Data Preparation

SQL was used to:

- Standardize data types and customer identifiers.
- Identify missing customer IDs.
- Separate positive sales from cancellations.
- Remove nonpositive quantities and prices from gross sales analysis.
- Calculate line-item revenue using `Quantity * UnitPrice`.
- Create reusable tables for downstream analysis.

The cleaned positive-sales dataset contains **530,104 transaction line items**, representing approximately **£10.67 million in gross sales**.

Gross sales exclude cancellations and should not be interpreted as net revenue.

### SQL Analysis

The SQL analysis covers:

1. Monthly revenue trends.
2. Month-over-month revenue growth using `LAG()`.
3. Top countries by revenue.
4. Highest-value customers.
5. Customer repeat purchase rates.
6. RFM customer behavior analysis.
7. Cancellation and net transaction value analysis.
8. Rule-based customer segmentation.

SQL techniques include:

`CTEs` · `JOINs` · `GROUP BY` · `CASE WHEN` · `LAG()` · `COUNT(DISTINCT)` · `COALESCE()` · `NULLIF()` · Date Functions

Each analysis includes documented business insights and recommendations.

## 3. Key Business Insights

### Sales Performance

**November 2011 was the strongest sales month**, generating approximately **£1.51 million** in positive sales.

September and November recorded month-over-month revenue growth of **39.45%** and **30.69%**, respectively.

Sales increased across September, October, and November, suggesting a period worth investigating for seasonal demand, product mix, or promotional effects.

**Recommendation:** Investigate the drivers of late-year sales growth and use comparable full-month periods when evaluating performance.

### Geographic Revenue Concentration

The **United Kingdom contributed approximately 84.61%** of gross sales, equivalent to roughly **£9.03 million**.

The Netherlands and EIRE were the next largest markets, contributing approximately 2.68% and 2.66%, respectively.

This indicates substantial geographic revenue concentration.

**Recommendation:** Maintain a strong focus on the UK market while evaluating growth opportunities in other established markets.

### Customer Retention

Among **4,338 identified customers**, **2,845 placed at least two distinct orders**.

The observed repeat purchase rate was **65.58%**.

This suggests that repeat customers represent a substantial share of the identified customer base.

**Recommendation:** Explore second-purchase campaigns for one-time buyers and analyze customer cohorts to better understand retention over time.

### Cancellation Analysis

The dataset contains **3,836 distinct cancellation invoices**, representing approximately **£896,812.49 in negative transaction value**.

One customer initially appeared to have generated over £77,000 in positive sales, but the purchase was fully canceled.

This demonstrates how gross sales alone can misrepresent customer value.

**Recommendation:** Incorporate cancellations when assessing net customer contribution and distinguish gross sales from cancellation-adjusted transaction value.

### RFM Customer Segmentation

Customers were segmented using three behavioral dimensions:

- **Recency:** Days since the most recent positive purchase.
- **Frequency:** Number of distinct positive-sales orders.
- **Monetary:** Cancellation-adjusted transaction value.

The project uses transparent, rule-based customer segments rather than quintile-based RFM scores.

| Customer Segment | Business Interpretation |
|---|---|
| High Value Active | Recent, frequent, high-value customers |
| High Value Inactive | High-value customers with long periods of inactivity |
| Regular Customer | Customers not meeting the other segment rules |
| One-Time Buyer | Customers with one positive-sales order |
| No Net Value | Customers with nonpositive net transaction value |

The **High Value Active** segment contains **757 customers** and contributes approximately **£5.22 million** in net transaction value.

This represents approximately **62.8% of net transaction value across identified customers**.

**Recommendation:** Prioritize retention for high-value active customers, investigate reactivation opportunities for inactive high-value customers, and encourage second purchases among one-time buyers.

## 4. Power BI Dashboard

The Power BI dashboard presents sales and customer performance through six primary visualizations.

**Key Performance Indicators**
- Gross Sales
- Total Orders
- Average Order Value

**Sales Analysis**
- Monthly Sales Trend
- Top 10 Countries by Revenue

**Customer Analysis**
- Net Customer Value by Segment
- Customer Count by Segment

The dashboard supports visual exploration of revenue trends, geographic concentration, and customer segment performance.

### Dashboard Preview

_Add a screenshot here once the final dashboard image has been uploaded to the repository._

## 5. Repository Contents

| File | Description |
|---|---|
| `02_sales_analysis.sql` | SQL queries covering sales performance, cancellations, customer behavior, and RFM segmentation |
| `Retail_Sales_Customer_Analytics.pbit` | Power BI dashboard template |
| `README.md` | Project documentation, methodology, findings, and recommendations |

The data-cleaning SQL script and dashboard screenshot can be added as separate files.

## 6. Data Source and Reproducibility

**Source:** UCI Machine Learning Repository — Online Retail Dataset

https://archive.ics.uci.edu/dataset/352/online+retail

To reproduce the analysis:

1. Download the Online Retail dataset from UCI.
2. Import the dataset into SQLite.
3. Create the cleaned and positive-sales tables.
4. Run the SQL analysis queries.
5. Open the Power BI template and connect
