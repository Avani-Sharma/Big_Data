/*
database  | regex
table     | test1 
task      | task_test
table     | test2
task      | task1
*/

-- 1 ques: 
-- Create a table named test and add a column dob with TIMESTAMP datatype.
-- Then create a task that automatically inserts the current system 
-- date and time into the table. 
-- Use the ALTER TASK SUSPEND command to stop the task.
create database regex;
use database regex;

create or replace table test1 (
    dob timestamp
);

create or replace task task_test
warehouse = compute_wh
schedule = '1 minute'
as
insert into test1
values (current_timestamp());

alter task task_test resume;
select * from test1;
alter task task_test suspend;



-- 2 ques
-- Create a new table and add two columns: status and current_time. 
-- Then create a task using a warehouse that automatically inserts the 
-- value completed and the current system date and time into the table.
create or replace table test2(
    status varchar,
    currenttime timestamp
);

create or replace task task1
warehouse = compute_wh
schedule = '1 minute'
as
insert into test2(status, currenttime)
values ('completed', current_timestamp());

alter task task1 resume;
select * from test2;
alter task task1 suspend;



-- 3 ques: 
-- Create a new table and add a column named file_name. 
-- Then create a task that automatically takes the 
-- file name and inserts it into the table.
create or replace table test_file (
    file_name varchar
);


create or replace stage s3_stage
url='s3://avani-project/'
storage_integration = s3_integrations;


create or replace task file_task
warehouse = compute_wh
schedule = '1 minute'
as
copy into test_file(file_name)
from (
    select metadata$filename
    from @s3_stage
);

alter task file_task resume;
select * from test_file;
alter task file_task suspend;

