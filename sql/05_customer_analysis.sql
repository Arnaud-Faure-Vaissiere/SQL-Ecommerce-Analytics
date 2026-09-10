-- Première analyse des clients

--Le CA moyen par client est de 2452,6 £
SELECT SUM(Sales) / COUNT( DISTINCT CustomerId) AS CA_Moyen_Client
FROM transactions
WHERE Transaction_Type = 'Sale'
AND CustomerID IS NOT NULL;

--Le panier moyen d'achat est de 513 £
SELECT SUM(Sales) / COUNT(DISTINCT InvoiceNo) AS Panier_Moyen
FROM transactions
WHERE Transaction_Type = 'Sale';

-- Quels sont les clients avec les plus forts CA? TOP 10 entre 280 000 et 80 000 £
SELECT CustomerID, SUM(Sales) AS CA_Par_Client
FROM transactions
WHERE Transaction_Type = 'Sale' AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY CA_Par_Client DESC LIMIT 10;

-- Quels sont les clients qui achètent le plus ? 
-- Les 10 clients ayant acheté les plus grandes quantités représentent des volumes élevés, 
-- avec un maximum d'environ 197 000 unités

SELECT CustomerID, SUM(Quantity) AS Qte_Par_Client
FROM transactions
WHERE Transaction_Type = 'Sale' AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY Qte_Par_Client DESC LIMIT 10;

-- Quels sont les paniers moyens les plus forts ? Entre 84 000 et 4000 les top paniers moyens
-- Avec en général entre 1 et 3 commandes sauf pour un qui a 21 commandes.
SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS Nombre_Commandes,
    SUM(Sales) AS CA_Par_Client, SUM(Sales) / COUNT(DISTINCT InvoiceNo) AS Panier_Moyen
FROM transactions
WHERE Transaction_Type = 'Sale' AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY Panier_Moyen DESC LIMIT 10;

--  Comportement et fidélité des clients

-- Quels sont les clients qui passent le plus de commandes ?
-- Les plus actifs comptent plus de 200 commandes ; le 10e compte 60 commandes.
--Les clients les plus actifs passent un nombre de commandes très supérieur à la majorité

SELECT CustomerId , COUNT(DISTINCT InvoiceNo) AS nb_commandes
FROM transactions 
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY nb_commandes DESC LIMIT 10;

-- Quels clients achètent le plus de produits différents ?
-- Les clients avec le plus de produits sont à 1787 ; le 10e compte plus de 600 produits.
--Certains clients présentent une très grande diversité d'achat, avec plusieurs centaines 
-- voire plus d'un millier de références différentes.
SELECT CustomerId , COUNT(DISTINCT StockCode) AS nb_produits_distincts
FROM transactions 
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY nb_produits_distincts DESC LIMIT 10;

--Répartition des clients selon leur nombre de commandes:
-- 1494 clients avec une commande , ensuite ça décroit bien quand le nb de commandes augmentent
SELECT nb_commandes, COUNT(*) nb_clients
FROM (SELECT CustomerId , COUNT(DISTINCT InvoiceNo) AS nb_commandes
FROM transactions 
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL
GROUP BY CustomerID) AS ordre_client
GROUP BY nb_commandes
ORDER BY nb_commandes;

--On remarque qu'on a 337 clients avec plus de 10 commandes
-- Donc on a plus de clients à 1,2,3,4 commandes qu'a plus de 10 commandes!
--Une part importante des clients n'effectue qu'un nombre limité de commandes, 
-- tandis qu'une minorité de clients présente une fréquence d'achat très élevée.
SELECT CASE WHEN nb_commandes > 10 THEN '10+' ELSE nb_commandes::text
    END AS cat_commande, COUNT(*) AS nb_clients
FROM ( SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS nb_commandes
    FROM transactions
    WHERE Transaction_Type = 'Sale' AND CustomerID IS NOT NULL
    GROUP BY CustomerID ) AS ordre_client
GROUP BY CASE  WHEN nb_commandes > 10 THEN '10+' ELSE nb_commandes::text END
ORDER BY MIN(nb_commandes); 

-- Quels clients ont la plus grande quantité moyenne par commande?
-- Regardons seulement les clients avec au moins 4 commandes passées
-- On voit qu'on a des clients à plus de 3000, 2000  
-- et le 10e à 1794 quantité moyenne pour 28 commandes
SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS nb_commande,
SUM(Quantity)/COUNT(DISTINCT InvoiceNo) AS qte_par_commande
FROM transactions 
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING COUNT(DISTINCT InvoiceNo) > 3
ORDER BY qte_par_commande DESC LIMIT 10;

-- Annulation

