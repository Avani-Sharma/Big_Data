/*
database        | clonedb
table           | customer
clone           | customer_clone

temporary table | temp_table
clone           | table_copy

schema          | raj
table           | test 
clone           | raj_trans

database        | companydb
clone           | companydb_clone
*/

-- database 
create database clonedb;
use clonedb;

-- create table 
create table customer(id int, name varchar(20));

-- insert into customer table
insert into customer values (10, 'avani'), (20, 'chinki'), (30, 'nikki');

-- check the data 
select * from customer;



-- create clone
create table customer_clone
clone customer;

-- check data 
select * from customer_clone;
select * from customer;

-- if we insert in customer_clone then changes will not show in customer table 
insert into customer_clone values (40, 'pinki');

select * from customer_clone;
select * from customer;


-- if we update in customer table then changes will not show in customer_clone 
update customer set name = 'regex';

select * from customer_clone;
select * from customer;




-- cloning temporary table possible 
create or replace temporary table temp_table(
  id int
);

-- insert in temporary table
insert into temp_table values (60), (70);

-- temporary clone is temporary but not permanent 
create or replace table table_copy
clone temp_table;



-- schema
create or replace schema raj;

-- create table
create table raj.test (id int);

-- clone schema
create or replace transient schema raj_trans
clone raj;

-- check data 
select * from raj_trans.test;





-- database clone
create or replace database companydb;
use companydb;

-- create table
create table employee(
  id int,
  name varchar(20)
);

-- insert data into table 
insert into employee values
(1, 'rahul'),
(2, 'aman');

-- check data 
select * from employee;

-- create database clone
create or replace database companydb_clone
clone companydb;

-- check cloned database data
select * from companydb_clone.public.employee;






-- Question:
-- Create a table named tests with 2 columns.
-- Insert 3 rows into the table.
-- Create a clone of the table named tests_clone.
-- Update 1 row in the cloned table.
-- Insert 2 new rows into the cloned table.
-- Check data from both original and cloned tables.
-- Apply Time Travel on the cloned table.


-- create table 
create table tests (
  id int,
  age int
);

-- insert the data 
insert into tests values (3, 20), (4, 21), (5, 22);

-- check data 
select * from tests;

-- clone 
create or replace table tests_clone
clone tests;

-- update 1 row in clone table
update tests_clone
set id = 30 where age = 22;

-- check clone data
select * from tests_clone;

-- insert 2 new rows into clone
insert into tests_clone values (7, 25), (8, 34);

-- check clone data 
select * from tests_clone;

-- check original table data
select * from tests;

-- time travel
select * from tests_clone before(offset => -60*1);