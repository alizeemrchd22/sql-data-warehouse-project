/*

===============================================================================

DDL Script: Create Silver Tables

===============================================================================

Script Purpose:

    This script defines and creates the table structures used in the

    'silver' schema of the Data Warehouse.

    At this stage, no data cleaning or transformation is performed.

    The script only defines the structure required to store the data that

    will later be cleaned, standardized and loaded from the Bronze layer.

    Compared with the Bronze tables, a technical metadata column called

    'dwh_create_date' is added to each Silver table.

    The 'dwh_create_date' column automatically records the timestamp at which

    each record is created in the Silver layer using CURRENT_TIMESTAMP.

    This provides traceability of when data entered the Silver layer.

    Existing Silver tables are dropped before being recreated to ensure

    that the latest DDL structure is applied.

Warning:

    Running this script will drop the existing Silver tables and therefore

    remove any data currently stored in them.

===============================================================================

*/




-- =============================================================================
-- CRM TABLES
-- =============================================================================

DROP TABLE IF EXISTS silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info (
    cst_id INT,
    cst_key VARCHAR(50),
    cst_firstname VARCHAR(50),
    cst_lastname VARCHAR(50),
    cst_marital_status VARCHAR(50),
    cst_gndr VARCHAR(50),
    cst_create_date DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SELECT table_schema,
       table_name
FROM information_schema.tables
WHERE table_schema = 'silver';


DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id INT,
    cat_id VARCHAR(50),
    prd_key VARCHAR(50),
    prd_nm VARCHAR(255),
    prd_cost NUMERIC(10,2),
    prd_line VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SELECT table_schema,
       table_name
FROM information_schema.tables
WHERE table_schema = 'silver';


DROP TABLE IF EXISTS silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num VARCHAR(20),
    sls_prd_key VARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales NUMERIC(10,2),
    sls_quantity INT,
    sls_price NUMERIC(10,2),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- ERP TABLES
-- =============================================================================

DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id VARCHAR(10),
    cat VARCHAR(50),
    subcat VARCHAR(100),
    maintenance VARCHAR(10),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    cid VARCHAR(20),
    cntry VARCHAR(100),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    cid VARCHAR(20),
    bdate DATE,
    gen VARCHAR(10),
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SELECT table_schema,
       table_name
FROM information_schema.tables
WHERE table_schema = 'silver';
