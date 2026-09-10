-- Analyse du chiffre d'affaires et des performances par pays

-- 1. Chiffre d'affaires par pays

-- Le Royaume-Uni génère de très loin le plus gros chiffre
-- d'affaires, pour plus de 9 millions de livres sterling.
-- Les Pays-Bas, l'Irlande, l'Allemagne et la France suivent, avec un 
-- chiffre d'affaires compris approximativement entre 200 000 et 300 000 livres sterling.

SELECT Country, SUM(Sales) AS total_sales
FROM transactions
WHERE Transaction_Type = 'Sale'
GROUP BY Country
ORDER BY total_sales DESC;

-- 2. Nombre de commandes par pays

-- Le Royaume-Uni domine également très largement avec plus de 18 000 commandes.
-- L'Allemagne, la France et l'Irlande arrivent ensuite, mais avec des volumes inférieurs.

SELECT Country, COUNT(DISTINCT InvoiceNo) AS number_of_orders
FROM transactions
WHERE Transaction_Type = 'Sale'
GROUP BY Country
ORDER BY number_of_orders DESC;


-- Interessant: Panier moyen (AOV) par pays

-- Le panier moyen varie fortement selon les pays.
-- Certains marchés comme Singapour et les Pays-Bas présentent un AOV très élevé.
-- tandis que le Royaume-Uni présente un AOV plus faible malgré son très important volume de commandes.
-- Ces résultats suggèrent des comportements d'achat différents selon les marchés. 
-- Les pays présentant un AOV élevé doivent cependant être interprétés en tenant compte 
-- du nombre de commandes, car un faible volume peut produire un AOV élevé.

SELECT Country, SUM(Sales) / COUNT(DISTINCT InvoiceNo) AS average_order_value
FROM transactions
WHERE Transaction_Type = 'Sale'
GROUP BY Country
ORDER BY average_order_value DESC;

-- On a remarqué qu'il y avait des produits qui correspondent à des frais de port
-- Ou autre et qu'on ne peut pas considérer comme des produits dans notre analyse

-- Identification des références non-produits

--On remarque que les ID des non-produits sont différents on peut donc les identifier facilement
--Certaines exceptions (FP OU FN) 

SELECT
    StockCode,
    MAX(Description) AS Description,
    SUM(Quantity) AS total_quantity,
    SUM(Sales) AS total_sales
FROM transactions
WHERE StockCode IN (
      'DOT',           -- DOTCOM POSTAGE
      'POST',          -- POSTAGE
      'M',             -- Manual
      'm',             -- Manual
      '23084',         -- website fixed
      'B',             -- Adjust bad debt
      'C2',            -- CARRIAGE
      'AMAZONFEE',     -- AMAZON FEE
      'BANK CHARGES',  -- Bank Charges
      'S',             -- SAMPLES
      'D',             -- Discount
      'CRUK',          -- CRUK Commission
      '23203',         -- mailout
      '22502',         -- reverse adjustment
      '84879',         -- damaged
      '85123A'         -- wrongly marked carton
  )
GROUP BY StockCode
ORDER BY total_sales DESC LIMIT 30;

--On crée une vue pour faciliter les résultats suivants sans réécrire la commande not in
DROP VIEW real_product;
CREATE VIEW real_product AS
SELECT *
FROM transactions
WHERE StockCode NOT IN ('DOT', 'POST', 'M', 'm', '23084','B', 'C2', 'AMAZONFEE', 
  'BANK CHARGES','S', 'D', 'CRUK', '23203', '22502','84879', '85123A');

-- Analyse des réels produits (chiffre d'affaires, produit le plus annulé, etc...)

--Quels produits génèrent le plus de CA ?
SELECT
    StockCode,
    MAX(Description) AS description,
    SUM(Sales) AS total_ventes_produits
FROM real_product
GROUP BY StockCode
ORDER BY total_ventes_produits DESC LIMIT 10;

--Quels produits sont le plus vendus (quantité) ?
SELECT StockCode, MAX(Description) AS description, SUM(Quantity) AS quantite_vendus_produits 
FROM real_product
WHERE Transaction_Type = 'Sale'
GROUP BY StockCode
ORDER BY  quantite_vendus_produits DESC
LIMIT 10 ;

--Important: Comparer volume et chiffres d'affaires
SELECT StockCode, MAX(Description) AS Description,
	SUM(Quantity) AS quantite_vendus_produits,
    SUM(Sales) AS total_ventes_produits
FROM real_product
WHERE Transaction_Type = 'Sale'
GROUP BY StockCode
ORDER BY total_ventes_produits DESC
LIMIT 20;

-- Conclusion :
-- Les produits générant le plus de chiffre d'affaires ne sont pas
-- nécessairement ceux vendus en plus grande quantité.
-- Le REGENCY CAKESTAND 3 TIER est le produit générant le plus
-- de chiffre d'affaires avec environ £174k, alors qu'il n'arrive
-- pas en première position en quantité vendue.
-- Cette comparaison montre qu'il est important d'analyser à la fois
-- le volume vendu et le chiffre d'affaires : un produit peut être
-- très vendu en quantité sans être celui qui génère le plus de CA,
-- notamment en fonction de son prix unitaire.

-- Quels sont les réels produits qui ont le plus d'annulation
SELECT StockCode, MAX(Description) AS Description,
       COUNT(*) AS number_cancellation
FROM real_product
WHERE Transaction_Type='Cancellation'
GROUP BY StockCode
ORDER BY number_cancellation DESC LIMIT 20;

-- Quels sont les réels produits qui ont le plus d'annulation en quantité
SELECT StockCode, MAX(Description) AS Description,
       SUM(ABS(Quantity)) AS quantity
FROM real_product
WHERE Transaction_Type='Cancellation'
GROUP BY StockCode
ORDER BY quantity DESC LIMIT 20;

-- Question business: Quels produits réels ont les taux d'annulation les plus élevés ?
SELECT StockCode, MAX(Description) AS Description,
       SUM(CASE WHEN Transaction_Type='Sale' THEN Quantity ELSE 0 END) AS qte_sold,
	   SUM(CASE WHEN Transaction_Type='Cancellation' THEN ABS(Quantity) ELSE 0 END) AS qte_cancel,
	   ROUND( 
	   SUM(CASE WHEN Transaction_Type='Cancellation' THEN ABS(Quantity) ELSE 0 END)::numeric
       / NULLIF(SUM(CASE WHEN Transaction_Type='Cancellation' THEN ABS(Quantity) ELSE 0 END)
	           +SUM(CASE WHEN Transaction_Type='Sale' THEN Quantity ELSE 0 END),0)
	 *100,2) AS pct_cancel
FROM real_product
GROUP BY StockCode
HAVING SUM(CASE WHEN Transaction_Type = 'Sale' THEN Quantity ELSE 0 END) > 0
ORDER BY pct_cancel DESC LIMIT 20;

--PAPER CRAFT, LITTLE BIRDIE présente un volume d'annulations exceptionnellement élevé
-- équivalent au volume vendu. Ce comportement mérite une investigation complémentaire
-- afin de déterminer s'il s'agit de véritables retours clients, 
-- d'annulations massives ou d'un traitement opérationnel particulier.
--APER CRAFT, LITTLE BIRDIE	80 995	80 995	
--MEDIUM CERAMIC TOP STORAGE JAR	78 033	74 494	
--ROTATING SILVER ANGELS	9 461	9 376	
--FAIRY CAKE FLANNEL		3 150