-- Quels clients ont le plus de quantité annulée ?
-- Un client a plus de 80 995 de quantité annulée (c'est le PAPERCRAFT)
-- Un autre a plus de 74 000 (c'est le MEDIUM CERAMIC TOP STORAGE JAR)
-- Le reste du top 10 des clients a entre 1000 et 10 000 quantités annulées
SELECT CustomerID, SUM(-Quantity) AS qte_cancel_par_client, 
MAX(Description) AS description
FROM transactions
WHERE Transaction_Type = 'Cancellation' AND CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY qte_cancel_par_client DESC LIMIT 10;

-- Quels clients ont le plus fort taux d'annulation ?
-- On regarde les clients avec au moins 50 quantité achetée 
-- On remarque de nombreux clients avec des taux d'annulation très élevés
-- 50% représente déjà autant de quantités achetées que retournées
-- On a 4 clients avec plus de produits annulés que d'acheter
SELECT CustomerID, 
SUM(CASE WHEN Transaction_Type = 'Cancellation' THEN -Quantity ELSE 0 END) AS qte_cancel,
SUM(CASE WHEN Transaction_Type = 'Sale' THEN Quantity ELSE 0 END) AS qte_sale,
ROUND(
SUM(CASE WHEN Transaction_Type = 'Cancellation' THEN -Quantity ELSE 0 END)::numeric
/NULLIF(SUM(CASE WHEN Transaction_Type = 'Cancellation' THEN -Quantity ELSE 0 END)
 + SUM(CASE  WHEN Transaction_Type = 'Sale' THEN Quantity  ELSE 0 END), 0) 
 * 100,2) AS pct_cancel
FROM transactions
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
HAVING SUM(CASE WHEN Transaction_Type = 'Sale' THEN Quantity ELSE 0 END) > 50
ORDER BY pct_cancel DESC LIMIT 10;

-- Segmentation

-- Objectif : Classer chaque client selon : 1. son chiffre d'affaires 2. sa fréquence d'achat 
-- Nous utilisons la médiane comme seuil. 
-- Si le CA est supérieur ou égal à la médiane -- => CA élevé 
-- Si le nombre de commandes est supérieur ou égal à la médiane => fréquence d'achat élevée
DROP VIEW IF EXISTS customer_segmentation;
CREATE VIEW customer_segmentation AS
-- ÉTAPE 1 : calculer les statistiques de chaque client 
WITH 
customer_stats AS 
(SELECT CustomerID, SUM(Sales) AS CA_client, COUNT(DISTINCT InvoiceNo) AS nb_commandes
FROM transactions
WHERE Transaction_Type = 'Sale'
AND CustomerID IS NOT NULL
GROUP BY CustomerID), 

-- ÉTAPE 2 : calculer les seuils médians
-- Pour le nombre de commandes le seuil de la médiane est à 2
-- Donc on utilise plutôt le seuil jusqu'au troisième quantile
seuils AS ( SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CA_client) AS seuil_ca,
            PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY nb_commandes) AS seuil_commandes
			FROM customer_stats )

-- Étape 3: comparer chaque client aux seuils
SELECT customer_stats.CustomerID, customer_stats.nb_commandes, 
        customer_stats.ca_client, seuils.seuil_commandes, seuils.seuil_ca,
CASE 
WHEN customer_stats.ca_client>=seuils.seuil_ca
AND customer_stats.nb_commandes>=seuils.seuil_commandes THEN 'Client VIP'
WHEN customer_stats.ca_client>=seuils.seuil_ca
AND customer_stats.nb_commandes<seuils.seuil_commandes THEN 'Gros clients occasionnels' 
WHEN customer_stats.ca_client<seuils.seuil_ca
AND customer_stats.nb_commandes>=seuils.seuil_commandes THEN 'Client fidèle'
ELSE 'Clients occasionnels'	END AS Category
FROM customer_stats
CROSS JOIN seuils;

SELECT *
FROM customer_segmentation
LIMIT 10;

-- Répartition des clients par catégorie
--on remarque environ 50% de clients occasionnels (2145)
-- 25% de clients (1091 clients VIP) ont plus de 668,56 £ dépensés avec au moins 5 commandes
-- 25% des clients (1079 gros clients occasionnels) ont plus de 668,56 £ dépensés en moins de 5 commandes
-- Très peu de clients fidèles (logique car compliqué de faire moins que le seuil pris) avec plus de 5 commandes
SELECT category, count(*) as client_par_cat
FROM customer_segmentation
GROUP BY category;

--Quelle part du chiffre d'affaires est générée par les 10 %,20 % des meilleurs clients ?
-- 61,45% du CA par le top 10% des clients
-- 74,68% du CA par le top 20% des clients
WITH customer_seg AS 
(SELECT CustomerID, SUM(Sales) AS ca_client
FROM transactions
WHERE Transaction_Type = 'Sale'
AND CustomerID IS NOT NULL
GROUP BY CustomerID),
      seuil AS 
(SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY ca_client) AS seuil_top10,
       PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY ca_client) AS seuil_top20
  FROM customer_seg), 
       category AS     
(SELECT customer_seg.CustomerID, customer_seg.ca_client,
CASE 
WHEN customer_seg.ca_client>=seuil.seuil_top10 THEN  'TOP10%' 
WHEN customer_seg.ca_client>=seuil.seuil_top20 THEN  'TOP20%' 
ELSE 'Autres' END AS category
FROM customer_seg
CROSS JOIN seuil),
       ca_category AS 
(SELECT category, SUM (ca_client) AS ca_cat
 FROM category
 GROUP BY category),
       ca_total AS 
(SELECT SUM(ca_client) AS ca_tot
FROM customer_seg)
SELECT ca_category.ca_cat,
       ca_category.category,
ROUND(ca_cat / ca_total.ca_tot*100,2) AS pct_total
FROM ca_category
CROSS JOIN ca_total
ORDER BY CASE WHEN ca_category.category = 'TOP10%' THEN 1 
WHEN ca_category.category = 'TOP20%' THEN 2 ELSE 3 END;


