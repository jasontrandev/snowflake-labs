# Getting Started with Snowflake

This hands-on practice will help you understand

## What we'll learn:

- How to create stages, databases, tables, views, and virtual warehouses.

- How to load structured and semi-structured data.

- How to consume Cybersyn data from the Snowflake Data Marketplace.

- How to perform analytical queries on data in Snowflake

- How to clone objects.

- How to undo user errors using Time Travel.

- How to create roles and users, and grant them privileges.

- How to securely and easily share data with other accounts

## Module 1: &nbsp; &nbsp; Prepare Your Lab Environment

If you haven't already, register for a Snowflake free 30-day trial. This lab assumes you are using a new Snowflake account created by registering for a trial.

The Snowflake edition (Standard, Enterprise, Business Critical, etc.), cloud provider (AWS, Azure, GCP), and Region (US East, EU, etc.) you use for this lab, do not matter. However, we suggest you select the region that is physically closest to you and Enterprise.

## Module 2: &nbsp; &nbsp; The Snowflake User Interface

First let's walk around with Snowflake! This section covers the basic components of the user interface.

![Snowflake UI](/samples/0-getting-started-with-snowflake/static/module2-00.png)

- **Worksheets** tab: submitting SQL queries, performing DDL and DML operations and viewing results.
- **Data > Databases:** tab: show databases you have created or have permission to access.
- **Monitoring** tab:

## Module 3: &nbsp; &nbsp; Preparing to Load Data

Let’s start by preparing to load the structured data on Cybersyn transactions into Snowflake.

This module will walk you through the steps to:

- Create a database and table
- Create an external stage
- Create a file format for the data

### Create a Database and Table

Ensure you are using the `SYSADMIN` role. Let’s create a database called CYBERSYN for loading the structured data.

```SQL
USE ROLE sysadmin;
CREATE OR REPLACE DATABASE CYBERSYN;
```

![](/samples/0-getting-started-with-snowflake/static/module3-00.png)

Next we create a table called `COMPANY_METADATA`. We use the worksheet to run the DDL that creates the table.

```SQL
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
```

> **Many Options to Run Commands.** SQL commands can be executed through the UI, via the **Worksheets** tab, using our SnowSQL cli, with a SQL editor via ODBC/JDBC, or through our other connectors (Python, Spark, etc.)

### Create an External Stage

```SQL
CREATE STAGE cybersyn_company_metadata
    url = 's3://sfquickstarts/zero_to_snowflake/cybersyn-consumer-company-metadata-csv/';

LIST @cybersyn_company_metadata;
```

### Create a File Format

```SQL
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
```

Verify the file format by using the following command:

```SQL
SHOW FILE FORMATS IN DATABASE
```

## Module 4: &nbsp; &nbsp; Loading Data

### Resize and Use a Warehouse for Data Loading

We will now use a virtual warehouse and the `COPY` command to initiate bulk loading of structured data into Snowflake table we created.

Compute resources are needed for loading data. Snowflake's compute nodes are called virtual warehouses and they can be dynamically sized up or out based on workload. Each workload can have its own warehouse so there is no resource contention.

```SQL
CREATE OR REPLACE WAREHOUSE "CYBERSYN_WH"
COMMENT = ''
WAREHOUSE_SIZE = 'SMALL' AUTO_RESUME = true
AUTO_SUSPEND = 60
MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 1;
```

> If this account isn't using Snowflake Enterprise Edition (or higher), you will not see the **Mode** or **Clusters** options shown in the screenshot below. The multi-cluster warehouses feature is not used in this lab

### Load the Data

Now we can run a COPY command to load the data into the TRIPS table we created earlier.

### Create a New Warehouse for Data Analytics

## Module 5: &nbsp; &nbsp; Analytical Queries, Results Cache, Cloning

### Execute SELECT Statements

### Clone a Table

## Module 6: &nbsp; &nbsp; Roles Based Access Controls and Account Admin

### Create New Role and Add User to it

### Account Administrator View
