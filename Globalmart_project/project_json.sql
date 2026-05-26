/*
database               | integrate_db
schema                 | iot
storage integration    | s3_integrations
external stage         | s3_stage
file format            | format_json
table                  | json_tbl
pipe                   | json_tbl_pipe
schema raw             | raw
file format raw        | format_json
external stage raw     | s3_stage
table raw              | json_raw
stream raw             | stream_json_raw
schema staging         | staging
staging table          | stg_json_sensor
*/
-- create database 
create database if not exists integrate_db;
use database integrate_db;

-- schema 
create schema if not exists integrate_db.iot;
use schema integrate_db.iot;

-- storage integration
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

-- files in stage 
list @s3_stage;

-- file format 
create or replace file format format_json
type = json
strip_outer_array = true;


-- table 
create or replace table iot.json_tbl(
    raw_col VARIANT
);

-- Check File in Stage
LIST @integrate_db.iot.s3_stage;


-- Load JSON Data
copy into integrate_db.iot.json_tbl
from @integrate_db.iot.s3_stage/avanijson/
FILE_FORMAT = (FORMAT_NAME = 'integrate_db.iot.format_json');

-- fetch the data
select * from integrate_db.iot.json_tbl;

-- Extract JSON Fields
select 
    raw_col:event_id::STRING AS event_id,
    raw_col:event_type::STRING AS event_type,
    raw_col:store_id::STRING AS store_id,
    raw_col:store_name::STRING AS store_name,
    raw_col:event_ts::TIMESTAMP_NTZ AS event_ts,
    raw_col:device_id::STRING AS device_id,
    raw_col AS raw_payload,
    CURRENT_TIMESTAMP() AS loaded_at
from integrate_db.iot.json_tbl;


-- use lateral flatten to extract nested array data
select 
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

from integrate_db.iot.json_tbl t,
LATERAL FLATTEN(input => t.raw_col:readings) r,
LATERAL FLATTEN(input => t.raw_col:alerts) a;



-- check data 
select * from integrate_db.iot.json_tbl;
select count(*) from integrate_db.iot.json_tbl;



-- create pipe 
create or replace pipe json_tbl_pipe
AUTO_INGEST = TRUE
AS
copy into json_tbl
from @s3_stage/avanijson/
FILE_FORMAT = (FORMAT_NAME = 'format_json');

-- check pipe
desc pipe json_tbl_pipe;

-- check status 
select SYSTEM$PIPE_STATUS('json_tbl_pipe');

-- check data 
select * from integrate_db.iot.json_tbl;
select count(*) from integrate_db.iot.json_tbl;





-- project work
-- schema raw 
create schema if not exists integrate_db.raw;
use schema integrate_db.raw;

-- file format
create or replace file format integrate_db.raw.format_json
TYPE = JSON
STRIP_OUTER_ARRAY = TRUE;

-- external stage
create or replace stage integrate_db.raw.s3_stage
URL = 's3://avani-project/'
STORAGE_INTEGRATION = s3_integrations;

-- table 
create or replace table integrate_db.raw.json_raw (
    event_id varchar,
    event_type varchar,
    store_id varchar,
    store_name varchar,
    event_ts  timestamp,
    device_id  varchar,
    raw_payload  VARIANT,
    load_ts timestamp,
    source_file varchar
);

-- Data load 
copy into integrate_db.raw.json_raw
from (
select 
        $1:event_id::varchar,
        $1:event_type::varchar,
        $1:store_id::varchar,
        $1:store_name::varchar,
        $1:timestamp::timestamp,
        $1:device_id::varchar,
        $1,
        CURRENT_TIMESTAMP(),
        METADATA$FILENAME
from @integrate_db.raw.s3_stage/avanijson/
(FILE_FORMAT => integrate_db.raw.format_json)
);

-- fetch the data
select * from integrate_db.raw.json_raw;


-- append only stream
create or replace stream integrate_db.raw.stream_json_raw
on table integrate_db.raw.json_raw
APPEND_ONLY = TRUE;

