/*
===============================================================================
Stored Procedure: Load Silver ERP Location Information
===============================================================================

Purpose:
    Load cleaned and standardized ERP location data from the Bronze layer
    into silver.erp_loc_a101.

Transformations:

    - Remove hyphens from customer IDs.

    - Standardize country values:
        * DE -> GERMANY
        * US / USA -> UNITED STATES
        * NULL or blank -> N/A
        * All other countries converted to uppercase.

    - Automatically populate dwh_create_date using the default value
      defined in the Silver table.

Source:
    bronze.erp_loc_a101

Target:
    silver.erp_loc_a101

Warning:
    TRUNCATE removes all existing rows from the Silver target table before
    reloading the transformed dataset.

===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_erp_loc_a101()

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
    RAISE NOTICE 'Loading Silver Layer - ERP Location Information';
    RAISE NOTICE '================================================';


    ---------------------------------------------------------------------------
    -- Clear target table
    ---------------------------------------------------------------------------

    RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';

    TRUNCATE TABLE silver.erp_loc_a101;


    ---------------------------------------------------------------------------
    -- Load cleaned and standardized data
    ---------------------------------------------------------------------------

    RAISE NOTICE '>> Loading transformed ERP location data';

    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )

    SELECT

        -----------------------------------------------------------------------
        -- Remove hyphens from customer IDs
        -----------------------------------------------------------------------

        REPLACE(cid, '-', '') AS cid,


        -----------------------------------------------------------------------
        -- Standardize country names
        -----------------------------------------------------------------------

        CASE
            WHEN UPPER(TRIM(cntry)) = 'DE'
                THEN 'GERMANY'

            WHEN UPPER(TRIM(cntry)) IN ('US', 'USA')
                THEN 'UNITED STATES'

            WHEN cntry IS NULL
              OR TRIM(cntry) = ''
                THEN 'N/A'

            ELSE UPPER(TRIM(cntry))
        END AS cntry

    FROM bronze.erp_loc_a101;


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
    RAISE NOTICE 'ERP Location Information loading completed';
    RAISE NOTICE '================================================';


EXCEPTION

    WHEN OTHERS THEN

        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR DURING ERP LOCATION SILVER LOAD';
        RAISE NOTICE 'Error message: %', SQLERRM;
        RAISE NOTICE 'SQL state: %', SQLSTATE;
        RAISE NOTICE '================================================';

        RAISE;

END;

$$;
