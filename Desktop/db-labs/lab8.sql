-- Create table: employees
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    salary DECIMAL(10, 2)
 );
-- Create table: departments
 CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
 );-- Create table: projects
 CREATE TABLE projects (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INT,
    budget DECIMAL(10, 2)
 );

-- Insert data into employees
 INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
 (1, 'John Smith', 101, 50000),
 (2, 'Jane Doe', 102, 60000),
 (3, 'Mike Johnson', 101, 55000),
 (4, 'Sarah Williams', 103, 65000),
 (5, 'Tom Brown', NULL, 45000);-- Insert data into departments
 INSERT INTO departments (dept_id, dept_name, location) VALUES
 (101, 'IT', 'Building A'),
 (102, 'HR', 'Building B'),
 (103, 'Finance', 'Building C'),
 (104, 'Marketing', 'Building D');-- Insert data into projects
 INSERT INTO projects (project_id, project_name, dept_id,
budget) VALUES
 (1, 'Website Redesign', 101, 100000),
 (2, 'Employee Training', 102, 50000),
 (3, 'Budget Analysis', 103, 75000),
 (4, 'Cloud Migration', 101, 150000),
 (5, 'AI Research', NULL, 200000);

--PART 2
--2.1
CREATE INDEX emp_salary_idx ON employees(salary);
--2 indexes

--2.2
CREATE INDEX dept_id_idx ON employees(dept_id);
--indexing foreign keys  speeds up  JOIN operations by allowing the database to quickly find related rows without a full table scan.

--2.3
--emp_salary_idx, dept_id_idx and automatically created employees(emp_id), departments(dept_id), projects(project_id

--PART 3
--3.1
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);
--no it will be useless for  a query that only filters by salary because query should start from first column

--3.2
 CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);
--yes the order is matter because if you do not maintain order the postgres can not use the index

--PART 4
--4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
 UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
 UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
 UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
 UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
 UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

 CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
 VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
--ERROR: duplicate key value violates unique constraint "emp_email_unique_idx" DETAIL: Key (email)=(john.smith@company.com) already exists.

--4.2
 ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

  SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
--employees_phone_key,CREATE UNIQUE INDEX employees_phone_key ON public.employees USING btree (phone)

--PART 5
--5.1
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);
 SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
--index help because postgres can read the rows in correcr order without doing additional sorting

--5.2
 CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);
SELECT project_name, budget
FROM projects
ORDER BY budget NULLS FIRST;

--PART 6
--6.1
 CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));
 SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
--Without this index, PostgreSQL would be forced to perform a full sequential table scan, computing LOWER for each row.

--6.2
ALTER TABLE employees ADD COLUMN hire_date DATE;
 UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
 UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
 UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
 UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
 UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

 SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

--PART 7
--7.1
 ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

 SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

--7.2
DROP INDEX emp_salary_dept_idx;
--Multiple indexes covering similar columns

--7.3
 REINDEX INDEX employees_salary_index;

--PART 8
--8.1
 SELECT e.emp_name, e.salary, d.dept_name
 FROM employees e
 JOIN departments d ON e.dept_id = d.dept_id
 WHERE e.salary > 50000
 ORDER BY e.salary DESC;

CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;

--8.2
 CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;

 SELECT project_name, budget
FROM projects
WHERE budget > 80000;
--Partial indexes are smaller and faster because they only index a subset of rows that match a specific condition, reducing storage and maintenance overhead while maintaining performance for targeted queries.

--8.3
 EXPLAIN SELECT * FROM employees WHERE salary > 52000;
--Seq scan

--PART 9
--9.1
 CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);
 SELECT * FROM departments WHERE dept_name = 'IT';
--Use a HASH index only for equality comparisons on large, static tables where you never need range queries

--9.2
 CREATE INDEX proj_name_btree_idx ON projects(project_name);
 CREATE INDEX proj_name_hash_idx ON projects USING HASH (project_name);

 SELECT * FROM projects WHERE project_name = 'Website Redesign';
 SELECT * FROM projects WHERE project_name > 'Database';

--PART 10
--10.1
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
 FROM pg_indexes
 WHERE schemaname = 'public'
 ORDER BY tablename, indexname;
--proj_name_hash_idx,32 kB  AND dept_name_hash_idx,32 kB, THEY ARE LARGER BECAUSE IT IS HASH

--10.2
 DROP INDEX IF EXISTS proj_name_hash_idx;

--10.3
 CREATE VIEW index_documentation AS
 SELECT
    tablename,
    indexname,
    indexdef,
 'Improves salary-based queries' as purpose
 FROM pg_indexes
 WHERE schemaname = 'public'
AND indexname LIKE '%salary%';
 SELECT * FROM index_documentation;
