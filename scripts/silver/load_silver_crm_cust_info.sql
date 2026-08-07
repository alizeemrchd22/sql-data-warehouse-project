/*
===============================================================================
Load Silver Layer: CRM Customer Information
===============================================================================

Script Purpose:

    This script loads cleaned and standardized customer data from
    bronze.crm_cust_info into silver.crm_cust_info.

    The following transformations are applied during the load:

    - Remove records where cst_id is NULL.
    - Identify multiple versions of the same customer using ROW_NUMBER().
    - Keep only the most recent record for each cst_id based on cst_create_date.
    - Remove leading and trailing spaces from first and last names.
    - Standardize marital status:
        M -> Married
        S -> Single
    - Standardize gender:
        M -> Male
        F -> Female
    - Replace missing or unexpected categorical values with 'n/a'.
    - Automatically populate dwh_create_date in the Silver table using
      its DEFAULT CURRENT_TIMESTAMP value.

    The Bronze table remains unchanged and continues to store the raw source data.

Warning:

    TRUNCATE removes all existing rows from silver.crm_cust_info before
    the cleaned data is reloaded.

===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_crm_cust_info()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN

    start_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver CRM Customer Information';
    RAISE NOTICE '================================================';

    RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';

    TRUNCATE TABLE silver.crm_cust_info;

    RAISE NOTICE '>> Loading cleaned data into: silver.crm_cust_info';

    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )

    SELECT
        cst_id,
        cst_key,

        TRIM(cst_firstname) AS cst_firstname,

        TRIM(cst_lastname) AS cst_lastname,

        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            ELSE 'n/a'
        END AS cst_marital_status,

        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            ELSE 'n/a'
        END AS cst_gndr,

        cst_create_date

    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) AS ranked_customers

    WHERE flag_last = 1;

    end_time := clock_timestamp();

    RAISE NOTICE '>> Load Duration: % seconds',
        ROUND(EXTRACT(EPOCH FROM (end_time - start_time))::numeric, 3);

    RAISE NOTICE '================================================';
    RAISE NOTICE 'CRM Customer Information loading completed';
    RAISE NOTICE '================================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR DURING CRM CUSTOMER SILVER LOAD';
        RAISE NOTICE 'Error message: %', SQLERRM;
        RAISE NOTICE 'SQL state: %', SQLSTATE;
        RAISE NOTICE '================================================';

        RAISE;

END;
$$;

CALL silver.load_crm_cust_info();

SELECT *
FROM silver.crm_cust_info
