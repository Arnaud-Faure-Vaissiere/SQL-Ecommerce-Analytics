SELECT COUNT(*) AS nombre_ligne
FROM transactions;

SELECT *
FROM transactions
LIMIT 2;

SELECT MIN(InvoiceDate) AS min_date, MAX(InvoiceDate) AS max_date
FROM transactions;
