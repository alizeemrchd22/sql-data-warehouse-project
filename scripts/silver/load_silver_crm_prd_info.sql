/*===========================================================================
  Load Silver Layer - CRM Product Information
==============================================================================
Purpose:
    Load the cleaned product information from the Bronze layer into the
    Silver layer.

Description:
    This process applies all required data quality and standardisation rules
    before loading the data into the Silver table.

Transformations:
    - Split the original product key into Category ID and Product Key
    - Standardise product names by removing leading/trailing spaces
    - Replace NULL product costs with 0
    - Replace product line abbreviations with descriptive names
    - Correct historical product end dates using the next product version
    - Load the cleaned dataset into silver.crm_prd_info

Source:
    bronze.crm_prd_info

Target:
    silver.crm_prd_info
===========================================================================*/

DO $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
BEGIN

    -------------------------------------------------------------------------
    -- Start execution timer
    -------------------------------------------------------------------------
    v_start_time := clock_timestamp();

    RAISE NOTICE '======================================================';
    RAISE NOTICE 'Loading Silver Layer - CRM Product Information';
    RAISE NOTICE 'Start Time: %', v_start_time;
    RAISE NOTICE '======================================================';

    -------------------------------------------------------------------------
    -- Clean target table before reloading
    -------------------------------------------------------------------------
    TRUNCATE TABLE silver.crm_prd_info;

    -------------------------------------------------------------------------
    -- Load cleaned data
    -------------------------------------------------------------------------
    INSERT INTO silver.crm_prd_info
    (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )

    SELECT
        prd_id,

        ---------------------------------------------------------------------
        -- Split the original product key into a category identifier
        ---------------------------------------------------------------------
        REPLACE(
            SUBSTRING(prd_key FROM 1 FOR 5),
            '-',
            '_'
        ) AS cat_id,

        ---------------------------------------------------------------------
        -- Keep only the product identifier
        ---------------------------------------------------------------------
        SUBSTRING(prd_key FROM 7) AS prd_key,

        ---------------------------------------------------------------------
        -- Remove leading and trailing spaces
        ---------------------------------------------------------------------
        TRIM(prd_nm) AS prd_nm,

        ---------------------------------------------------------------------
        -- Replace missing costs with zero
        ---------------------------------------------------------------------
        COALESCE(prd_cost,0) AS prd_cost,

        ---------------------------------------------------------------------
        -- Replace abbreviations with descriptive names
        ---------------------------------------------------------------------
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
            WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
            WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
            WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,

        ---------------------------------------------------------------------
        -- Start date already valid
        ---------------------------------------------------------------------
        prd_start_dt,

        ---------------------------------------------------------------------
        -- Correct invalid historical end dates
        ---------------------------------------------------------------------
        COALESCE(
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            ) - INTERVAL '1 day',
            prd_end_dt
        ) AS prd_end_dt

    FROM bronze.crm_prd_info;

    -------------------------------------------------------------------------
    -- End execution timer
    -------------------------------------------------------------------------
    v_end_time := clock_timestamp();

    RAISE NOTICE '======================================================';
    RAISE NOTICE 'Silver Product table successfully loaded.';
    RAISE NOTICE 'Rows Loaded: %', (SELECT COUNT(*) FROM silver.crm_prd_info);
    RAISE NOTICE 'Execution Time: %', (v_end_time - v_start_time);
    RAISE NOTICE '======================================================';

END $$;
