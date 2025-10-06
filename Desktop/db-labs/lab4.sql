-- Create tables
 CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary NUMERIC(10,2),
    hire_date DATE,
    manager_id INTEGER,
    email VARCHAR(100)
 );
 CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    budget NUMERIC(12,2),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20)
 );
 CREATE TABLE assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees(employee_id),
    project_id INTEGER REFERENCES projects(project_id),
    hours_worked NUMERIC(5,1),
    assignment_date DATE
 );
-- Insert sample data
 INSERT INTO employees (first_name, last_name, department,
salary, hire_date, manager_id, email) VALUES
 ('John', 'Smith', 'IT', 75000, '2020-01-15', NULL,
'john.smith@company.com'),
 ('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1,
'sarah.j@company.com'),
 ('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL,
'mbrown@company.com'),
 ('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL,
'emily.davis@company.com'),
 ('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
 ('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3,
'lisa.a@company.com');
 INSERT INTO projects (project_name, budget, start_date,
end_date, status) VALUES
 ('Website Redesign', 150000, '2024-01-01', '2024-06-30',
'Active'),
 ('CRM Implementation', 200000, '2024-02-15', '2024-12-31',
'Active'),
 ('Marketing Campaign', 80000, '2024-03-01', '2024-05-31',
'Completed'),
 ('Database Migration', 120000, '2024-01-10', NULL, 'Active');
 INSERT INTO assignments (employee_id, project_id,
hours_worked, assignment_date) VALUES
 (1, 1, 120.5, '2024-01-15'),
 (2, 1, 95.0, '2024-01-20'),
 (1, 4, 80.0, '2024-02-01'),
 (3, 3, 60.0, '2024-03-05'),
 (5, 2, 110.0, '2024-02-20'),
 (6, 3, 75.5, '2024-03-10');
-- Part 1
-- Task 1.1
SELECT
    employees.first_name|| ' ' || employees.last_name AS full_name,
    employees.department,
    employees.salary
FROM employees;
--Task 1.2
SELECT DISTINCT department
FROM employees;
--Task 1.3
SELECT
    projects.project_name,
    projects.budget,
    CASE
        WHEN projects.budget > 150000 THEN 'Large'
        WHEN projects.budget BETWEEN 100000 AND 150000 THEN 'Medium'
        ELSE 'Small'
        END AS budget_category
FROM projects;

-- Task 1.4
SELECT
    employees.first_name || ' ' || employees.last_name AS full_name,
    COALESCE(employees.email, 'No email provided') AS email
FROM employees;
-- Part 2
-- Task 2.1
SELECT
    first_name,
    last_name,
    hire_date
FROM employees
WHERE hire_date > '2020-01-01';

--Task 2.2
SELECT
    first_name,
    last_name,
    hire_date
FROM employees
WHERE salary BETWEEN 60000 AND 70000;

--Task 2.3
SELECT
      first_name,
    last_name
FROM employees
WHERE last_name LIKE 'S%' OR last_name LIKE 'J%';

--Task 2.4
SELECT
    employees.first_name,
    employees.last_name,
    employees.department,
    employees.manager_id
FROM employees
WHERE manager_id IS NOT NULL
    AND department = 'IT';

--Part 3
--Task 3.1
SELECT
    UPPER(employees.first_name || ' ' || employees.last_name) AS full_name_upper,
    LENGTH(employees.last_name) AS last_name_length,
    SUBSTRING(email FROM 1 FOR 3) AS email_prefix
FROM employees;

-- Task 3.2
SELECT
    employees.first_name,
    employees.last_name,
    employees.salary * 12 AS annual_salary,
    ROUND(employees.salary, 2) AS monthly_salary,
    ROUND(employees.salary * 0.10, 2) AS raise_amount
FROM employees;

--Task 3.3
SELECT
    FORMAT('Project: %s - Budget: $%s - Status: %s',
    projects.project_name, projects.budget, projects.status) AS project_info
FROM projects;

--Task 3.4
SELECT
    employees.first_name,
    employees.last_name,
    employees.hire_date
    ROUND(EXTRACT(YEAR FROM AGE(CURRENT_DATE, employees.hire_date)), 2) AS years_with_company
FROM employees;

--Part 4
--Task 4.1
SELECT
    employees.department,
    ROUND(AVG(employees.salary), 2) AS avg_salary
FROM employees
GROUP BY department;

--Task 4.2
SELECT
    p.project_name
    SUM(a.hourse_worked) AS total_hours
FROM assingments a
JOIN projects p ON a.project_id = p.project_id
GROUP BY p.project_name;

--Task 4.3
SELECT
    employees.department,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

--Task 4.4
SELECT
    MAX(employees.salary) AS max_salary,
    MIN(employees.salary) AS min_salary,
    SUM(employees.salary) AS total_payroll
FROM employees;

--Part 5
--Task 5.1
SELECT
    employees.employee_id,
    employees.first_name, || ' ' ||  employees.last_name AS full_name,
    employees.salary,
FROM employees
WHERE salary > 65000

UNION

SELECT
    employees.employee_id,
    employees.first_name, || ' ' ||  employees.last_name AS full_name,
    employees.salary,
FROM employees
WHERE hire_date > '2020-01-01';

--Task 5.2
SELECT employees.employee_id, employees.first_name, employees.last_name, employees.department, employees.salary
FROM employees
WHERE department = 'IT'

INTERSECT

SELECT employees.employee_id, employees.first_name, employees.last_name, employees.department, employees.salary
FROM employees
WHERE salary > 65000;

--Task 5.3
SELECT employees.employee_id, employees.first_name, employees.last_name
FROM employees

EXCEPT

SELECT DISTINCT employees.employee_id, employees.first_name, employees.last_name
FROM employees e
JOIN assignments a ON a.employee_id = e.employee_id = a.employee_id;

--PART 6
--Task 6.1
SELECT employees.employee_id, e.first_name, e.last_name
FROM employees e
WHERE EXISTS(
    SELECT 1
    FROM assignments a
    WHERE a.employee_id = e.employee_id
);

--Tak 6.2
SELECT employees.employee_id, employees.first_name, employees.last_name, department
FROM employees e
WHERE employee_id IN (
    SELECT a.employee_id
    FROM assignments a
    JOIN projects p ON a.project_id = a.project_id
    WHERE p.status = 'Active'
    );

--Task 6.3
SELECT employees.employee_id, employees.first_name, employees.last_name, salary
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
    );

--Part 7
--Task 7.1
SELECT
    e.first_name || ' ' || e.last_name AS full_name,
    e.department,
    ROUND(AVG(a.hours_worked), 2) AS avg_hours_worked,
    RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC) AS salary_rank
FROM employees e
LEFT JOIN assignments a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary
ORDER BY e.department, salary_rank;

--Task 7.2
SELECT
    p.project_name,
    SUM(a.hours_worked) AS total_hours,
    COUNT(DISTINCT a.employee_id) AS num_employees
FROM projects p
JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name
HAVING SUM(a.hours_worked) > 150;

--Task 7.3
SELECT
    e.department,
    COUNT(*) AS total_employees,
    ROUND(AVG(e.salary), 2) AS avg_salary,
    (
        SELECT emp.first_name || ' ' || emp.last_name
        FROM employees emp
        WHERE emp.department = e.department
        ORDER BY emp.salary DESC
        LIMIT 1
    ) AS highest_paid_employee,
    GREATEST(MAX(e.salary), AVG(e.salary)) AS salary_comparison_high,
    LEAST(MIN(e.salary), AVG(e.salary)) AS salary_comparison_low
FROM employees e
GROUP BY e.department
ORDER BY avg_salary DESC;
