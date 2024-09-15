# Getting Started with Snowflake

This hands-on lab will help you navigate the Snowflake interface and introduce you to some of our core capabilities. Once you cover the basics, you'll be ready to start processing your own data and diving into Snowflake's more advanced features!

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

If you haven't already, register for a [Snowflake free 30-day trial](https://signup.snowflake.com/developers). This lab assumes you are using a new Snowflake account created by registering for a trial.

The Snowflake edition (Standard, Enterprise, Business Critical, etc.), cloud provider (AWS, Azure, GCP), and Region (US East, EU, etc.) you use for this lab, do not matter. However, we suggest you select the region that is physically closest to you and Enterprise.

## Module 2: &nbsp; &nbsp; The Snowflake User Interface

First let's walk around with Snowflake! This section covers the basic components of the user interface.

![Snowflake UI](/samples/0-getting-started-with-snowflake/static/module2-00.png)

- **Worksheets** tab: submitting SQL queries, performing DDL and DML operations and viewing results.
- **Data > Databases:** tab: show databases you have created or have permission to access.
- **Monitoring** tab: there are multiple tabs for tracking your usage of your Snowflake account
  ![Snowflake UI](/samples/0-getting-started-with-snowflake/static/module2-01.png)

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
```

Or we can use UI to create a stage in the screenshot below

![](/samples/0-getting-started-with-snowflake/static/module3-01.png)

> The S3 bucket for this lab is public so you can leave the credentials options in the statement empty. In a real-world scenario, the bucket used for an external stage would likely require key information.

Add the following SQL statement below the previous code and then execute:

```SQL
LIST @cybersyn_company_metadata;
```

You should see the list of files in the stage:

![](/samples/0-getting-started-with-snowflake/static/module3-02.png)

### Create a File Format

Before we can load the data into Snowflake, we have to create a file format that matches the data structure. Add the following command below and execute it:

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

For this module, we will use a virtual data warehouse and the `COPY` command to initiate bulk loading of structured data into the Snowflake table we just created.

### Resize and Use a Warehouse for Data Loading

Compute resources are needed for loading data. Snowflake's compute nodes are called virtual warehouses and they can be dynamically sized up or out based on workload. Each workload can have its own warehouse so there is no resource contention.

```SQL
CREATE OR REPLACE WAREHOUSE "CYBERSYN_WH"
COMMENT = ''
WAREHOUSE_SIZE = 'SMALL' AUTO_RESUME = true
AUTO_SUSPEND = 60
MIN_CLUSTER_COUNT = 1 MAX_CLUSTER_COUNT = 1;
```

> If this account isn't using Snowflake Enterprise Edition (or higher), you will not see the **Mode** or **Clusters** options shown in the screenshot below. The multi-cluster warehouses feature is not used in this lab

![](/samples/0-getting-started-with-snowflake/static/module4-00.png)

### Load the Data

Now we can run a COPY command to load the data into the `COMPANY_METADATA` table we created earlier.

&nbsp; &nbsp; &nbsp; **Role:** SYSADMIN <br>
&nbsp; &nbsp; &nbsp; **Warehouse:** CYBERSYN_WH <br>
&nbsp; &nbsp; &nbsp; **Database:** CYBERSYN <br>
&nbsp; &nbsp; &nbsp; **Schema:** PUBLIC

Execute the following statements in the worksheet to load the staged data into the table.

```SQL
COPY INTO company_metadata FROM @cybersyn_company_metadata file_format=csv PATTERN = '.*csv.*' ON_ERROR = 'CONTINUE';
```

In the result pane, you should see the status of each file that was loaded.

![](/samples/0-getting-started-with-snowflake/static/module4-01.png)

> If you reload the `COMPANY_METADATA` table with a larger warehouse e.g. `Small` to `Large`, the time load using the `Large` warehouse was significantly faster.

### Create a New Warehouse for Data Analytics

Let's assume our internal analytics team wants to eliminate resource contention between their data loading/ETL workloads and the analytical end users using BI tools to query Snowflake. As mentioned earlier, Snowflake can easily do this by assigning different, appropriately-sized warehouses to various workloads. Since our company already has a warehouse for data loading, let's create a new warehouse for the end users running analytics. We will use this warehouse to perform analytics in the next section.

Navigate to the **Admin > Warehouses** tab, click **+ Warehouse**, and name the new warehouse and set the size to `Large`.

![](/samples/0-getting-started-with-snowflake/static/module4-02.png)

## Module 5: &nbsp; &nbsp; Analytical Queries, Results Cache, Cloning

In the previous exercises, we loaded data into two tables using Snowflake's `COPY` bulk loader command and the `CYBERSYN_WH` virtual warehouse. Now we are going to take on the role of the analytics users at our company who need to query data in those tables using the worksheet and the second warehouse `ANALYTICS_WH`.

> **Real World Roles and Querying** Within a real company, analytics users would likely have a different role than SYSADMIN. To keep the lab simple, we are going to stay with the SYSADMIN role for this module. Additionally, querying would typically be done with a business intelligence product like Tableau, Looker, PowerBI, etc.

### Execute Some Queries

Go to the Worksheets tab. Within the worksheet, make sure you set your context appropriately:

&nbsp; &nbsp; &nbsp; **Role:** SYSADMIN <br>
&nbsp; &nbsp; &nbsp; **Warehouse:** ANALYTICS_WH (L) <br>
&nbsp; &nbsp; &nbsp; **Database:** CYBERSYN <br>
&nbsp; &nbsp; &nbsp; **Schema:** PUBLIC

![](/samples/0-getting-started-with-snowflake/static/module5-00.png)

Now, let's look at the performance of these companies in the stock market. Run the queries below in the worksheet.

**Closing Price Statistics:** First, calculate the daily return of a stock (the percent change in the stock price from the close of the previous day to the close of the current day) and 5-day moving average from closing prices (which helps smooth out daily price fluctuations to identify trends).

```SQL
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
```

**Trading Volume Statistics:** Then, calculate the trading volume change from one day to the next to see if there's an increase or decrease in trading activity. This can be a sign of increasing or decreasing interest in a stock.

```SQL
SELECT
    meta.primary_ticker,
    meta.company_name,
    ts.date,
    ts.value AS nasdaq_volume,
    (ts.value / LAG(ts.value, 1) OVER (PARTITION BY meta.primary_ticker ORDER BY ts.date))::DOUBLE AS volume_change
