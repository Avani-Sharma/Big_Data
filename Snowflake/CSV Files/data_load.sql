/*
Database Name   : regex
Schema Name     : project_data
Stage Name      : aws_ext_stage
AWS S3 Bucket   : avani-bucket-123
Table Name      : av
*/

-- Step 1: Create a new database
create or replace database regex;

-- Step 2: Create schema
create or replace schema regex.project_data;

-- Step 3: Create external stage and connect Snowflake with AWS S3 bucket
create or replace stage regex.project_data.aws_ext_stage
url='s3://avani-bucket-123'
credentials = (
    aws_key_id='aws key id here'
    aws_secret_key='aws secret key here'
);

-- Step 4: Check stage details
desc stage regex.project_data.aws_ext_stage;

-- Step 5: List files available inside S3 bucket
list @regex.project_data.aws_ext_stage;

-- Step 6: Create table
create or replace table regex.project_data.av(
    year int,
    industry_level varchar(10)
);

-- Step 7: Check table structure
describe table regex.project_data.av;

-- Step 8: View table data (currently empty)
select * from regex.project_data.av;

-- Step 9: Load data from S3 stage into table
copy into regex.project_data.av
from @regex.project_data.aws_ext_stage/data.csv
FILE_FORMAT = (SKIP_HEADER = 1);

-- Step 10: View loaded data
select * from regex.project_data.av;