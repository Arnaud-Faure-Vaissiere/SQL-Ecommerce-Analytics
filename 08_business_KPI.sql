-- KPI Analysis

-- KPI globaux

-- CA total
-- Le chiffre d'affaires total réalisé sur la période s'élève à £10,64 millions.
SELECT SUM(SALES) AS CA_total
FROM transactions
WHERE Transaction_Type='Sale';

-- Nombre de commandes
-- 20 726 commandes comportent au moins une ligne de vente sur la période.
SELECT COUNT(DISTINCT InvoiceNo) AS commandes_total
FROM transactions
WHERE Transaction_Type='Sale';

-- Panier Moyen
-- Le panier moyen est d'environ £513 par commande.
-- Le panier moyen est calculé comme suit : CA total / nombre de commandes
SELECT SUM(SALES)/COUNT(DISTINCT InvoiceNo) AS CA_commandes
FROM transactions
WHERE Transaction_Type='Sale';

-- Nombre de clients identifiés
-- 4 339 clients identifiés ont réalisé au moins un achat sur la période.
SELECT COUNT(DISTINCT CustomerID) AS nombre_clients
FROM transactions
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL;

-- CA moyen généré par client identifié
-- Le CA moyen généré par un client identifié est d'environ £2 048.
-- Ce KPI correspond au CA réalisé auprès des clients identifiés
-- rapporté au nombre de clients ayant réalisé au moins un achat.

SELECT SUM(SALES)/COUNT(DISTINCT CustomerID) AS CA_clients
FROM transactions
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL;

-- Quantité vendue
-- Environ 5,65 millions d'unités ont été vendues sur la période. 
SELECT SUM(Quantity) AS qte_total
FROM transactions
WHERE Transaction_Type='Sale';

-- Taux d'annulation en quantité
-- Les annulations représentent environ 4,65 % du volume total, 
-- selon l'indicateur : quantité annulée / (quantité annulée + quantité vendue).
--Cet indicateur mesure le poids des annulations en volume et ne correspond pas directement à un taux de retour de commandes.

SELECT ROUND (
SUM(CASE WHEN Transaction_Type='Cancellation' THEN ABS(Quantity) ELSE 0 END)::numeric
/ (SUM(CASE WHEN Transaction_Type='Cancellation' THEN ABS(Quantity) ELSE 0 END) +
 SUM(CASE WHEN Transaction_Type='Sale' THEN Quantity ELSE 0 END))
*100,2) AS pct_annulation_qte
FROM transactions;

-- KPI Clients

-- Concentration du CA
-- Le Top 10 % des clients génère 61,45 % du CA réalisé auprès des clients identifiés.
-- Le Top 20 % des clients génère 74,68 % de ce CA.
-- Le chiffre d'affaires est donc fortement concentré sur une minorité de clients.

SELECT SUM(CASE WHEN category= 'TOP10%' THEN pct_total ELSE 0 END) AS pct_top10,
SUM(CASE WHEN category IN ('TOP20%','TOP10%') THEN pct_totaL ELSE 0 END) AS pct_top20
FROM(
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
WHEN ca_category.category = 'TOP20%' THEN 2 ELSE 3 END) AS resultat;

-- Répartition des clients par segmentation
-- La segmentation montre environ : 2 145 clients occasionnels, 1 091 clients VIP
-- 1 079 gros clients occasionnels, 24 clients à forte fréquence d'achat
-- La clientèle est donc principalement composée de clients occasionnels, 
-- tandis qu'un groupe plus restreint de clients génère une part importante du chiffre d'affaires.

SELECT Category, COUNT(*)
FROM customer_segmentation AS client_category
GROUP BY Category;

-- KPI Géographique

-- Part du CA réalisée au Royaume-Uni
-- Le Royaume-Uni représente environ 84,59 % du CA total, contre 15,41 % pour l'ensemble des autres pays.
-- Le marché britannique constitue donc le principal moteur du chiffre d'affaires.

WITH Sale_country AS 
(SELECT Country, SUM(SALES) AS sale_country
FROM transactions
WHERE Transaction_Type='Sale'
GROUP BY Country),
      Somme_total AS 
(SELECT SUM(sale_country) AS somme
 FROM Sale_country)
SELECT SUM(CASE WHEN Sale_country.Country='United Kingdom' THEN Sale_country.sale_country 
ELSE 0 END) AS CA_UK,
ROUND(
SUM(CASE WHEN Sale_country.Country='United Kingdom' THEN Sale_country.sale_country 
ELSE 0 END) / MAX(Somme_total.somme) *100,2) AS pct_UK_sale,
ROUND(SUM(CASE WHEN Sale_country.Country <> 'United Kingdom' THEN Sale_country.sale_country 
ELSE 0 END)	/ MAX(Somme_total.somme) *100,2) AS pct_Others_Country_sale
FROM Sale_Country
CROSS JOIN Somme_total;

-- Part des clients identifiés situés au Royaume-Uni
-- Environ 90,2 % des clients identifiés sont situés au Royaume-Uni, soit environ 3 921 clients.
-- La clientèle est donc encore plus concentrée au Royaume-Uni que le chiffre d'affaires.

SELECT clients_UK, pct_Clients_UK, (100 - pct_Clients_UK) AS pct_Clients_others
FROM (WITH Country_Client AS
(SELECT Country, COUNT(DISTINCT CustomerID) AS nb_clients
FROM transactions
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL
GROUP BY Country),
      SOMME AS
(SELECT SUM(nb_clients) AS somme
FROM Country_Client)
SELECT SUM(CASE WHEN Country_Client.Country='United Kingdom' 
THEN Country_Client.nb_clients ELSE 0 END) AS clients_UK,
ROUND( SUM(CASE WHEN Country_Client.Country='United Kingdom' 
THEN Country_Client.nb_clients ELSE 0 END) / MAX(SOMME.somme) *100, 2) AS pct_Clients_UK
FROM Country_Client
CROSS JOIN SOMME);

