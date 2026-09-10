--Construction des premiers KPI 

-- nombre de clients: 4372 
SELECT COUNT(DISTINCT CustomerID) AS nb_clients 
FROM transactions; 

-- nombre de commandes distinctes: 25898 
SELECT COUNT(DISTINCT InvoiceNo) AS nb_commandes 
FROM transactions; 

-- nombre de produits distincts: 4070 
SELECT COUNT(DISTINCT StockCode) AS nb_produits 
FROM transactions; 

-- nombre de transactions par pays : UK largement devant 
SELECT Country, COUNT(*) AS nb_transactions 
FROM transactions
GROUP BY Country 
ORDER BY nb_transactions DESC; 

--Chiffre d'affaires uniquement des ventes ("Sales") : 10642110.80 sterling
SELECT SUM(Sales) AS total_sales 
FROM transactions 
WHERE Transaction_Type = 'Sale'; 

--Répartition du nombre de ventes, ajustement et d'annulation 
--Beaucoup plus de ventes(526052) contre 9251 annulation et 1336 ajustements divers 
SELECT Transaction_Type, COUNT(*) as nb_transactions 
FROM transactions 
GROUP BY Transaction_Type 
ORDER BY nb_transactions DESC; 

--KPI intéressant: combien dépense en moyenne un client par commande: 513.46 sterling 
-- AOV: average order value 
-- Distinct car on rappelle qu'une même commande peut avoir des objets différents 
SELECT SUM(Sales)/ COUNT(DISTINCT InvoiceNo) AS AOV 
FROM transactions WHERE Transaction_Type = 'Sale';

SELECT *
FROM transactions