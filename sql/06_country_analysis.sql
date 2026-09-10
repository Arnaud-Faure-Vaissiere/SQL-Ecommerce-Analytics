--Analyse Pays

--Quels pays ont les clients qui dépensent le plus en moyenne ?
-- L'irlande largement devant avec 88 420£ (mais juste 3 clients)
-- Idem 1 seul client pour Singapour avec 31 000 £
-- Sinon le reste du top 10 est à 8,9 clients en général
-- 15 383 £ (Australie), 2 000 £ pour l'Allemagne néanmoins, avec 94 clients.
--Les valeurs très élevées de l’Irlande et de Singapour doivent être interprétées 
-- avec prudence, car elles reposent sur un nombre très limité de clients. 
--Elles constituent davantage un signal à examiner qu'une preuve d'un marché particulièrement performant.
-- L’Australie semble présenter un potentiel intéressant, avec une dépense moyenne élevée 
-- tout en reposant sur un nombre de clients supérieur aux marchés les plus extrêmes.
SELECT Country, SUM(SALES)/COUNT(DISTINCT CustomerID) AS nb_depense_client_pays,
                 COUNT(DISTINCT CustomerID) AS nb_clients
FROM transactions
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL
GROUP BY Country
ORDER BY nb_depense_client_pays DESC LIMIT 10;


--Quels marchés ont la plus grande base de clients identifiés ?
-- UK 3921 clients, les autres pays ont au total 426 clients
-- 90,37% des clients sont du Royaume-Uni
-- Le 10ème pays n'a plus que 11 clients
-- La clientèle est extrêmement concentrée au Royaume-Uni. 
-- Les autres pays représentent une faible part de la base clients
-- ce qui montre que l'entreprise dépend fortement de son marché domestique.
SELECT Country, COUNT(DISTINCT CustomerID) AS nb_clients
FROM transactions
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL
GROUP BY Country
ORDER BY nb_clients DESC LIMIT 10;


WITH Clients AS 
(SELECT Country, COUNT(DISTINCT CustomerID) AS nb_clients
FROM transactions
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL
GROUP BY Country), 
      Uk_Other AS
(SELECT Country, nb_clients,
 CASE  WHEN Country = 'United Kingdom' THEN 'UK' ELSE 'Other' END AS cat
 FROM Clients),
      SOMME AS
(SELECT COUNT(DISTINCT CustomerID) AS somme_total
FROM transactions
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL),
       SOMME_Uk_Others AS
(SELECT cat, SUM(nb_clients) as nb_clients_cat
FROM Uk_Other
GROUP BY cat)
SELECT SOMME_Uk_Others.cat, SOMME_Uk_Others.nb_clients_cat,
ROUND(SOMME_Uk_Others.nb_clients_cat::numeric / SOMME.somme_total * 100, 2
    ) AS pct_clients
FROM SOMME_Uk_Others
CROSS JOIN SOMME;

-- Un pays génère-t-il beaucoup de CA parce qu'il a beaucoup de clients?
-- Le Royaume-Uni domine en chiffre d'affaires
-- Logique avec plus de 90% de clients
-- Cependant, certains marchés internationaux génèrent un CA important 
-- malgré une base de clients beaucoup plus faible. 
--Les Pays-Bas (9 clients) et l'Irlande (3 clients) illustrent ce phénomène, 
-- avec un CA (2ème et 3ème avec plus de 2 millions de CA) élevé rapporté à un nombre limité de clients.
SELECT Country, SUM(SALES) AS CA_pays,
                 COUNT(DISTINCT CustomerID) AS nb_clients
FROM transactions
WHERE Transaction_Type='Sale' AND CustomerID IS NOT NULL
GROUP BY Country
ORDER BY CA_pays DESC LIMIT 10;

-- Segmentation des pays en fonction du nombre de clients et du CA
-- On réalise cela avec la médiane ou le troisième quantile
-- On a pris le troisième quantile pour le CA par pays (médiane de 14,992 £, 38,129 £ mtn) 
-- On a pris le 3ème quantile pour seuil_client (la médiane était de 5, 10,75 mtn)
DROP VIEW IF EXISTS pays_segmentation;
CREATE VIEW pays_segmentation AS 
WITH 
      table_pays AS
