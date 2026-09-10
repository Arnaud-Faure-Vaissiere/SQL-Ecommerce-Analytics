CREATE TABLE transactions(
    InvoiceNo TEXT,
    StockCode TEXT,
    Description TEXT,
    Quantity INTEGER,
    InvoiceDate TIMESTAMP,
	UnitPrice NUMERIC(10,2),
	CustomerID	TEXT,
	Country TEXT,
	IsCancellation BOOLEAN,
	Transaction_Type TEXT,
	Sales NUMERIC(10,2));