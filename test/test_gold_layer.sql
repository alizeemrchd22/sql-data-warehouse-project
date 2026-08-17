-- verifications qualite sur la gold layer
-- je run ca avant de commencer a analyser les donnees, pour etre sur
-- que mes vues sont clean. si une requete plus bas renvoie des lignes
-- ca veut dire qu'il y a un souci a regler

-- 1) est ce que customer_key est unique dans dim_customers
-- normalement chaque client = une seule ligne, donc ca doit rien renvoyer
SELECT
    customer_key,
    COUNT(*) AS nb_doublons
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;


-- 2) pareil mais pour product_key dans dim_products
SELECT
    product_key,
    COUNT(*) AS nb_doublons
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;


-- 3) est ce que toutes les ventes sont bien reliees a un client et un produit qui existent
-- left join vers les deux dimensions, si customer_key ou product_key ressort en NULL
-- ca veut dire que la vente pointe vers rien -> lien casse
SELECT *
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
    ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
    ON p.product_key = f.product_key
WHERE p.product_key IS NULL
   OR c.customer_key IS NULL;
