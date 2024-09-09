
/*****

Zero to Snowflake

Follow online at: https://quickstarts.snowflake.com/guide/getting_started_with_snowflake

Copyright @2024 Snowflake

******/

/***********

1. Overview

2. Prepare your Lab Environment

3. The Snowflake User Interface and Lab Story

***********/

USE ROLE sysadmin;

/***********

4. Preparing to Load Data

***********/

CREATE OR REPLACE DATABASE CYBERSYN;

USE DATABASE CYBERSYN;

CREATE OR REPLACE TABLE company_metadata
(cybersyn_company_id string,
company_name string,
permid_security_id string,
primary_ticker string,
security_name string,
asset_class string,
primary_exchange_code string,
primary_exchange_name string,
security_status string,
global_tickers variant,
exchange_code variant,
permid_quote_id variant);


CREATE STAGE cybersyn_company_metadata
    url = 's3://sfquickstarts/zero_to_snowflake/cybersyn-consumer-company-metadata-csv/';

    
LIST @cybersyn_company_metadata;

--create file format

CREATE OR REPLACE FILE FORMAT csv
    TYPE = 'CSV'
    COMPRESSION = 'AUTO'  -- Automatically determines the compression of files
    FIELD_DELIMITER = ','  -- Specifies comma as the field delimiter
    RECORD_DELIMITER = '\n'  -- Specifies newline as the record delimiter
    SKIP_HEADER = 1  -- Skip the first line
    FIELD_OPTIONALLY_ENCLOSED_BY = '\042'  -- Fields are optionally enclosed by double quotes (ASCII code 34)
    TRIM_SPACE = FALSE  -- Spaces are not trimmed from fields
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE  -- Does not raise an error if the number of fields in the data file varies
    ESCAPE = 'NONE'  -- No escape character for special character escaping
    ESCAPE_UNENCLOSED_FIELD = '\134'  -- Backslash is the escape character for unenclosed fields
    DATE_FORMAT = 'AUTO'  -- Automatically detects the date format
    TIMESTAMP_FORMAT = 'AUTO'  -- Automatically detects the timestamp format
    NULL_IF = ('')  -- Treats empty strings as NULL values
    COMMENT = 'File format for ingesting data for zero to snowflake';


--verify file format is created

SHOW FILE FORMATS IN DATABASE cybersyn;


/************

5. Loading Data

************/

CREATE OR REPLACE WAREHOUSE "CYBERSYN_WH"
COMMENT = ''
WAREHOUSE_SIZE = 'SMALL' AUTO_RESUME = true
AUTO_SUSPEND = 60
MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 1;

COPY INTO company_metadata FROM @cybersyn_company_metadata file_format=csv PATTERN = '.*csv.*' ON_ERROR = 'CONTINUE';

TRUNCATE TABLE company_metadata;

-- Verify that the table is empty by running the following command:
SELECT * FROM company_metadata LIMIT 10;

-- Change warehouse size from small to large (4x)
ALTER WAREHOUSE cybersyn_wh SET warehouse_size='large';

-- Verify the change using the following SHOW WAREHOUSES:
SHOW WAREHOUSES;

-- Copy data again
COPY INTO company_metadata FROM @cybersyn_company_metadata file_format=csv PATTERN = '.*csv.*' ON_ERROR = 'CONTINUE';

-- After you change the data warehouse size, compare the times of the two COPY INTO commands. The load using the Large warehouse was significantly faster.

/***********

6. Working with Queries, the Results Cache, and Cloning 

***********/

CREATE OR REPLACE WAREHOUSE "ANALYTICS_WH"
COMMENT = ''
WAREHOUSE_SIZE = 'LARGE' AUTO_RESUME = true
AUTO_SUSPEND = 60
MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 1;

SELECT * FROM company_metadata;

SELECT
    meta.primary_ticker,
    meta.company_name,
    ts.date,
    ts.value AS post_market_close,
    (ts.value / LAG(ts.value, 1) OVER (PARTITION BY meta.primary_ticker ORDER BY ts.date))::DOUBLE AS daily_return,
    AVG(ts.value) OVER (PARTITION BY meta.primary_ticker ORDER BY ts.date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS five_day_moving_avg_price
FROM Financial__Economic_Essentials.cybersyn.stock_price_timeseries ts
INNER JOIN company_metadata meta
ON ts.ticker = meta.primary_ticker
WHERE ts.variable_name = 'Post-Market Close';

CREATE TABLE company_metadata_dev CLONE company_metadata;

/***********

7. Working with Roles, Account Admin, and Account Usage

***********/

USE ROLE accountadmin;

CREATE ROLE junior_dba;
GRANT ROLE junior_dba TO USER JASONTRAN;

USE ROLE junior_dba;

USE ROLE accountadmin;

GRANT USAGE ON WAREHOUSE cybersyn_wh TO ROLE junior_dba;

USE ROLE junior_dba;

USE WAREHOUSE cybersyn_wh;

USE ROLE accountadmin;

GRANT USAGE ON DATABASE cybersyn TO ROLE junior_dba;
GRANT IMPORTED PRIVILEGES ON DATABASE Financial__Economic_Essentials TO ROLE junior_dba;

USE ROLE junior_dba;