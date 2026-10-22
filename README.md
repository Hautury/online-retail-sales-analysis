# Online Retail Sales & Customer Analytics

**SQL (SQLite) · Power BI · Data Cleaning · Customer Analysis**

I built this project to practice working with real transaction data and answering business questions using SQL and Power BI. I wanted to look at more than just total sales, so I also explored customer purchasing behavior, cancellations, and simple RFM customer segments.

## Project overview

- **Dataset:** [UCI Online Retail](https://archive.ics.uci.edu/dataset/352/online+retail)
- **Period:** December 2010 to December 2011
- **Tools:** SQLite, DBeaver, Power BI Desktop
- **Original data:** 541,909 transaction line items

The main questions I tried to answer were: When were sales strongest? Which countries and customers contributed the most? How many customers bought more than once? And how do canceled orders change the picture?

## What I did

### 1. Cleaned the data

I imported the dataset into SQLite and used `01_data_cleaning.sql` to check missing customer IDs, canceled invoices, quantities, and prices. I kept a cleaned copy of all transactions and created a separate table for positive sales.

The positive-sales table has **530,104 line items** and **£10,666,684.54 in gross sales**. These figures exclude cancellations, so I do not treat them as net revenue.

### 2. Analyzed sales and customers in SQL

In `02_sales_analysis.sql`, I used queries with `GROUP BY`, `COUNT(DISTINCT)`, CTEs, `CASE WHEN`, `LAG()`, and date functions to study monthly revenue, growth, countries, repeat purchases, and customer value.

One part I found especially interesting was customer **12346**. Looking only at positive sales, this customer seemed to have spent more than £77,000. After checking the original transactions, I found that the order had been fully canceled. This made me realize why customer value should not be calculated from gross sales alone.

I also created a `customer_rfm` view using recency, frequency, and cancellation-adjusted monetary value. The segments are based on rules I chose for this project, not standard RFM quintile scores.

### 3. Built a Power BI dashboard

I created a Power BI report with these visuals:

- Gross Sales, Total Orders, and Average Order Value
- Monthly Sales Trend
- Top 10 Countries by Revenue
- Net Customer Value by Segment
- Customer Count by Segment

The `.pbit` file is included as a Power BI template. Opening it may require configuring the source data on your computer.

## A few findings

| Question | What I found |
|---|---|
| Strongest sales month | November 2011, about **£1.51 million** in positive sales |
| Late-year sales | September and November grew **39.45%** and **30.69%** month over month |
| Largest market | The UK accounted for **84.61%** of gross sales |
| Repeat customers | **2,845 of 4,338** identified customers placed at least two orders (**65.58%**) |
| Cancellations | **3,836** cancellation invoices, totaling about **£896,812** in negative transaction value |
| High Value Active segment | **757 customers** with about **£5.22 million** in cancellation-adjusted transaction value |

December 2010 and December 2011 are incomplete months, so I avoid using them for direct full-month comparisons. The repeat-purchase percentage describes behavior within this dataset; it is not a cohort retention rate.

## Dashboard preview

![Power BI dashboard](Sales%20%26%20Customer%20Analytics.png)

## Files

| File | Purpose |
|---|---|
| `01_data_cleaning.sql` | Checks and prepares the retail data |
| `02_sales_analysis.sql` | SQL questions, results, and short business notes |
| `Retail_Sales_Customer_Analytics.pbit` | Power BI report template |
| `Sales & Customer Analytics.png` | Dashboard screenshot |
| `README.md` | Project explanation |

## How to reproduce the SQL work

1. Download the dataset from the [UCI repository](https://archive.ics.uci.edu/dataset/352/online+retail).
2. Import it into a SQLite database using DBeaver. Name the raw table `Online_Retail_DBeaver`.
3. Run `01_data_cleaning.sql` to create `retail_cleaned` and `retail_sales`.
4. Run `02_sales_analysis.sql` to reproduce the analysis and create the `customer_rfm` view.
5. Open the Power BI template and configure its data source if you want to explore the dashboard.

## What I learned

This project helped me practice SQL on a dataset with real cleaning issues. The biggest lesson was that **a metric can look correct in a query but still be misleading for a business question**. In particular, gross sales, canceled transactions, and customer value need to be treated differently.

I would like to improve this project further by testing different RFM thresholds and adding a more detailed analysis of customer retention over time.
