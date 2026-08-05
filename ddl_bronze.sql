/*

===============================================================================

DDL Script: Create Bronze Tables

===============================================================================

DDL (Data Definition Language) is the category of SQL commands used to define

and manage the structure of a database. It includes operations such as

CREATE, ALTER, DROP and TRUNCATE.

Script Purpose:

    This script creates all tables in the 'bronze' schema.

    Existing tables are dropped before being recreated to ensure a clean

    development environment.

    This script defines the raw data structure used by the Bronze layer

    of the Data Warehouse.

===============================================================================

*/




-- =============================================================================

-- CRM TABLES

-- =============================================================================

drop table if exists bronze.crm_cust_info

CREATE TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key VARCHAR(50),
    cst_firstname VARCHAR(50),
    cst_lastname VARCHAR(50),
    cst_marital_status VARCHAR(50),
    cst_gndr VARCHAR(50),
    cst_create_date DATE
);

SELECT table_schema,
       table_name
FROM information_schema.tables
WHERE table_schema = 'bronze';

drop table if exists bronze.crm_prd_info

CREATE TABLE bronze.crm_prd_info (
    prd_id INT,
    prd_key VARCHAR(50),
    prd_nm VARCHAR(255),
    prd_cost NUMERIC(10,2),
    prd_line VARCHAR(10),
    prd_start_dt DATE,
    prd_end_dt DATE
);

SELECT table_schema,
       table_name
FROM information_schema.tables
WHERE table_schema = 'bronze';

drop table if exists bronze.crm_sales_details

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num VARCHAR(20),
    sls_prd_key VARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales NUMERIC(10,2),
    sls_quantity INT,
    sls_price NUMERIC(10,2)
);


-- =============================================================================

-- ERP TABLES

-- =============================================================================


drop table if exists bronze.erp_px_cat_g1v2 

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id VARCHAR(10),
    cat VARCHAR(50),
    subcat VARCHAR(100),
    maintenance VARCHAR(10)
);

drop table is exists bronze.erp_loc_a101
CREATE TABLE bronze.erp_loc_a101 (
    cid VARCHAR(20),
    cntry VARCHAR(100)
);

drop table if exists bronze.erp_cust_az12
CREATE TABLE bronze.erp_cust_az12 (
    cid VARCHAR(20),
    bdate DATE,
    gen VARCHAR(10)
);

SELECT table_schema,
       table_name
FROM information_schema.tables
WHERE table_schema = 'bronze';

