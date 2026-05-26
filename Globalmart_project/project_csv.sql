/*
database = intergrate_db
storage integration = s3_integrations
external stage = s3_stage
file format = format_csv
table = pos_batch_jan
pipe = pos_batch_jan_pipe
schema = raw
table = csv_raw
table = stream_csv_raw
schema = staging
table = stg_csv_transaction
*/

-- create database
create database if not exists integrate_db;
use integrate_db;

-- create schema 
create schema if not exists pos_batch;
use schema pos_batch;

-- create storage integration 
create STORAGE INTEGRATION s3_integrations
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::035625951902:role/snowflake_s3_role'
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
create or replace table integrate_db.pos_batch.pos_batch_jan (
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


copy into  integrate_db.pos_batch.pos_batch_jan
from @s3_stage/avanicsv/
FILE_FORMAT = (FORMAT_NAME = 'format_csv');

-- CHECK DATA
select * from  integrate_db.pos_batch.pos_batch_jan;
select count(*) from  integrate_db.pos_batch.pos_batch_jan;


-- CREATE PIPE
create or replace pipe pos_batch_jan_pipe
AUTO_INGEST = TRUE
AS
copy into  integrate_db.pos_batch.pos_batch_jan
from @s3_stage/avanicsv/
FILE_FORMAT = (FORMAT_NAME = 'format_csv');

-- CHECK PIPE
desc pipe pos_batch_jan_pipe;

-- CHECK STATUS (IMPORTANT)
select SYSTEM$PIPE_STATUS('pos_batch_jan_pipe');

-- CHECK DATA
select * from  integrate_db.pos_batch.pos_batch_jan;
select count(*) from  integrate_db.pos_batch.pos_batch_jan;








-- project work
create schema if not exists raw;
use schema raw;

-- external stage 
create or replace stage s3_stage
    url = 's3://avani-project/'
    STORAGE_INTEGRATION = s3_integrations;


-- file format  
create or replace file format format_csv
type = csv
skip_header = 1;

-- table : csv_raw
create or replace table integrate_db.raw.csv_raw (
    transaction_id varchar,
    store_id varchar,
    store_name varchar,
    store_city varchar,
    store_region varchar,
    cashier_id varchar,
    customer_id varchar,
    transaction_date date,
    transaction_time time,
    product_sku varchar,
    product_name varchar,
    category varchar,
    subcategory varchar,
    quantity int,
    unit_price float,
    discount_pct int,
    total_amount float,
    payment_method varchar,
    loyalty_points int,
    load_ts timestamp,
    source_file varchar
);

-- stream 
create or replace stream raw.stream_csv_raw
on table csv_raw
append_only = true;

copy into integrate_db.raw.csv_raw
from (
select
    t.$1, t.$2, t.$3, t.$4, t.$5, t.$6,
    t.$7, t.$8, t.$9, t.$10, t.$11, t.$12,
    t.$13, t.$14, t.$15, t.$16, t.$17, t.$18, t.$19,
    current_timestamp(),
    metadata$filename
from @s3_stage/avanicsv/
(file_format => format_csv) t
);

-- check data
select * from integrate_db.raw.csv_raw;
select * from raw.stream_csv_raw;


-- staging schema 
create schema if not exists staging;
use schema staging;

-- table : stg_csv_transaction
create or replace table integrate_db.staging.stg_csv_transaction (
    transaction_id varchar,
    store_id varchar,
    store_name varchar,
    store_city varchar,
    store_region varchar,
    cashier_id varchar,
    customer_id varchar,
    transaction_ts timestamp,
    product_sku varchar,
    product_name varchar,
    category varchar,
    subcategory varchar,
    quantity int,
    unit_price float,
    discount_pct int,
    line_total float,
    payment_method varchar,
    loyalty_points int,
    processed_ts timestamp
);


insert into staging.stg_csv_transaction
select
    transaction_id,
    store_id,
    store_name,
    store_city,
    store_region,
    cashier_id,
    customer_id,
    to_timestamp(transaction_date || ' ' || transaction_time) as transaction_ts,
    product_sku,
    product_name,
    category,
    subcategory,

     case when quantity > 0 then quantity else 0 end,
    case when unit_price > 0 then unit_price else 0 end,
    case when discount_pct > 0 then discount_pct else 0 end,
    
    (case when quantity > 0 then quantity else 0 end *
     case when unit_price > 0 then unit_price else 0 end)
    -
    (
     (case when quantity > 0 then quantity else 0 end *
      case when unit_price > 0 then unit_price else 0 end)
      *
      case when discount_pct > 0 then discount_pct else 0 end / 100
    )

    case
        when lower(payment_method) = 'credit card' then 'cc'
        when lower(payment_method) = 'debit card' then 'dc'
        else payment_method
    end as payment_method,
    loyalty_points,
    current_timestamp()
from raw.stream_csv_raw;


select * from staging.stg_csv_transaction;

