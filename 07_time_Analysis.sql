-- Analyse Série Time

-- Quels sont les mois avec les meilleurs CA et comment évolue le CA au cours du temps?	
--Les données couvrent la période de décembre 2010 à décembre 2011.
--Le CA est relativement élevé dès le début de la période, 
--puis connaît une baisse avant de progresser fortement à partir de septembre 2011.
--Les meilleurs mois sont septembre, octobre et novembre, 
--avec novembre en première position.
--Décembre 2011 doit être interprété avec prudence : les données ne couvrent 
--que les 9 premiers jours du mois. Malgré cette période incomplète, 
--décembre ne se situe pas parmi les derniers mois en termes de CA.
SELECT DATE_TRUNC('month', InvoiceDate) AS mois, SUM(SALES) AS CA_mois,
       RANK() OVER (ORDER BY SUM(SALES) DESC) AS Classement
FROM transactions
WHERE Transaction_Type = 'Sale'
GROUP BY DATE_TRUNC('month', InvoiceDate)
ORDER BY mois;
-- On pourrait même regarder l'écart par rapport à la moyenne ou l'écart-type pour comparer les mois ...

-- Analyse du nombre de commandes par mois
-- On observe une forte similitude entre le classement des mois selon le CA 
-- et selon le nombre de commandes.
--Pour les mois complets, le nombre de commandes varie d'environ 1 120 à 2 884 commandes
-- avec un maximum atteint en novembre 2011.
SELECT DATE_TRUNC('month', InvoiceDate) AS mois, COUNT(DISTINCT InvoiceNo) AS nb_commande,
       RANK() OVER(ORDER BY COUNT(DISTINCT InvoiceNo) DESC) AS Classement_nb_commande,
	   RANK() OVER(ORDER BY SUM(SALES) DESC) AS Classement_sales
	   FROM transactions
       WHERE Transaction_Type = 'Sale'
       GROUP BY DATE_TRUNC('month', InvoiceDate)
       ORDER BY mois;

-- Panier Moyen par Mois
-- CA= nombre de commandes* panier moyen d'une commande
-- On remarque dans le haut du classement des meilleurs mois que :
-- Le nombre de commandes est un indicateur assez fiable du CA
-- Le panier moyen pas forcément car par exemple le mois de janvier 
-- est en 10e position du mois avec le plus de CA alors que son panier moyen
-- est classé deuxième des 
SELECT DATE_TRUNC('month', InvoiceDate) AS mois, COUNT(DISTINCT InvoiceNo) AS nb_commande,
       SUM(SALES)/COUNT(DISTINCT InvoiceNo) AS Panier_Moyen,
       RANK() OVER(ORDER BY SUM(SALES) DESC) AS Classement_CA
	   FROM transactions
       WHERE Transaction_Type = 'Sale'
       GROUP BY DATE_TRUNC('month', InvoiceDate)
       ORDER BY classement_ca;

-- Évolution des annulations par mois et comparatif du CA
--L'indicateur de volume d'annulation atteint environ 21 % en janvier 2011 et 
-- 17 % en décembre 2011. Les autres mois restent généralement sous les 5 %.
-- A première vue, aucune relation évidente n'apparaît entre le niveau de 
-- CA mensuel et le taux d'annulation. Une analyse plus approfondie serait nécessaire 
--pour déterminer si les périodes de forte activité entraînent davantage d'annulations.
SELECT DATE_TRUNC('month', InvoiceDate) AS mois,
SUM(CASE WHEN Transaction_Type='Cancellation' THEN ABS(Quantity)
ELSE 0 END) AS qte_cancel,
ROUND(SUM(CASE WHEN Transaction_Type='Cancellation' THEN ABS(Quantity)ELSE 0 END)::numeric
/NULLIF(SUM(CASE WHEN Transaction_Type='Cancellation' THEN (ABS(Quantity))
ELSE 0 END) + SUM(CASE WHEN Transaction_Type='Sale' THEN Quantity ELSE 0 END),0)*100,2)
AS pct_cancel,
RANK() OVER (ORDER BY SUM(CASE WHEN Transaction_Type = 'Sale' THEN Sales 
            ELSE 0 END) DESC) AS Classement
FROM transactions
GROUP BY DATE_TRUNC('month', InvoiceDate)
ORDER BY qte_cancel DESC;

-- Regardons les CA par mois pour les marchés les plus intéressants
-- Le Royaume-Uni domine très largement tous les mois. 
-- Son CA mensuel est sans commune mesure avec celui des autres pays.
-- Pour les autres marchés, on observe des pics concentrés sur certains mois. 
--Par exemple, les Pays-Bas atteignent plus de £40k en août et octobre, 
--tandis que l'Irlande dépasse £42k en juillet et septembre.
-- Néanmoins les Pays-Bas et l'Irlande présentent des niveaux élevés malgré 
-- une base de clients très faible. Il faut donc interpréter ces pics avec prudence.
-- Les principaux marchés européens comme France et Allemagne semblent avoir une activité
-- plus régulière, mais avec un CA mensuel nettement inférieur au Royaume-Uni.
SELECT DATE_TRUNC('month', InvoiceDate) AS mois, Country,
       SUM(SALES) AS CA_pays_mois
FROM transactions
WHERE Transaction_Type='Sale' AND Country IN ('United Kingdom', 'Germany',
  'France', 'Netherlands','EIRE','Australia')
GROUP BY Country, DATE_TRUNC('month',InvoiceDate)
ORDER BY CA_pays_mois DESC ;
    

-- Comparaison entre les trois premiers mois disponibles 
-- et les trois derniers mois disponibles
-- Pour les trois derniers mois, c'est du 9 septembre au 9 décembre!
SELECT Country,
SUM(CASE WHEN InvoiceDate < '2011-03-01' THEN Sales ELSE 0 END) AS CA_debut,
SUM(CASE WHEN InvoiceDate >= '2011-09-09' THEN Sales ELSE 0 END) AS CA_fin
FROM transactions
WHERE Transaction_Type='Sale'
GROUP BY Country
ORDER BY CA_fin DESC ;

-- Comparaison du CA entre les trois premiers mois et les trois derniers mois disponibles.
-- Le Royaume-Uni enregistre de loin la plus forte évolution en valeur absolue,
-- ce qui s'explique principalement par son poids très important dans le CA total.
-- La majorité des principaux marchés européens connaissent également une évolution
-- positive entre le début et la fin de la période.
-- Les évolutions des marchés secondaires sont plus faibles en valeur absolue
-- et doivent être interprétées avec prudence compte tenu de leur faible niveau de CA.

-- Évolution en pourcentage selon les trois derniers mois disponibles
SELECT Country, Evolution_CA_pct
FROM (SELECT Country,
    ROUND(((CA_fin - CA_debut)::numeric / NULLIF(CA_debut, 0)) * 100,2
    ) AS Evolution_CA_pct
FROM (SELECT Country,
SUM(CASE WHEN InvoiceDate < '2011-03-01' THEN Sales ELSE 0 END) AS CA_debut,
SUM(CASE WHEN InvoiceDate >= '2011-09-09' THEN Sales ELSE 0 END) AS CA_fin
FROM transactions
WHERE Transaction_Type='Sale' 
GROUP BY Country) AS CA) AS CA
WHERE Evolution_CA_pct IS NOT NULL
ORDER BY Evolution_CA_pct DESC LIMIT 20;
