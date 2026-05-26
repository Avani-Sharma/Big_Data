
/*
database            | integrate_db
storage_integration | s3_integrations
stage               | s3_stage
schema              | iot
table               | json_tbl
file                | iot_events_batch_01.json
file_format         | format_json
*/

-- ====================================
-- iot_events_batch_01 : json file 
-- ====================================

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


-- create schema 
CREATE SCHEMA IF NOT EXISTS iot;
USE SCHEMA iot;


-- Create Stage inside iot schema
CREATE OR REPLACE STAGE s3_stage
    URL = 's3://avani-project/'
    STORAGE_INTEGRATION = s3_integrations;


-- Create File Format for JSON
CREATE OR REPLACE FILE FORMAT integrate_db.iot.format_json
TYPE = 'JSON'
STRIP_OUTER_ARRAY = TRUE;


-- Create Table
CREATE OR REPLACE TABLE integrate_db.iot.json_tbl (
    raw_col VARIANT
);


-- Check File in Stage
LIST @integrate_db.iot.s3_stage;


-- Load JSON Data
COPY INTO integrate_db.iot.json_tbl
FROM @integrate_db.iot.s3_stage/iot_events_batch_01.json
FILE_FORMAT = (FORMAT_NAME = 'integrate_db.iot.format_json');


-- fetch the data
SELECT * FROM integrate_db.iot.json_tbl;


-- Extract JSON Fields
SELECT
    raw_col:event_id::STRING AS event_id,
    raw_col:event_type::STRING AS event_type,
    raw_col:store_id::STRING AS store_id,
    raw_col:store_name::STRING AS store_name,
    raw_col:event_ts::TIMESTAMP_NTZ AS event_ts,
    raw_col:device_id::STRING AS device_id,
    raw_col AS raw_payload,
    CURRENT_TIMESTAMP() AS loaded_at
FROM integrate_db.iot.json_tbl;


-- use lateral flatten to extract nested array data
SELECT
    t.raw_col:event_id::STRING        AS event_id,
    t.raw_col:event_type::STRING      AS event_type,
    t.raw_col:store_id::STRING        AS store_id,
    t.raw_col:store_name::STRING      AS store_name,
    t.raw_col:timestamp::TIMESTAMP_NTZ AS event_ts,
    t.raw_col:device_id::STRING       AS device_id,

    r.value:sensor::STRING            AS sensor_name,
    r.value:value::FLOAT              AS sensor_value,
    r.value:unit::STRING              AS unit,

    a.value:alert_type::STRING        AS alert_type,
    a.value:severity::STRING          AS severity,
    a.value:triggered_at::STRING      AS triggered_at,

    t.raw_col:metadata:firmware::STRING     AS firmware,
    t.raw_col:metadata:battery_pct::INT     AS battery_pct,
    t.raw_col:metadata:signal_rssi::INT     AS signal_rssi,
    t.raw_col:metadata:store_floor::INT     AS store_floor,

    CURRENT_TIMESTAMP() AS loaded_at

FROM integrate_db.iot.json_tbl t,
LATERAL FLATTEN(input => t.raw_col:readings) r,
LATERAL FLATTEN(input => t.raw_col:alerts) a;