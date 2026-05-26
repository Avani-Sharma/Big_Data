/*
database = intergrate_db
storage integration = s3_integrations
external stage = s3_stage
file format = format_csv
table = pos_batch_jan
pipe = pos_batch_jan_pipe
*/

-- create database
create database if not exists integrate_db;
use integrate_db;

-- create storage integration 
create STORAGE INTEGRATION s3_integrations
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'aws:role-arn/snowflake_s3_role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://avani-project/');

-- take details  
desc storage integration s3_integrations;

-- external stage 
create or replace stage s3_stage
    url = 's3://avani-project/'
    STORAGE_INTEGRATION = s3_integrations;

-- list
list @s3_stage;

-- FILE FORMAT (csv)
create or replace file format format_csv
type = 'csv'
skip_header =1;

-- TABLE
create or replace table pos_batch_jan (
    transaction_id VARCHAR,
    store_id VARCHAR,
    store_name VARCHAR,
    store_city VARCHAR,
    store_region VARCHAR,
    cashier_id VARCHAR,
    customer_id VARCHAR,
    transaction_date DATE,
    transaction_time TIME,
    product_sku VARCHAR,
    product_name VARCHAR,
    category VARCHAR,
    subcategory VARCHAR,
    quantity INT,
    unit_price FLOAT,
    discount_pct INT,
    total_amount FLOAT,
    payment_method VARCHAR,
    loyalty_points INT
);


-- CHECK FILES IN STAGE
list @s3_stage;


copy into pos_batch_jan
from @s3_stage/avanicsv/
FILE_FORMAT = (FORMAT_NAME = 'format_csv');

-- CHECK DATA
select * from pos_batch_jan; pos_batch_jan;
select count(*) from pos_batch_jan;


-- CREATE PIPE
create or replace pipe pos_batch_jan_pipe
AUTO_INGEST = TRUE
AS
copy into pos_batch_jan
from @s3_stage/avanicsv/
FILE_FORMAT = (FORMAT_NAME = 'format_csv');

-- CHECK PIPE
desc pipe pos_batch_jan_pipe;

-- CHECK STATUS (IMPORTANT)
select SYSTEM$PIPE_STATUS('pos_batch_jan_pipe');

-- CHECK DATA
select * from pos_batch_jan;
select count(*) from pos_batch_jan;