Dataset:

The dataset used in this project is the Online Retail dataset from the UCI Machine Learning Repository.

The original dataset contains transactions from a UK-based online retailer between December 2010 and December 2011.

The cleaned CSV file is not included in this repository because of its file size.

Source:

UCI Machine Learning Repository:

https://uci-ics-mlr-prod.aws.uci.edu/dataset/352/online%2Bretail

Data preparation:

The dataset was explored and cleaned using Python and pandas.

The cleaning process included:

Removing 2 rows with negative unit prices
Identifying sales, cancellations and operational adjustments
Creating a Sales column (Quantity × UnitPrice)
Preserving missing CustomerID values
Preserving zero-price transactions
Creating transaction-type indicators

The cleaned dataset was then used for the PostgreSQL SQL analysis included in this repository.
