/*

===============================================================================

Create Database Schemas

===============================================================================

Script Purpose:

    This script initializes the Data Warehouse by creating the three

    main schemas used in the Medallion Architecture:

    - bronze : Raw data imported from source systems.

    - silver : Cleaned and transformed data.

    - gold   : Business-ready analytical tables.

Notes:

    - This script is intended for PostgreSQL.

    - Schemas are created only if they do not already exist.

    - Safe to execute multiple times thanks to IF NOT EXISTS.

===============================================================================

*/


SELECT datname
FROM pg_database
WHERE datname = 'datawarehouse';

CREATE SCHEMA IF NOT EXISTS bronze;

CREATE SCHEMA IF NOT EXISTS silver;

CREATE SCHEMA IF NOT EXISTS gold;

SELECT schema_name
FROM information_schema.schemata
ORDER BY schema_name;
