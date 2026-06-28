# Store Analysis Data Warehouse and BI Dashboard

## Project Overview

This project is an end-to-end business intelligence and data warehousing project built around a retail sales analysis scenario. The goal was to design, build, validate, and visualize a Snowflake-based data warehouse that supports business decisions around store performance, profitability, sales targets, bonus allocation, product sales trends, and market expansion.

The analysis focuses on **Store 10** and **Store 21**. I built the full pipeline from source data ingestion to staging tables, dimension tables, fact tables, secure SQL views, and a final Tableau dashboard.


**Tableau Public Dashboard: [View the live dashboard](https://public.tableau.com/views/IMT577_DW_Souporno_Ghosh_Dashboard_Story/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)**

---

## Business Scenario

The company manufactures and sells products through multiple sales channels, including physical stores, online sales, direct customers, and resellers. Products are grouped into product categories and product types. Each product has a retail price, wholesale price, and production cost.

The business goal was to analyze historical sales data and recommend ways to improve sales profit. My assigned analysis area was **Stores 10 and 21**.

The project answers four main business questions:

1. How are Stores 10 and 21 performing compared to their sales targets?
2. Should either store be closed or restructured?
3. How should a $2,000,000 bonus pool be allocated based on 2013 sales target achievement?
4. What can product sales by day of week reveal about sales trends?
5. Should new stores be opened, and if so, where?

---

## Core Metrics

The warehouse and dashboard were designed around the following metrics:

| Metric | Definition |
|---|---|
| Sales Amount | Quantity × Price |
| Sales Quantity | Number of units sold |
| Sales Profit | (Quantity × Price) - (Quantity × Cost) |
| Product Profit Margin % | (Price - Cost) ÷ Price |
| Actual-to-Target Comparison | Actual sales compared with target sales |

A key business rule was that product price depends on the selling context. Products sold directly to customers use retail price, while products sold to resellers use wholesale price.

---

## What Is Dimensional Modeling?

Dimensional modeling is a data warehouse design approach used to organize data for business analysis and reporting. It separates data into two main types of tables:

- **Fact tables**, which store measurable business events such as sales, quantity, profit, and targets.
- **Dimension tables**, which provide descriptive context such as date, product, store, customer, channel, and reseller.

This structure makes it easier to write analytical queries, build dashboards, and answer business questions.

For this project, I designed the model as a **star schema / fact constellation schema**. A star schema connects fact tables to surrounding dimensions. A fact constellation, also called a galaxy schema, includes multiple fact tables that share common dimensions.

<img width="979" height="699" alt="image" src="https://github.com/user-attachments/assets/f2df233a-0a81-41bb-a09c-2a017073e78f" />


---

## Data Warehouse Architecture

The project followed this pipeline:

```text
Source CSV Files
        ↓
Snowflake Staging Tables
        ↓
Dimension Tables
        ↓
Fact Tables
        ↓
Secure SQL Views
        ↓
Tableau Dashboard and Story
```


The warehouse includes two central fact tables and multiple shared dimensions.

---

## Fact Tables

### FACT_SALES

`FACT_SALES` captures detailed sales transactions.

**Grain:** One row per sales transaction line item.

This fact table supports analysis of:

* Store-level sales
* Product sales
* Sales quantity
* Gross profit
* Product category performance
* Day-of-week sales trends
* Store profitability

Key measures include:

* Quantity sold
* Unit price
* Total sales amount
* Unit cost
* Gross profit


---

### FACT_DAILY_TARGETS

`FACT_DAILY_TARGETS` stores target data converted from annual targets into daily targets.

**Grain:** One row per daily target for each applicable business entity.

The source target data was annual, but daily targets were more useful for flexible reporting. Converting targets to daily grain made it possible to compare actual sales and target sales across different time periods.

This fact table supports:

* Actual-to-target comparison
* Store target analysis
* Product target analysis
* Channel and reseller target analysis
* Bonus allocation calculations


---

## Dimension Tables

The warehouse includes the following dimensions:

| Dimension        | Purpose                                                                                         |
| ---------------- | ----------------------------------------------------------------------------------------------- |
| DIM_DATE         | Supports date, year, month, quarter, day-of-week, weekend, and time-series analysis             |
| DIM_PRODUCT      | Stores product details, product type, product category, retail price, wholesale price, and cost |
| DIM_STORE        | Stores physical store information and location attributes                                       |
| DIM_CUSTOMER     | Stores direct customer information                                                              |
| DIM_CHANNEL      | Stores channel and channel category information                                                 |
| DIM_RESELLER     | Stores reseller information and reseller type                                                   |
| DIM_SALES_HEADER | Preserves sales header information for lineage and transaction context                          |


---

## Why I Used This Schema Design

I used a star schema / fact constellation design because it supports both analytical performance and business usability.

### 1. Separate Sales and Target Fact Tables

Sales data and target data have different grains. Sales are transactional, while targets are planned benchmarks. Keeping them in separate fact tables avoids grain mismatch and makes actual-to-target reporting cleaner.

### 2. Shared Conformed Dimensions

The fact tables share dimensions such as date, product, store, channel, and reseller. This allows consistent filtering across sales and target data.

### 3. Surrogate Keys

Dimension tables use surrogate keys as primary keys. These warehouse-generated keys are more stable than source system keys and support future changes such as slowly changing dimensions.

### 4. Unknown Members

Dimension tables include unknown members so that fact table foreign keys do not remain NULL. This protects referential integrity when source data is missing or incomplete.

### 5. Secure Views

I created secure SQL views to act as the data access layer between Snowflake and Tableau. This prevents Tableau from querying base tables directly and supports cleaner business-ready calculations.

---

## Step 1: Data Ingestion and Staging

The first step was to create staging tables in Snowflake and load the raw CSV files from Azure Blob Storage.

The staging database followed this naming pattern:

```sql
IMT577_DW_SOUPORNO_GHOSH_STAGING
```

The staging tables followed this pattern:

```sql
STAGING_<CSVFILENAME>
```

Examples include:

```sql
STAGING_CHANNEL
STAGING_CHANNELCATEGORY
STAGING_CUSTOMER
STAGING_PRODUCT
STAGING_PRODUCTCATEGORY
STAGING_PRODUCTTYPE
STAGING_RESELLER
STAGING_SALESDETAIL
STAGING_SALESHEADER
STAGING_STORE
STAGING_TARGETDATACHANNEL
STAGING_TARGETDATAPRODUCT
```

The staging layer preserved the source data structure before transformation into a dimensional model.


---

## Step 2: Dimension Table Creation and Loading

After loading the staging tables, I created the dimension tables.

This step included:

* Creating dimension tables with surrogate primary keys.
* Loading data from staging tables.
* Joining staging tables where needed.
* Transforming source data into warehouse-ready attributes.
* Adding unknown members.
* Validating that dimensions aligned with the required model structure.

Examples of dimension work:

* `DIM_DATE` supports year, month, quarter, day-of-week, and time filtering.
* `DIM_PRODUCT` combines product, product type, and product category information.
* `DIM_STORE` supports store-level and geographic analysis.
* `DIM_CHANNEL` supports direct and indirect channel analysis.
* `DIM_RESELLER` supports reseller and expansion analysis.


---

## Step 3: Fact Table Creation and Loading

After creating the dimensions, I created and loaded the fact tables.

This step included:

* Creating fact table structures.
* Joining staging data to dimension tables.
* Mapping natural keys to surrogate keys.
* Calculating sales amount, quantity, cost, profit, and targets.
* Ensuring fact table foreign keys did not contain NULL values.
* Mapping missing dimensional relationships to unknown members.

Main fact tables:

```sql
FACT_SALES
FACT_DAILY_TARGETS
```


---

## Step 4: Secure SQL Views

The final warehouse layer used secure SQL views.

The project required two categories of views:

### Pass-Through Views

These views exposed dimension and fact tables without using `SELECT *`. They create a basic data access layer and protect downstream reporting from direct table dependency.

Examples:

```sql
VW_DIM_DATE
VW_DIM_PRODUCT
VW_DIM_STORE
VW_DIM_CUSTOMER
VW_DIM_CHANNEL
VW_DIM_RESELLER
VW_FACT_SALES
VW_FACT_DAILY_TARGETS
```

### Custom Analytical Views

Custom views were created to support Tableau dashboard requirements. These views handled joins, filters, grouping, and calculations that were better managed in SQL.

The custom views supported:

* Store sales vs. targets
* Store profitability
* Bonus allocation
* Product category sales by day of week
* Weekly sales trends
* Market expansion opportunities


---

## Data Quality Issue and Resolution

During validation, I discovered a critical issue in the data pipeline.

### Issue

Some downstream views were not reflecting 2014 data correctly. In addition, 2013 dates were appearing incorrectly, and date distributions in the fact tables were inconsistent with expected results.

### Root Cause Analysis

I traced the issue through the pipeline:

1. I first reviewed the Tableau views and SQL views because the issue appeared in final reporting.
2. I then checked the fact table insert logic to see whether date parsing was incorrect.
3. I verified that `DIM_DATE` was populated correctly.
4. I found the root cause in the staging layer.

The issue came from `STAGING_SALESHEADER`. When the source `Date` column was defined as a `DATE` type, Snowflake auto-converted date strings such as:

```text
1/4/13
```

into:

```text
0013-01-04
```

instead of:

```text
2013-01-04
```

### Resolution

To fix the problem, I:

* Updated the `STAGING_SALESHEADER` table to correct the date format issue.
* Revised the date parsing logic in the fact table insert statements.
* Recreated the affected dimension and fact tables.
* Rebuilt the SQL views.
* Validated that the corrected views reflected accurate 2013 and 2014 date ranges and metrics.

This debugging process was important because it showed that the data warehouse was not just built, but also validated and corrected through root cause analysis.

---

## Tableau Dashboard

The final visualization was built in Tableau Public using SQL views from Snowflake.

The dashboard includes:

* Overall sales assessment for Stores 10 and 21
* Actual store profits
* Bonus distribution based on 2013 target achievement
* Product sales and category performance by day of week
* Weekly sales trends by store and year
* Market expansion opportunity map
* Global filters for store number and year
* Interactive click/filter behavior


→ **[View the live dashboard on Tableau Public](https://public.tableau.com/views/IMT577_DW_Souporno_Ghosh_Dashboard_Story/Dashboard1?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)**

<img width="750" height="601" alt="image" src="https://github.com/user-attachments/assets/fbde035a-8b6e-4a84-b07b-e2c8ce655585" />


---

## Key Findings

## 1. Overall Sales Performance

Store 10 performed better than Store 21 overall.

| Store    | Year | Actual Sales | Target Sales | Target Achievement |
| -------- | ---: | -----------: | -----------: | -----------------: |
| Store 10 | 2013 |  $47,916,947 |  $46,932,000 |              ~102% |
| Store 10 | 2014 |  $44,225,655 |  $54,250,500 |               ~81% |
| Store 21 | 2013 |  $32,546,862 |  $41,528,000 |             ~81.5% |
| Store 21 | 2014 |  $31,256,024 |  $41,000,500 |               ~76% |

Store 10 exceeded its 2013 target but declined in 2014. Store 21 underperformed in both years.

<img width="631" height="359" alt="image" src="https://github.com/user-attachments/assets/cf11317c-009f-457f-8784-3b9459f1e5b6" />


---

## 2. Profitability Analysis

Store 10 was more profitable than Store 21 in both years.

| Store    | 2013 Profit | 2014 Profit |
| -------- | ----------: | ----------: |
| Store 10 |      $31.4M |      $28.9M |
| Store 21 |      $21.1M |      $20.2M |

Store 21 had lower profitability and a declining profit trend, raising concerns about long-term sustainability.

<img width="288" height="388" alt="image" src="https://github.com/user-attachments/assets/5263f56b-9cf2-4e69-b7e0-d33ab7b4d8b7" />


---

## 3. Store Closure or Restructuring Recommendation

Store 21 missed both sales and profit expectations across the analysis period. Based on this pattern, Store 21 should be considered for restructuring, operational review, inventory optimization, or potential closure.

Store 10, despite its 2014 decline, showed stronger long-term return potential. It should receive further investment in targeted promotions, staffing alignment, category expansion, and high-margin product lines.

<img width="786" height="374" alt="image" src="https://github.com/user-attachments/assets/17ed1637-878d-444b-b241-a559f7674492" />


---

## 4. Bonus Distribution

The 2013 bonus pool was allocated based on target achievement ratio.

Total bonus pool:

```text
$2,000,000
```

| Store    | 2013 Target Achievement | Recommended Bonus |
| -------- | ----------------------: | ----------------: |
| Store 10 |                 102.09% |        $1,085,781 |
| Store 21 |                  81.52% |          $914,219 |

This method creates a transparent and performance-based bonus allocation.

<img width="623" height="281" alt="image" src="https://github.com/user-attachments/assets/16a932af-0590-460d-a8e9-64d13a84f4d6" />


---

## 5. Day-of-Week Sales Trends

Store 10 showed stronger sales momentum, especially on Friday and Tuesday, with consistently high weekend performance.

Store 21 showed a flatter trend with no strong sales peaks.

This suggests that Store 10 can benefit from targeted weekday promotions, while Store 21 may require deeper investigation into product mix, local demand, staffing, and marketing effectiveness.

<img width="521" height="308" alt="image" src="https://github.com/user-attachments/assets/14895167-eca1-484a-8008-f1808deba8e7" />


---

## 6. Product Category Breakdown

The strongest product categories were:

1. Women's Apparel
2. Men's Apparel
3. Accessories

The dashboard also showed higher profit margins on certain high-performing days. This suggests an opportunity to push best-selling products on high-margin days and optimize Store 21's product mix.

<img width="1064" height="356" alt="image" src="https://github.com/user-attachments/assets/a82d0be6-0ace-448f-bfd8-0f28b58b8d7c" />


---

## 7. Store Expansion Opportunities

The expansion analysis used a scoring approach based on:

* Market size
* Profitability
* Competition
* Market validation

High-priority expansion candidates included:

| City         | State | Evidence               |
| ------------ | ----- | ---------------------- |
| Indianapolis | IN    | $782.4M reseller sales |
| Birmingham   | AL    | $77.8M online sales    |
| Meridian     | MS    | $106.5M reseller sales |

The strongest candidates were cities with no existing physical store presence but strong online or reseller sales. This suggests validated demand without current physical coverage.

<img width="402" height="225" alt="image" src="https://github.com/user-attachments/assets/cc7e5360-48c6-40b2-91d4-32dafcd660ea" />


---

## Final Recommendations

Based on the analysis, I recommended the following:

1. Consider restructuring or closing Store 21 because of consistent underperformance.
2. Invest further in Store 10 because it shows stronger profitability and better long-term ROI.
3. Allocate bonuses based on actual target achievement to create a transparent incentive structure.
4. Use day-of-week and product-category trends to improve promotions, staffing, and inventory planning.
5. Open new stores in validated high-demand markets where reseller or online sales are strong and physical store presence is limited.
6. Continue using BI dashboards to monitor sales, profitability, targets, and expansion opportunities over time.

<img width="718" height="336" alt="image" src="https://github.com/user-attachments/assets/2732fc43-6a2c-4489-8438-b4df29edab62" />


---

## Tools and Technologies

| Tool               | Purpose                                                                |
| ------------------ | ---------------------------------------------------------------------- |
| Snowflake          | Cloud data warehouse                                                   |
| SQL                | Staging, transformation, dimensional modeling, fact loading, and views |
| Azure Blob Storage | Source file storage                                                    |
| Tableau Public     | Dashboard and story visualization                                      |
| GitHub             | Version control and portfolio hosting                                  |
| Draw.io            | Dimensional schema design                                              |

---

## Repository Structure

Current structure:

```text
store-analysis/
│
├── 01_staging_tables.sql
├── 02_dim_tables.sql
├── 03_fact_tables.sql
├── 04_views.sql
└── README.md
```

Recommended future structure:

```text
store-analysis/
│
├── README.md
├── sql/
│   ├── 01_staging_tables.sql
│   ├── 02_dim_tables.sql
│   ├── 03_fact_tables.sql
│   └── 04_views.sql
│
├── images/
│   ├── dimensional_model.png
│   ├── final_dashboard.png
│   ├── sales_performance.png
│   ├── profitability_analysis.png
│   ├── bonus_distribution.png
│   ├── daywise_sales_trends.png
│   ├── category_breakdown.png
│   └── market_expansion_map.png
│
└── docs/
    └── project_notes.md
```

---

## Skills Demonstrated

This project demonstrates:

* Data warehousing
* Dimensional modeling
* Star schema and fact constellation design
* SQL-based ETL/ELT development
* Snowflake database development
* Staging, dimension, fact, and view-layer implementation
* Surrogate key and unknown member handling
* Secure SQL view creation
* Data quality debugging and root cause analysis
* Business intelligence dashboard design
* Tableau visualization
* Store profitability analysis
* Sales target analysis
* Bonus allocation logic
* Market expansion analysis
* Translating warehouse outputs into business recommendations

---

## Project Outcome

The final project produced a complete BI system, starting from raw source files and ending in a Tableau dashboard. The warehouse structure enabled reliable analysis of store performance, sales targets, profitability, day-of-week product trends, bonus allocation, and market expansion opportunities.

The final recommendation was to treat Store 10 as the stronger investment candidate, reassess or restructure Store 21, allocate bonuses based on target achievement, and pursue new store expansion in markets with strong online or reseller demand.
