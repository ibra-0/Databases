CREATE DATABASE advanced_lab
       CREATE TABLE employees(
           emp_id SERIAL PRIMARY KEY,
           first_name VARCHAR(50),
           last_name VARCHAR(50),
           department VARCHAR(50),
           salary INTEGER,
           hire_date DATE,
           status VARCHAR(20) DEFAULT 'Active'
       );

       CREATE TABLE departments(
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    start_date DATE,
    end_date DATE,
    budget INT
    );

INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1, 'John', 'Doe', 'IT');

INSERT INTO employees (first_name, last_name, department, hire_date)
VALUES ('Mary', 'Smith', 'HR','2025-09-29');

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
    ('Alice', 'Brown', 'Finance', 6000, '2024-05-10'),
     ('Bob', 'Taylor', 'Marketing', 55000, '2023-03-15'),
    ('Charlie', 'Johnson', 'IT', 50000, '2022-01-20');

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Eve', 'Williams', 'Research', 50000 * 1.1, CURRENT_DATE);

-- создаем врменную таблицу похожую на employees
CREATE TEMP TABLE temp_employees AS
       SELECT *
       FROM employees
       WHERE 1 = 0;
INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

UPDATE employees
SET salary = salary * 1.10;

UPDATE  employees
SET status = 'Senior'
WHERE salary > 60000
    AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Managment'
WHEN sakary BETWEEN 50000 AND 80000 THEN 'Senior'
ELSE 'Junior'
END;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments d
SET budget = (
    SELECT AVG(e.salary) * 1.2
    FROM employees e
    WHERE e.department = d.depatment_name
    );

UPDATE employees
SET
    salary = salary * 1.5
    status = 'Promoted'
WHERE department = 'Sales';



DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
    AND hire_date > '2023-01-01'
    AND department IS NULL;

DELETE  FROM departments
WHERE dept_id NOT IN(
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
    );

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;



INSERT INTO employees (first_name, last_name, salary, department, hire_date, status)
VALUES ('Ibra', 'Razyyev', NULL, NULL, '2023-09-01', 'Active');

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL
    OR department IS NULL;


--F
INSERT INTO employees(emp_id, first_name, last_name, department, salary, hire_date)
VALUES ('Anna', 'Smirnova', 'Finance', 60000, CURRENT_DATE, 'Active')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;


INSERT INTO employees(emp_id, first_name, last_name, department, salary, hire_date)
SELECT 'Ibra', 'Razyyev', 'IT', 55000, CURRENT_DATE, 'Active'
WHERE NOT EXISTS (
    SELECT 1
    FROM employees
    WHERE first_name = 'Ibra' AND last_name = 'Razyyev'
);


UPDATE employees e
SET salary = salary *
    CASE
        WHEN (SELECT budget FROM departments d WHERE d.department = e.department) > 100000
        THEN 1.10
        ELSE 1.05
    END;

INSERT INTO employees(emp_id, first_name, last_name, department, salary, hire_date)
VALUES
    ('Oleg', 'Sidorov', 'IT', 45000, CURRENT_DATE, 'Active'),
('Maria', 'Kuznetsova', 'HR', 40000, CURRENT_DATE, 'Active'),
('Petr', 'Smirnov', 'Sales', 38000, CURRENT_DATE, 'Active'),
('Anna', 'Volkova', 'Finance', 60000, CURRENT_DATE, 'Active'),
('Dmitry', 'Fedorov', 'IT', 47000, CURRENT_DATE, 'Active');
UPDATE employees
SET salary = salary * 1.10
WHERE hire_date = CURRENT_DATE;


CREATE TABLE employee_archive AS
    SELECT * FROM employees WHERE 1=0;
INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND (
      SELECT COUNT(*)
      FROM employees e
      WHERE e.department = p.department
  ) > 3;
