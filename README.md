# SQL-Ecommerce-Analytics

## Project Overview

This project analyzes transactional data from an online retail company using **PostgreSQL** for data analysis and **Python** for exploratory analysis and visualization.
The objective is to transform raw transactional data into **business insights** about sales performance, customers, products, countries and time trends.

The project follows an end-to-end analytical workflow:

**Data exploration → Data cleaning → PostgreSQL → SQL analysis → Business KPIs**

## Business Questions

The analysis aims to answer several business questions:

### Sales performance

* What is the total revenue generated?
* How many orders were placed?
* What is the average order value?
* Which countries generate the most revenue?
* Which months perform best and worst?

### Product performance

* Which products generate the highest revenue?
* Which products have the highest sales volumes?
* Are the best-selling products also the most profitable in terms of revenue?
* Which products have significant cancellation volumes?

### Customer analysis

* How many customers can be identified?
* Which customers generate the most revenue?
* Which customers place the most orders?
* How concentrated is revenue among the top customers?
* Can customers be segmented according to revenue and purchase frequency?

### Country analysis

* Which markets generate the most revenue?
* Which countries have the largest customer bases?
* Which markets could represent development opportunities?
* Which countries have relatively high cancellation rates?

### Time analysis

* How does revenue evolve over time?
* Which months generate the highest revenue?
* How does the average order value change over time?
* How do cancellations evolve over time?
* How has revenue changed between the beginning and the end of the observed period?

## Dataset

The project uses the **Online Retail dataset** from the UCI Machine Learning Repository.

The dataset contains transactional records from a UK-based online retailer between **December 2010 and December 2011**.

The original dataset contains **541,909 transactions** and the following main variables:

| Column        | Description         |
| ------------- | ------------------- |
| `InvoiceNo`   | Invoice number      |
| `StockCode`   | Product code        |
| `Description` | Product description |
| `Quantity`    | Quantity purchased  |
| `InvoiceDate` | Transaction date    |
| `UnitPrice`   | Unit price          |
| `CustomerID`  | Customer identifier |
| `Country`     | Customer country    |

Source:

UCI Machine Learning Repository — Online Retail Dataset.

The cleaned dataset is not stored in this repository because of its file size.

## Data Cleaning

The data was explored and cleaned using **Python and pandas**.

The cleaning process included:

* Checking missing values
* Checking duplicated and inconsistent data
* Identifying cancelled transactions
* Identifying operational adjustments
* Removing 2 rows with negative unit prices
* Preserving missing `CustomerID` values
* Preserving missing product descriptions
* Preserving zero-price transactions
* Creating a `Sales` column:

`Sales = Quantity × UnitPrice`

A `Transaction_Type` column was also created to distinguish:

* `Sale`
* `Cancellation`
* `Adjustment`

The detailed exploration and cleaning process is available in:

`Carnet/01_Exploration_Nettoyage.ipynb`


## Tools & Technologies

* **Python**
* **pandas**
* **Jupyter Notebook**
* **PostgreSQL**
* **SQL**
* **GitHub**

## SQL Analysis

The SQL analysis is organized into several stages:

| File                       | Analysis                |
| -------------------------- | ----------------------- |
| `01_create_table.sql`      | Database table creation |
| `02_data_validation.sql`   | Data validation         |
| `03_basic_analysis.sql`    | Basic business metrics  |
| `04_sales_analysis.sql`    | Sales analysis          |
| `05_customer_analysis.sql` | Customer analysis       |
| `06_country_analysis.sql`  | Country analysis        |
| `07_time_analysis.sql`     | Time analysis           |
| `08_business_kpis.sql`     | Final business KPIs     |

This structure separates **technical preparation**, **exploratory analysis** and **business-oriented analysis**.

## Key Findings

The analysis highlights several important business insights.

### Overall performance

* Total sales revenue: approximately **£10.64M**
* Number of sales orders: approximately **20.7K**
* Average order value: approximately **£513**
* Identified buying customers: approximately **4.3K**
* Total quantity sold: approximately **5.65M units**

These indicators provide an overview of the company's sales activity during the observed period.

### Customer concentration

Revenue is relatively concentrated among the highest-value customers.

* The **top 10% of identified customers generate approximately 61.45%** of identified-customer revenue.
* The **top 20% cumulatively generate approximately 74.68%** of identified-customer revenue.

This indicates that a relatively small proportion of customers represents a significant share of the company's revenue.

Customer segmentation was also performed using revenue and purchase frequency, identifying four main groups:

* Occasional customers
* VIP customers
* High-value occasional customers
* High-frequency customers

The segmentation can help identify different customer profiles and potential commercial strategies.

### Geographic performance

The **United Kingdom is the dominant market**, representing approximately 85% of total revenue and around 90% of identified customers.

Other European markets such as the Netherlands, Germany and France also contribute significantly to revenue.

### Product performance

The products generating the highest revenue are not necessarily the products sold in the highest quantities.

This demonstrates the importance of analyzing both:

* Revenue
* Sales volume

rather than relying on a single performance indicator.

### Time evolution

Comparing the first three complete months of the dataset with the last three complete months shows an increase in revenue of approximately **82%**.

The comparison excludes December 2011 from the final period because the dataset only contains part of that month.

## Analytical Limitations

Several limitations should be considered when interpreting the results:

* The dataset covers approximately one year, so it is not sufficient to establish long-term seasonality.
* Some transactions do not have an identified `CustomerID`.
* Cancellation rate is calculated using cancelled units relative to sold and cancelled units. It should therefore not be interpreted directly as a customer return rate.
* Some countries have very few identified customers, so their average customer revenue can be strongly influenced by individual customers.
* The analysis identifies correlations and patterns but does not establish causal relationships.


## Project Structure

```text
SQL-Ecommerce-Analytics/
│
├── README.md
│
├── data/
│   └── README.md
│
├── notebooks/
│   └── 01_exploration_nettoyage.ipynb
│
└── sql/
    ├── 01_create_table.sql
    ├── 02_data_validation.sql
    ├── 03_basic_analysis.sql
    ├── 04_sales_analysis.sql
    ├── 05_product_analysis.sql
    ├── 06_customer_analysis.sql
    ├── 07_country_analysis.sql
    ├── 08_time_analysis.sql
    └── 09_business_kpis.sql
```
## Next Step

The next stage of the project is to build an interactive **Power BI dashboard** based on the cleaned dataset and SQL analysis.

The Power BI stage will focus on:

* Data transformation with Power Query
* Data modeling
* DAX measures
* KPI creation
* Interactive dashboards
* Business-oriented data visualization

The objective is to transform the SQL analysis into an interactive reporting solution for decision-making.

