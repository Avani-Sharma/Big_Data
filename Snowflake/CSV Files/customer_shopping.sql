-- STEP 1: CREATE DATABASE
create or replace database regex;

-- STEP 2: CREATE SCHEMAS
create or replace schema regex.external_stages_s3;

-- STEP 3: CREATE EXTERNAL STAGE (AWS S3 CONNECTION)
create or replace stage regex.external_stages_s3.aws_ext_stage
url='s3://avani-bucket-123'
credentials = (
    aws_key_id='AKIAQCMK'
    aws_secret_key='xv9J/revBUlASppEY61jU0Z'
);

-- STEP 4: CHECK STAGE DETAILS
desc stage regex.external_stages_s3.aws_ext_stage;

-- STEP 5: LIST FILES IN S3 BUCKET
list @regex.external_stages_s3.aws_ext_stage;



-- ====================================
-- customer_shopping_data : csv file 
-- ====================================

-- create schema for csv file 
create schema if not exists customer_db.data;

-- create table
create or replace table customer_db.data.customer_shopping (
    invoice_no VARCHAR,
    customer_id VARCHAR,
    gender VARCHAR,
    age INT,
    category VARCHAR,
    quantity INT,
    price FLOAT,
    payment_method VARCHAR,
    invoice_date VARCHAR,
    shopping_mall VARCHAR
);

-- copy data 
copy into customer_db.data.customer_shopping
from @s3_stage/customer_shopping_data.csv
file_format = (skip_header = 1);

-- fetch the data 
select * from customer_db.data.customer_shopping;