(SELECT Country , SUM(SALES) AS CA_pays, COUNT(DISTINCT CustomerID) AS nb_clients
FROM transactions
WHERE Transaction_Type='Sale'
GROUP BY Country),
       Seuil AS 
(SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY CA_pays) AS seuil_CA,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY nb_clients) AS seuil_client
FROM table_pays)
SELECT table_pays.Country, table_pays.nb_clients, table_pays.CA_pays, 
CASE WHEN table_pays.CA_pays>=Seuil.seuil_CA 
AND table_pays.nb_clients>=Seuil.seuil_client THEN 'Marché Prioritaire'
WHEN table_pays.CA_pays>=Seuil.seuil_CA 
AND table_pays.nb_clients<Seuil.seuil_client THEN 'Potentiel de développement'
WHEN table_pays.CA_pays<Seuil.seuil_CA 
AND table_pays.nb_clients>=Seuil.seuil_client THEN 'Potentiel augmentation du panier'
ELSE 'marché secondaire' END AS category
FROM table_pays
CROSS JOIN Seuil;
	
SELECT *
FROM pays_segmentation;

-- On a 6 marchés prioritaires, 4 potentiels augmentation du panier 
-- 4 potentiel de développement et 24 marché secondaire
SELECT category, COUNT(nb_clients) AS cb_pays_par_marche
FROM pays_segmentation
GROUP BY category;

-- Regardons par exemple les marchés prioritaires : 
-- UK, Allemagne, France, Espagne, Suisse, Belgique
-- Les principaux marchés prioritaires sont majoritairement des pays européens proches du Royaume-Uni.
SELECT Country, CA_pays, category
FROM pays_segmentation
WHERE category='Marché Prioritaire'
ORDER BY  CA_pays DESC ;

-- Regardons maintenant les marchés intéressants :
-- Pays à fort potentiel avec un bon CA: Pays-Bas, Irlande, Australie, Suède
-- Pays à fort potentiel d'augmentation panier: Portugal, Finlande, Italie, Autriche
SELECT Country, CA_pays, category
FROM pays_segmentation
WHERE category='Potentiel de développement' OR category='Potentiel augmentation du panier'
ORDER BY  CA_pays DESC ;

-- Analyse des annulations par pays 

-- Quantité d'annulation par pays
-- Uk largement devant avec plus de 261 000 quantités annulées
-- Les pays dans le top 10 sont des pays à fort potentiel ou marché prioritaires
-- Excepté pour USA et JAPAN 
SELECT Country, -SUM(Quantity) AS qte_cancel
FROM transactions
WHERE Transaction_Type='Cancellation'
GROUP BY Country
ORDER BY qte_cancel DESC LIMIT 10;

-- Taux d'annulation par pays
-- USA largement en tête avec plus de 36% d'annulation
-- Taux assez élevé aussi à Bahreïn (14,67%) et en République tchèque(10,53%)
-- Pour le reste des pays on passe en dessous de 6%
DROP VIEW IF EXISTS Annulation;
CREATE VIEW Annulation AS 
SELECT Country, SUM(CASE WHEN Transaction_Type='Cancellation' 
                THEN ABS(Quantity) ELSE 0 END ) AS qte_cancel,
				SUM(CASE WHEN Transaction_Type='Sale' 
				THEN Quantity ELSE 0 END ) AS qte_vente,
				ROUND(
				SUM(CASE WHEN Transaction_Type='Cancellation' 
                THEN ABS(Quantity) ELSE 0 END )::numeric / NULLIF(
				SUM(CASE WHEN Transaction_Type='Cancellation' 
                THEN ABS(Quantity) ELSE 0 END) + 
				SUM(CASE WHEN Transaction_Type='Sale' 
				THEN Quantity ELSE 0 END ),0)*100,2) AS pct_cancel_pays
FROM transactions
GROUP BY Country
ORDER BY pct_cancel_pays DESC ;

SELECT *
FROM annulation;

--Les marchés qui génèrent beaucoup de CA ont-ils aussi beaucoup d'annulations 
--En règle générale, ils en ont assez peu: 5,24% pour UK
-- Puis le reste du top 10 des pays par CA a en général 1%, 2%, 3% maximum d'annualations.
SELECT p.ca_pays, p.country,
       p.category, a.pct_cancel_pays
FROM pays_segmentation AS p
JOIN annulation AS a ON p.country=a.country
ORDER BY p.ca_pays DESC LIMIT 10;


