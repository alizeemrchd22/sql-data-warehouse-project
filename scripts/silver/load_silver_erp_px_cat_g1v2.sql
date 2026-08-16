/*
===============================================================================
Stored Procedure: Load Silver ERP Product Categories
===============================================================================

Purpose:
    Load ERP product category data from the Bronze layer into
    silver.erp_px_cat_g1v2.

Transformations:

    - No data transformations required.
    - Source data already meets the Silver layer quality standards.

    - Automatically populate dwh_create_date using the default value
      defined in the Silver table.

Source:
    bronze.erp_px_cat_g1v2

Target:
    silver.erp_px_cat_g1v2

Warning:
    TRUNCATE removes all existing rows from the Silver target table before
    reloading the dataset.

===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_erp_px_cat_g1v2()

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
    RAISE NOTICE 'Loading Silver Layer - ERP Product Categories';
    RAISE NOTICE '================================================';


    ---------------------------------------------------------------------------
    -- Clear target table
    ---------------------------------------------------------------------------

    RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2';

    TRUNCATE TABLE silver.erp_px_cat_g1v2;


    ---------------------------------------------------------------------------
    -- Load data
    ---------------------------------------------------------------------------

    RAISE NOTICE '>> Loading ERP product category data';

    INSERT INTO silver.erp_px_cat_g1v2
    (
        id,
        cat,
        subcat,
        maintenance
    )

    SELECT

        id,
        cat,
        subcat,
        maintenance

    FROM bronze.erp_px_cat_g1v2;


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
    RAISE NOTICE 'ERP Product Categories loading completed';
    RAISE NOTICE '================================================';


EXCEPTION

    WHEN OTHERS THEN

        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR DURING ERP PRODUCT CATEGORY SILVER LOAD';
        RAISE NOTICE 'Error message: %', SQLERRM;
        RAISE NOTICE 'SQL state: %', SQLSTATE;
        RAISE NOTICE '================================================';

        RAISE;

END;

$$;