-- CA moyen par client : Royaume-Uni vs autres pays
-- Le CA moyen par client est d'environ £1 858 au Royaume-Uni, 
-- contre environ £3 800 dans les autres pays.
-- Le Royaume-Uni tire principalement son CA de la taille de sa base de clients, 
---tandis que certains marchés internationaux présentent un CA moyen par client beaucoup plus élevé.
-- Ces résultats doivent toutefois être interprétés avec prudence, car certains pays disposent d'un nombre très faible de clients.

SELECT ROUND( SUM(CASE WHEN Country = 'United Kingdom' THEN Sales ELSE 0 END)
       / COUNT(DISTINCT CASE WHEN Country = 'United Kingdom' THEN CustomerID END),
        2) AS CA_moyen_client_UK,
       ROUND(SUM(CASE WHEN Country <> 'United Kingdom' THEN Sales ELSE 0 END)
        / COUNT(DISTINCT CASE WHEN Country <> 'United Kingdom' THEN CustomerID END),
        2 ) AS CA_moyen_client_others
FROM transactions
WHERE Transaction_Type = 'Sale' AND CustomerID IS NOT NULL;  

-- Répartition des pays par segmentation
--La segmentation des marchés identifie : 
-- 6 marchés prioritaires : CA élevé et base de clients importante
-- 4 marchés à potentiel de développement : CA élevé mais base de clients limitée
-- 4 marchés présentant un potentiel d'augmentation du panier : base de clients importante mais CA plus limité
-- 24 marchés secondaires
-- Cette segmentation permet de distinguer les marchés à consolider des marchés présentant des opportunités de développement.

SELECT category, COUNT(*) AS cb_pays_marche
FROM pays_segmentation
GROUP BY category;

-- Pays avec un taux d'annulation élevé
-- Parmi les pays ayant réalisé plus de 100 unités vendues, 
-- les États-Unis présentent le taux d'annulation le plus élevé, avec environ 36,68 %.
-- Bahreïn et la République tchèque dépassent également les 10 %.
-- Le Royaume-Uni dépasse légèrement le seuil de 5 %.
-- Cette analyse permet d'identifier les marchés nécessitant potentiellement une analyse plus approfondie des causes d'annulation.

SELECT Country, pct_cancel_pays
FROM (SELECT Country, 
SUM(CASE WHEN Transaction_Type='Sale' THEN Quantity ELSE 0 END) AS qte_sale,
                ROUND(
				SUM(CASE WHEN Transaction_Type='Cancellation' 
                THEN ABS(Quantity) ELSE 0 END )::numeric / NULLIF(
				SUM(CASE WHEN Transaction_Type='Cancellation' 
                THEN ABS(Quantity) ELSE 0 END) + 
				SUM(CASE WHEN Transaction_Type='Sale' 
				THEN Quantity ELSE 0 END ),0)*100,2) AS pct_cancel_pays
FROM transactions
GROUP BY Country
ORDER BY pct_cancel_pays)
WHERE pct_cancel_pays >=5 AND qte_sale>100 -- Au moins 100 qte vendus
ORDER BY pct_cancel_pays DESC ;

-- KPI Temporels

-- CA du meilleur mois
-- Le meilleur mois est novembre 2011, avec environ £1,50 million de CA.
SELECT mois, CA_mois
FROM (SELECT DATE_TRUNC('month',InvoiceDate) AS mois, SUM(SALES) AS CA_mois,
       RANK() OVER (ORDER BY SUM(Sales) DESC) AS rang
FROM transactions
WHERE Transaction_Type='Sale'
GROUP BY DATE_TRUNC('month',InvoiceDate)) AS CA_mois
WHERE rang<=1;

-- CA du pire mois complet
-- Le mois de février 2011 présente le CA le plus faible parmi les mois analysés, avec environ £522 546.
-- Le CA de novembre est donc presque trois fois supérieur à celui de février.

SELECT mois, CA_mois
FROM (SELECT DATE_TRUNC('month',InvoiceDate) AS mois, SUM(SALES) AS CA_mois,
       RANK() OVER (ORDER BY SUM(Sales) ASC) AS rang
FROM transactions
WHERE Transaction_Type='Sale'
GROUP BY DATE_TRUNC('month',InvoiceDate)) AS CA_mois
WHERE rang<=1;

-- Évolution du CA entre le début et la fin de la période
-- La comparaison porte sur les trois premiers mois complets de la période (décembre 2010 à février 2011) et les trois derniers mois complets (septembre à novembre 2011).
-- 2033809.90 £ de CA les trois premiers mois, 3711565.70 £ de CA les trois derniers mois
-- Soit une augmentation de 82,49% du CA 
-- Le CA progresse fortement entre ces deux périodes, ce qui confirme une dynamique commerciale positive sur la période étudiée.

SELECT CA_debut, CA_fin, CA_fin - CA_debut AS Evolution_CA,
    ROUND((CA_fin - CA_debut)::numeric / NULLIF(CA_debut, 0) * 100,2) AS Evolution_CA_pct
FROM (SELECT SUM(CASE WHEN InvoiceDate < '2011-03-01' THEN Sales ELSE 0 END) AS CA_debut,
      SUM(CASE WHEN InvoiceDate >= '2011-09-01' AND InvoiceDate < '2011-12-01'
           THEN Sales ELSE 0 END) AS CA_fin
FROM transactions
WHERE Transaction_Type = 'Sale') AS CA;