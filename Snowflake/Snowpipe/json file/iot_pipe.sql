/*
-- DATABASE : integrate_db
-- SCHEMA   : iot
-- STAGE    : s3_stage
-- FILE     : iot_events_batch_01.json
-- TABLE    : json_tbl
-- PIPE     : json_tbl_pipe
*/

-- create database
create database if not exists integrate_db;
use integrate_db;

-- create storage integration 
create STORAGE INTEGRATION s3_integrations
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::aws_account_id:role/role_name'
    STORAGE_ALLOWED_LOCATIONS = ('s3://avani-project/');

-- take details  
desc storage integration s3_integrations;

-- external stage 
create or replace stage s3_stage
    url = 's3://avani-project/'
    STORAGE_INTEGRATION = s3_integrations;

-- list
list @s3_stage;


-- CREATE SCHEMA
CREATE SCHEMA IF NOT EXISTS integrate_db.iot;

USE SCHEMA integrate_db.iot;

-- CREATE STAGE
CREATE OR REPLACE STAGE s3_stage
URL = 's3://avani-project/'
STORAGE_INTEGRATION = s3_integrations;

-- FILE FORMAT (JSON)
CREATE OR REPLACE FILE FORMAT format_json
TYPE = 'JSON'
STRIP_OUTER_ARRAY = TRUE;

-- TABLE
CREATE OR REPLACE TABLE json_tbl (
    raw_col VARIANT
);

-- CHECK FILES IN STAGE
LIST @s3_stage;

COPY INTO json_tbl
FROM @s3_stage/avani/
FILE_FORMAT = (FORMAT_NAME = 'format_json');

-- CHECK DATA
SELECT * FROM json_tbl;
select count(*) from json_tbl;




-- CREATE PIPE
CREATE OR REPLACE PIPE json_tbl_pipe
AUTO_INGEST = TRUE
AS
COPY INTO json_tbl
FROM @s3_stage/avani/
FILE_FORMAT = (FORMAT_NAME = 'format_json');

-- CHECK PIPE
DESC PIPE json_tbl_pipe;

-- CHECK STATUS (IMPORTANT)
SELECT SYSTEM$PIPE_STATUS('json_tbl_pipe');

-- CHECK DATA
SELECT * FROM json_tbl;
select count(*) from json_tbl;