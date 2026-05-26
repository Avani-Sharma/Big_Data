/*
Database Name   : regex
Schema Name     : external_stages_s3 (stage schema)
Table Schema    : reg_tables_s
Table Name      : movie_data
Stage Name      : aws_ext_stage
Source Files    : tags.csv, tags1.csv, tags2.csv, tags3.csv, tags_error.csv

Project Purpose :
Load CSV data from AWS S3 into Snowflake table using
COPY INTO command with multiple scenarios like:
- single file load
- multiple file load
- timestamp conversion
- error handling
*/


-- STEP 1: CREATE DATABASE
create or replace database regex;

-- STEP 2: CREATE SCHEMAS
create or replace schema regex.external_stages_s3;

-- STEP 3: CREATE EXTERNAL STAGE (AWS S3 CONNECTION)
create or replace stage regex.external_stages_s3.aws_ext_stage
url='s3://avani-bucket-123'
credentials = (
    aws_key_id='aws_access_key_id'
    aws_secret_key='aws_secret_access_key'
);

-- STEP 4: CHECK STAGE DETAILS
desc stage regex.external_stages_s3.aws_ext_stage;

-- STEP 5: LIST FILES IN S3 BUCKET
list @regex.external_stages_s3.aws_ext_stage;

-- STEP 6: CREATE schema and TABLE
create or replace schema regex.reg_tables_s;

create or replace table regex.reg_tables_s.movie_data(
    userId NUMBER,
    movieId NUMBER,
    tags STRING,
    date DATE
);

-- STEP 7: CHECK TABLE
select * from regex.reg_tables_s.movie_data;

-- STEP 8: LOAD SINGLE FILE (tags.csv)
copy into regex.reg_tables_s.movie_data
from @regex.external_stages_s3.aws_ext_stage/tags.csv
FILE_FORMAT = (SKIP_HEADER = 1);

-- STEP 9: COUNT ROWS
select count(*) as tags_csv_rows
from regex.reg_tables_s.movie_data;

-- STEP 10: LOAD MULTIPLE FILES
copy into regex.reg_tables_s.movie_data
from @regex.external_stages_s3.aws_ext_stage
files = ('tags1.csv','tags2.csv','tags3.csv')
FILE_FORMAT = (SKIP_HEADER = 1);

-- STEP 11: VIEW DATA
select * from regex.reg_tables_s.movie_data;

-- STEP 12: FINAL COUNT
select count(*) as final_total_rows
from regex.reg_tables_s.movie_data;

-- STEP 13: DATA TRANSFORMATION (TIMESTAMP → DATE)
copy into regex.reg_tables_s.movie_data
from (
    select
        $1::NUMBER,
        $2::NUMBER,
        $3::STRING,
        TO_DATE(TO_TIMESTAMP($4))
    from @regex.external_stages_s3.aws_ext_stage/tags.csv
)
FILE_FORMAT = (SKIP_HEADER = 1);

-- STEP 14: ERROR HANDLING FILE LOAD
copy into regex.reg_tables_s.movie_data
from @regex.external_stages_s3.aws_ext_stage/tags_error.csv
FILE_FORMAT = (SKIP_HEADER = 1);

-- CONTINUE ON ERROR MODE
copy into regex.reg_tables_s.movie_data
from @regex.external_stages_s3.aws_ext_stage/tags_error.csv
FILE_FORMAT = (SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE';

-- FINAL OUTPUT
select * from regex.reg_tables_s.movie_data;