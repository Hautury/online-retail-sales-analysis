# Online Retail Sales & Customer Analysis

**Portfolio project | SQL (SQLite) · Power BI (planned) · Business Analytics**

## Project overview
This project analyzes transaction-level data from the UK Online Retail dataset to identify revenue trends, geographic sales concentration, and customer purchasing behavior. The analysis uses SQLite in DBeaver and will be extended with a Power BI dashboard.

**Status:** In progress. Data cleaning and monthly sales analyses are complete. Customer, country, RFM and dashboard analyses are planned.

## Business questions
1. How does gross sales revenue change month to month?
2. Which months have the strongest month-over-month growth?
3. Which countries contribute the most revenue?
4. Who are the highest-value customers?
5. What percentage of identified customers make repeat purchases?
6. How can customers be segmented using RFM metrics?

## Dataset and methodology
Source: UCI Machine Learning Repository, *Online Retail* dataset. Original source contains **541,909 line items** with invoice, product, quantity, price, customer and country information.

Cleaning steps:
- Normalize blank `CustomerID` values to SQL `NULL`.
- Keep only positive `Quantity` and `UnitPrice`.
- Exclude cancellation invoice numbers starting with `C`.
- Calculate `Revenue = Quantity × UnitPrice` for retained line items.

**Important metric definition:** `Revenue` in this project is **positive gross sales** after excluding cancellation/return rows, **not net revenue after returns**. Some retained transactions lack a customer identifier; customer analyses must filter `CustomerID IS NOT NULL`.

| Validation metric | Result |
|---|---:|
| Raw line items | 541,909 |
| Retained sales line items | 530,104 |
| Positive gross sales | £10,666,684.54 |

## Verified findings
- **November 2011** had the highest monthly gross sales in the analyzed period: **£1,509,496.33**.
- **February 2011** had the lowest gross sales among full months: **£523,631.89**.
- Revenue increased in **September (+39.45%), October (+9.11%) and November (+30.69%)** compared with the immediately preceding month.
- **December 2010 and December 2011 are partial months**; avoid direct full-month comparisons, especially interpreting the December 2011 decline as a full-month business contraction.

### Business interpretation
The September–November increase warrants investigation of seasonal demand, product mix and order volume. A holiday effect is a **hypothesis**, not a proven cause from these monthly totals alone.

### Preliminary recommendations
- Investigate drivers of the September–November sales increases using order count, product categories and average order value before attributing the pattern to seasonality.
- Plan inventory and operational capacity around observed demand peaks, subject to validation with additional periods of data.
- Use only comparable full months for monthly performance reporting.

## Reproduce the SQL analysis
1. Download the original *Online Retail* workbook from the UCI repository: https://archive.ics.uci.edu/dataset/352/online+retail
2. Import it into a SQLite database in DBeaver as a table named `Online_Retail_DBeaver` with the original column names.
3. Execute [`sql/01_data_cleaning.sql`](sql/01_data_cleaning.sql).
4. Execute [`sql/02_sales_analysis.sql`](sql/02_sales_analysis.sql). The script includes completed queries and clearly labeled pending questions.
5. When complete, add the Power BI `.pbix` file and dashboard screenshots to `dashboard/` and `images/`.

> The raw dataset and local SQLite database are not included in this repository. The Power BI report is not yet complete.

## Repository structure
```text
online-retail-sales-analysis/
├── README.md
├── sql/
│   ├── 01_data_cleaning.sql
│   └── 02_sales_analysis.sql
├── dashboard/
│   └── README.md
├── images/
│   └── README.md
└── data/
    └── README.md
```

## Next steps
- Complete country ranking and calculate revenue concentration.
- Analyze customer value, repeat purchase behavior and RFM segmentation.
- Validate metric definitions and build an interactive Power BI dashboard.
- Replace planned sections with executed, verified findings and dashboard screenshots.

## Skills demonstrated
SQLite · SQL data cleaning · aggregation · CTEs · window functions (`LAG`) · month-over-month growth · business insights · data quality checks
