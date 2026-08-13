/*
===============================================================================
Stored Procedure: Load Silver ERP Customer Information
===============================================================================

Purpose:
    Load cleaned and standardized ERP customer data from the Bronze layer
    into silver.erp_cust_az12.

Transformations:

    - Remove the "NAS" prefix from customer IDs when present.

    - Replace invalid birth dates with NULL:
        * dates in the future
        * dates earlier than 1924-01-01

    - Standardize gender values:
        * F / FEMALE -> Female
        * M / MALE   -> Male
        * anything else -> n/a

    - Automatically populate dwh_create_date using the default value
      defined in the Silver table.

Source:
    bronze.erp_cust_az12

Target:
    silver.erp_cust_az12

Warning:
    TRUNCATE removes all existing rows from the Silver target table before
    reloading the transformed dataset.

===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_erp_cust_az12()

LANGUAGE plpgsql

AS $$

DECLARE

    start_time TIMESTAMP;
    end_time TIMESTAMP;
    rows_loaded INTEGER;

BEGIN

    ---------------------------------------------------------------------------
    -- Start execution timer
    ---------------------------------------------------------------------------

    start_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer - ERP Customer Information';
    RAISE NOTICE '================================================';


    ---------------------------------------------------------------------------
    -- Clear target table
    ---------------------------------------------------------------------------

    RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';

    TRUNCATE TABLE silver.erp_cust_az12;


    ---------------------------------------------------------------------------
    -- Load cleaned and standardized data
    ---------------------------------------------------------------------------

    RAISE NOTICE '>> Loading transformed ERP customer data';

    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )

    SELECT

        -----------------------------------------------------------------------
        -- Problem:
        -- ERP customer IDs may contain the prefix "NAS".
        --
        -- Transformation:
        -- Remove "NAS" and keep the actual customer identifier.
        -----------------------------------------------------------------------

        CASE
            WHEN cid LIKE 'NAS%'
            THEN SUBSTRING(cid FROM 4)
            ELSE cid
        END AS cid,


        -----------------------------------------------------------------------
        -- Problem:
        -- Some birth dates may be invalid or implausible.
        --
        -- Transformation:
        -- Replace future dates or dates before 1924-01-01 with NULL.
        -----------------------------------------------------------------------

        CASE
            WHEN bdate > CURRENT_DATE
              OR bdate < DATE '1924-01-01'
            THEN NULL
            ELSE bdate
        END AS bdate,


        -----------------------------------------------------------------------

        -- Problem:

        -- Gender values may use different formats, abbreviations or letter case.

        --

        -- Transformation:

        -- Convert all values to uppercase before comparison and standardize them

        -- into a single format.

        -----------------------------------------------------------------------

        CASE

            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')

                THEN 'FEMALE'

            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')

                THEN 'MALE'

            ELSE 'N/A'

        END AS gen

    FROM bronze.erp_cust_az12;


    ---------------------------------------------------------------------------
    -- Capture number of inserted rows
    ---------------------------------------------------------------------------

    GET DIAGNOSTICS rows_loaded = ROW_COUNT;


    ---------------------------------------------------------------------------
    -- End execution timer
    ---------------------------------------------------------------------------

    end_time := clock_timestamp();

    RAISE NOTICE '>> Rows Loaded: %', rows_loaded;

    RAISE NOTICE '>> Load Duration: % seconds',
        ROUND(
            EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC,
            3
        );

    RAISE NOTICE '================================================';
    RAISE NOTICE 'ERP Customer Information loading completed';
    RAISE NOTICE '================================================';


EXCEPTION

    WHEN OTHERS THEN

        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR DURING ERP CUSTOMER SILVER LOAD';
        RAISE NOTICE 'Error message: %', SQLERRM;
        RAISE NOTICE 'SQL state: %', SQLSTATE;
        RAISE NOTICE '================================================';

        RAISE;

END;

$$;
