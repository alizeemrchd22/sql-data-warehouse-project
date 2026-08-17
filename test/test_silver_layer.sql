-- verifications qualite sur la silver layer
-- je run ca juste apres avoir charge les donnees dans silver, pour
-- verifier que le nettoyage a bien marche avant de construire la gold layer
-- si une requete plus bas renvoie des lignes (sauf indication contraire) y'a un souci


-- table crm_cust_info -----------------------------------------------

-- cst_id ne doit jamais etre NULL ni duplique, c'est la primary key
SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- check espaces en trop autour de cst_key
SELECT
    cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

-- juste pour voir les valeurs possibles et si tout est bien standardise
SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;


-- table crm_prd_info --------------------------------------------------

-- meme check pour prd_id
SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- espaces en trop sur le nom du produit
SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- le cout ne devrait jamais etre negatif ou vide
SELECT
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- valeurs possibles de la ligne produit
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;

-- la date de fin ne peut pas etre avant la date de debut, logique
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;


-- table crm_sales_details ---------------------------------------------

-- check sur les dates au format brut (encore en bronze ici, avant conversion)
-- une date valide doit faire 8 chiffres (YYYYMMDD) et etre dans une plage raisonnable
SELECT
    NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
   OR LENGTH(sls_due_dt::text) != 8
   OR sls_due_dt > 20500101
   OR sls_due_dt < 19000101;

-- la date de commande doit toujours etre avant l'expedition et l'echeance
SELECT *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- verif que sales = quantity * price, et que rien n'est nul ou negatif/zero
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;


-- table erp_cust_az12 --------------------------------------------------

-- les dates de naissance doivent etre realistes, entre 1924 et aujourd'hui
SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > CURRENT_DATE;

-- valeurs possibles pour le genre
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;


-- table erp_loc_a101 ----------------------------------------------------

-- valeurs possibles pour le pays, histoire de reperer les incoherences
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;


-- table erp_px_cat_g1v2 --------------------------------------------------

-- espaces en trop sur les colonnes texte
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);

-- valeurs possibles pour maintenance
SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2;