FROM cybersyn.stock_price_timeseries ts
INNER JOIN company_metadata meta
ON ts.ticker = meta.primary_ticker
WHERE ts.variable_name = 'Nasdaq Volume';
```

### Use the Result Cache

Snowflake has a result cache that holds the results of every query executed in the past 24. These are available across warehouses, so query results returned to one user are available to any other user on the system who executes the same query, provided the underlying data has not changed.

Let's see the result cache in action by running the exact same query above again.

![](/samples/0-getting-started-with-snowflake/static/module5-01.png)

### Clone a Table

Snowflake allows you to create clones, also known as "zero-copy clones" of tables, schemas, and databases in seconds. When a clone is created, Snowflake takes a snapshot of data present in the source object. The cloned object is writable and independent of the clone source. Therefore, changes made to either the source object or the clone object are not included in the other.

_A popular use case for zero-copy cloning is to clone a production environment for use by Development & Testing teams to test and experiment without impacting the production environment and eliminating the need to set up and manage two separate environments._

Run the following command in the worksheet to create a development (dev) table clone of the `company_metadata` table:

```SQL
CREATE TABLE company_metadata_dev CLONE company_metadata;
```

You will see a new table named `company_metadata_dev`. Your Development team now can do whatever they want with this table, including updating or deleting it, without impacting the `company_metadata` table or any other object.

![](/samples/0-getting-started-with-snowflake/static/module5-02.png)

## Module 6: &nbsp; &nbsp; Roles Based Access Controls and Account Admin

In this section, we will explore of Snowflake's access control security model, such as creating a role and granting it specific permissions

Continuing with the lab story, let's assume a junior DBA has joined our internal analytics team, and we want to create a new role for them with less privileges than the system-defined, default role of `SYSADMIN`.

### Create New Role and Add User

In the `ZERO_TO_SNOWFLAKE_WITH_CYBERSYN` worksheet, switch to the `ACCOUNTADMIN` role to create a new role. `ACCOUNTADMIN` encapsulates the `SYSADMIN` and `SECURITYADMIN` system-defined roles. It is the top-level role in the account and should be granted only to a limited number of users.

```SQL
USE ROLE accountadmin;
```

Notice that, in the top right of the worksheet, the context has changed to `ACCOUNTADMIN`:

![](/samples/0-getting-started-with-snowflake/static/module6-00.png)

Use the following commands to create a new role named `JUNIOR_DBA` and assign it to your Snowflake user.

```SQL
CREATE ROLE junior_dba;
GRANT ROLE junior_dba TO USER JASONTRAN;
```

> If you try to perform this operation while in a role such as SYSADMIN, it would fail due to insufficient privileges.

Change your worksheet context to the new JUNIOR_DBA role:

```SQL
USE ROLE junior_dba;
```

Switching back to `ACCOUNTADMIN` role and grant usage privileges to `CYBERSYN_WH` warehouse.

```SQL
USE ROLE accountadmin;
GRANT USAGE ON WAREHOUSE cybersyn_wh TO ROLE junior_dba;
```

Finally, you can notice that `CYBERSYN` database no longer appear in the database object browser. This is because the JUNIOR_DBA role does not have privileges to access them.

Grant the `JUNIOR_DBA` the USAGE privilege required to view and use the `CYBERSYN` database.

```SQL
USE ROLE accountadmin;
GRANT USAGE ON DATABASE cybersyn TO ROLE junior_dba;
```

Notice that the CYBERSYN database now appear in the database object browser on the left.

![](/samples/0-getting-started-with-snowflake/static/module6-01.png)

### Account Administrator UI

Let's change our access control role back to ACCOUNTADMIN to see other areas of the UI accessible only to this role. Once you switch the UI session to the `ACCOUNTADMIN` role, new tabs are available under **Admin**.

![](/samples/0-getting-started-with-snowflake/static/module6-02.png)
