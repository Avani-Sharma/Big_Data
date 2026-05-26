-- DATABASE CREATION
create database if not exists integrate_db;

-- Use the created database
use database integrate_db;

-- table creation
create or replace table test (
    transaction_id string,
    store_id string,
    store_name string,
    store_city string
);

-- insert data into table
insert into test values 
('abc345', '34g4', 'rani store', 'bhiwadi'),
('defj4',  '23nj3',   'raja store', 'gurgaon'),
('hij678', '56h7', 'sita store', 'delhi');


-- TIME TRAVEL CONCEPTS IN SNOWFLAKE
-- OFFSET BASED TIME TRAVEL
select * from test at (OFFSET => -60*3);   -- 3 minutes ago


-- TIMESTAMP BASED TIME TRAVEL
select  *  from test at (TIMESTAMP => '2026-05-19 17:47:00');


-- BEFORE TIMESTAMP
select *  from test before (TIMESTAMP => DATEADD(MINUTE, -10, CURRENT_TIMESTAMP));


-- CURRENT TIMESTAMP (for reference)
select  CURRENT_TIMESTAMP();


-- STATEMENT BASED TIME TRAVEL : 
-- statement id can be obtained from the query id column of the query history view
select * from test before (STATEMENT => '01c478fc-3202-b595-0017-12fe0005b1ee');