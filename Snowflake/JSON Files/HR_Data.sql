/*
Database Name   : regex
Schema Name     : project_data
Stage Name      : aws_ext_stage
AWS S3 Bucket   : avani-bucket-123
Table Name      : hr_data
File            : hr_data.json
*/

-- Create a new database
create or replace database regex;

-- Create schema
create or replace schema regex.project_data;

-- Create external stage and connect Snowflake with AWS S3 bucket
create or replace stage regex.project_data.aws_ext_stage
url='s3://avani-bucket-123'
credentials = (
    aws_key_id='aws_access_key_id',
    aws_secret_key='aws_secret_access_key'
);

-- Check stage details
desc stage regex.project_data.aws_ext_stage;

-- List Files in S3 Bucket
LIST @regex.project_data.aws_ext_stage;

-- Create Table (VARIANT for JSON)
CREATE OR REPLACE TABLE regex.project_data.hr_data (
    raw_col VARIANT
);

-- Check Table Structure
DESCRIBE TABLE regex.project_data.hr_data;

-- Load JSON Data from S3 into Table
COPY INTO regex.project_data.hr_data
FROM @regex.project_data.aws_ext_stage/HR_data.json
FILE_FORMAT = (
    TYPE = 'JSON',
    STRIP_OUTER_ARRAY = TRUE
);

-- View Raw Loaded Data
SELECT * FROM regex.project_data.hr_data;

-- extract the output 
SELECT
    raw_col:id::INT AS id,
    raw_col:first_name::STRING AS first_name,
    raw_col:last_name::STRING AS last_name,
    raw_col:city::STRING AS city,
    raw_col:job.title::STRING AS job_title,
    raw_col:job.salary::INT AS salary
FROM regex.project_data.hr_data;