-- check stream : it is empty 
select * from integrate_db.raw.stream_json_raw;


-- staging schema
create schema if not exists integrate_db.staging;
use schema integrate_db.staging;

-- table : stg_json_sensor
create or replace table integrate_db.staging.stg_json_sensor (
    event_id varchar,
    event_type varchar,
    store_id varchar,
    store_name varchar,
    event_ts timestamp,
    device_id varchar,
    firmware varchar,
    battery_pct int,
    store_floor int,
    sensor_name varchar,
    sensor_value float,
    sensor_unit varchar,
    processed_ts  timestamp
);


select
    s.raw_payload:event_id::varchar as event_id,
    s.raw_payload:event_type::varchar as event_type,
    s.raw_payload:store_id::varchar as store_id,
    s.raw_payload:store_name::varchar as store_name,
    s.raw_payload:timestamp::timestamp as event_ts,
    s.raw_payload:device_id::varchar as device_id,
    s.raw_payload:metadata:firmware::varchar as firmware,
    s.raw_payload:metadata:battery_pct::int as battery_pct,
    s.raw_payload:metadata:store_floor::int as store_floor,
    f.value:sensor::varchar as sensor_name,
    f.value:value::float as sensor_value,
    f.value:unit::varchar as sensor_unit,
    current_timestamp() as processed_ts
from integrate_db.raw.stream_json_raw as s,
lateral flatten(input => s.raw_payload:sensors) as f;


-- staging into stream
insert into integrate_db.staging.stg_json_sensor
select
    s.raw_payload:event_id::varchar as event_id,
    s.raw_payload:event_type::varchar as event_type,
    s.raw_payload:store_id::varchar as store_id,
    s.raw_payload:store_name::varchar as store_name,
    s.raw_payload:timestamp::timestamp as event_ts,
    s.raw_payload:device_id::varchar as device_id,
    s.raw_payload:metadata:firmware::varchar as firmware,
    s.raw_payload:metadata:battery_pct::int as battery_pct,
    s.raw_payload:metadata:store_floor::int as store_floor,
    f.value:sensor::varchar as sensor_name,
    f.value:value::float as sensor_value,
    f.value:unit::varchar as sensor_unit,
    current_timestamp() as processed_ts
from integrate_db.raw.stream_json_raw as s,
lateral flatten(input => s.raw_payload:sensors) as f;

-- check data 
select * from integrate_db.raw.json_raw;
select * from integrate_db.raw.stream_json_raw;       
select * from integrate_db.staging.stg_json_sensor;


-- upload new file 
copy into integrate_db.raw.json_raw
from (
select 
        $1:event_id::varchar,
        $1:event_type::varchar,
        $1:store_id::varchar,
        $1:store_name::varchar,
        $1:timestamp::timestamp,
        $1:device_id::varchar,
        $1,
        CURRENT_TIMESTAMP(),
        METADATA$FILENAME
    from @integrate_db.raw.s3_stage/avanijson/
    (FILE_FORMAT => integrate_db.raw.format_json)
);

-- new file in stream
select * from integrate_db.raw.stream_json_raw;

-- insert in staging
insert into integrate_db.staging.stg_json_sensor
select
    s.raw_payload:event_id::varchar as event_id,
    s.raw_payload:event_type::varchar as event_type,
    s.raw_payload:store_id::varchar as store_id,
    s.raw_payload:store_name::varchar as store_name,
    s.raw_payload:timestamp::timestamp as event_ts,
    s.raw_payload:device_id::varchar as device_id,
    s.raw_payload:metadata:firmware::varchar as firmware,
    s.raw_payload:metadata:battery_pct::int as battery_pct,
    s.raw_payload:metadata:store_floor::int as store_floor,
    f.value:sensor::varchar as sensor_name,
    f.value:value::float as sensor_value,
    f.value:unit::varchar as sensor_unit,
    current_timestamp() as processed_ts
from integrate_db.raw.stream_json_raw as s,
lateral flatten(input => s.raw_payload:sensors) as f;
    
    
select * from integrate_db.staging.stg_json_sensor;
