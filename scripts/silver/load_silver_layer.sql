/*
===============================================================================
Stored Procedure: Load Silver Layer
===============================================================================

Purpose:
    Execute all Silver layer loading procedures in the correct order.

Description:
    This procedure orchestrates the complete loading of the Silver layer by
    executing each individual table loading procedure.

===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver_layer()

LANGUAGE plpgsql

AS $$

DECLARE

    start_time TIMESTAMP;
    end_time TIMESTAMP;

BEGIN

    ---------------------------------------------------------------------------
    -- Start execution timer
    ---------------------------------------------------------------------------

    start_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Complete Silver Layer';
    RAISE NOTICE '================================================';


    ---------------------------------------------------------------------------
    -- CRM Tables
    ---------------------------------------------------------------------------

    CALL silver.load_crm_cust_info();

    CALL silver.load_crm_prd_info();

    CALL silver.load_crm_sales_details();


    ---------------------------------------------------------------------------
    -- ERP Tables
    ---------------------------------------------------------------------------

    CALL silver.load_erp_cust_az12();

    CALL silver.load_erp_loc_a101();

    CALL silver.load_erp_px_cat_g1v2();


    ---------------------------------------------------------------------------
    -- End execution timer
    ---------------------------------------------------------------------------

    end_time := clock_timestamp();

    RAISE NOTICE '================================================';

    RAISE NOTICE 'Silver Layer loaded successfully';

    RAISE NOTICE 'Total Duration: % seconds',
        ROUND(
            EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC,
            3
        );

    RAISE NOTICE '================================================';


EXCEPTION

    WHEN OTHERS THEN

        RAISE NOTICE '================================================';

        RAISE NOTICE 'ERROR DURING SILVER LAYER LOAD';

        RAISE NOTICE 'Error message: %', SQLERRM;

        RAISE NOTICE 'SQL state: %', SQLSTATE;

        RAISE NOTICE '================================================';

        RAISE;

END;

$$;
