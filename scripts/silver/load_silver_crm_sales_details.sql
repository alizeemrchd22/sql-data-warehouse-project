/*
===============================================================================
Stored Procedure: Load Silver CRM Sales Details
===============================================================================

Purpose:
    Load cleaned and standardized sales data from the Bronze layer into
    silver.crm_sales_details.

Transformations:

    - Remove leading and trailing spaces from order numbers and product keys.

    - Convert integer dates stored as YYYYMMDD into PostgreSQL DATE values.

    - Replace invalid date values with NULL:
        * value = 0
        * value does not contain exactly 8 digits

    - Standardize product prices:
        * NULL or zero price -> calculate Sales / Quantity
        * negative price -> convert to positive using ABS()

    - Standardize sales amounts:
        * NULL, zero or negative sales -> recalculate Quantity × Price
        * inconsistent sales -> recalculate Quantity × Price

    - Keep quantity unchanged.

    - Automatically populate dwh_create_date using the Silver table default.

Source:
    bronze.crm_sales_details

Target:
    silver.crm_sales_details

Warning:
    TRUNCATE removes all rows from the Silver target table before reload.

===============================================================================
*/


CREATE OR REPLACE PROCEDURE silver.load_crm_sales_details()

LANGUAGE plpgsql

AS $$

DECLARE

    start_time TIMESTAMP;
    end_time TIMESTAMP;
    rows_loaded INTEGER;

BEGIN

    start_time := clock_timestamp();


    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer - CRM Sales Details';
    RAISE NOTICE '================================================';


    ---------------------------------------------------------------------------
    -- Clear Silver table
    ---------------------------------------------------------------------------

    RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';

    TRUNCATE TABLE silver.crm_sales_details;


    RAISE NOTICE '>> Transforming and loading sales data';


    ---------------------------------------------------------------------------
    -- STEP 1:
    -- Clean text, convert dates and calculate a valid product price
    ---------------------------------------------------------------------------

    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )

    WITH cleaned_sales AS (

        SELECT

            -------------------------------------------------------------------
            -- Remove unwanted spaces
            -------------------------------------------------------------------

            TRIM(sls_ord_num) AS sls_ord_num,

            TRIM(sls_prd_key) AS sls_prd_key,

            sls_cust_id,


            -------------------------------------------------------------------
            -- ORDER DATE
            --
            -- Bronze stores dates as INTEGER YYYYMMDD.
            -- Invalid values are converted to NULL.
            -------------------------------------------------------------------

            CASE
                WHEN sls_order_dt IS NULL
                  OR sls_order_dt = 0
                  OR LENGTH(sls_order_dt::TEXT) <> 8
                THEN NULL

                ELSE TO_DATE(
                    sls_order_dt::TEXT,
                    'YYYYMMDD'
                )::DATE

            END AS sls_order_dt,


            -------------------------------------------------------------------
            -- SHIPPING DATE
            -------------------------------------------------------------------

            CASE
                WHEN sls_ship_dt IS NULL
                  OR sls_ship_dt = 0
                  OR LENGTH(sls_ship_dt::TEXT) <> 8
                THEN NULL

                ELSE TO_DATE(
                    sls_ship_dt::TEXT,
                    'YYYYMMDD'
                )::DATE

            END AS sls_ship_dt,


            -------------------------------------------------------------------
            -- DUE DATE
            -------------------------------------------------------------------

            CASE
                WHEN sls_due_dt IS NULL
                  OR sls_due_dt = 0
                  OR LENGTH(sls_due_dt::TEXT) <> 8
                THEN NULL

                ELSE TO_DATE(
                    sls_due_dt::TEXT,
                    'YYYYMMDD'
                )::DATE

            END AS sls_due_dt,


            -------------------------------------------------------------------
            -- Keep original sales temporarily
            -------------------------------------------------------------------

            sls_sales,

            sls_quantity,


            -------------------------------------------------------------------
            -- PRICE CLEANING
            --
            -- NULL / zero:
            --     calculate Sales / Quantity
            --
            -- Negative:
            --     convert to positive
            -------------------------------------------------------------------

            CASE

                WHEN sls_price IS NULL
                  OR sls_price = 0

                THEN
                    CASE
                        WHEN sls_quantity IS NOT NULL
                         AND sls_quantity <> 0
                         AND sls_sales IS NOT NULL

                        THEN ABS(
                            sls_sales::NUMERIC
                            / sls_quantity
                        )

                        ELSE NULL
                    END

                ELSE ABS(sls_price)

            END AS cleaned_price


        FROM bronze.crm_sales_details
    )


    ---------------------------------------------------------------------------
    -- STEP 2:
    -- Use the cleaned price to calculate the final sales amount
    ---------------------------------------------------------------------------

    SELECT

        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,


        -----------------------------------------------------------------------
        -- SALES CLEANING
        --
        -- Recalculate sales if:
        --   - NULL
        --   - zero
        --   - negative
        --   - inconsistent with Quantity × Price
        -----------------------------------------------------------------------

        CASE

            WHEN sls_sales IS NULL
              OR sls_sales <= 0
              OR sls_sales <> sls_quantity * cleaned_price

            THEN sls_quantity * cleaned_price

            ELSE sls_sales

        END::NUMERIC(10,2) AS sls_sales,


        sls_quantity,


        -----------------------------------------------------------------------
        -- Store cleaned positive price
        -----------------------------------------------------------------------

        cleaned_price::NUMERIC(10,2) AS sls_price


    FROM cleaned_sales;


    ---------------------------------------------------------------------------
    -- Capture number of inserted rows
    ---------------------------------------------------------------------------

    GET DIAGNOSTICS rows_loaded = ROW_COUNT;


    end_time := clock_timestamp();


    RAISE NOTICE '>> Rows Loaded: %', rows_loaded;

    RAISE NOTICE '>> Load Duration: % seconds',
        ROUND(
            EXTRACT(EPOCH FROM (end_time - start_time))::NUMERIC,
            3
        );


    RAISE NOTICE '================================================';
    RAISE NOTICE 'CRM Sales Details loading completed';
    RAISE NOTICE '================================================';


EXCEPTION

    WHEN OTHERS THEN

        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR DURING CRM SALES SILVER LOAD';
        RAISE NOTICE 'Error message: %', SQLERRM;
        RAISE NOTICE 'SQL state: %', SQLSTATE;
        RAISE NOTICE '================================================';

        RAISE;

END;

$$;
