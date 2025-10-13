-- Razyyev Ibrakhim  ID: 24B030181
--Part 1
--Task 1.1  Сreate table employees
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);
-- Task 1.2
CREATE TABLE products_catalog(
     product_id INTEGER,
     product_name TEXT,
     regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND discount_price > 0 AND discount_price < regular_price
        )
);

--Tak 1.3
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN  1 AND 1O),
    CHECK (check_out_date > check_in_date)
);

-- INSERT INTO employees
--  VALID DATA
INSERT INTO employees(first_name, last_name, age, salary)
VALUES
    ('Aigerim', 'Tleubayeva', 25, 250000),
    ('Nurlan', 'Saparov', 60, 450000);
--  INVALID DATA
INSERT INTO employees (first_name, last_name, age, salary)
VALUES ('Timur', 'Young', 16, 120000);
-- ERROR: new row for relation "employees" violates check constraint "employees_age_check"

-- INSERT INTO products_catalog
-- VALID DATA
INSERT INTO products_catalog(product_name TEXT, regular_price NUMERIC, discount_price NUMERIC)
VALUES
--VALID
    (cheese, 300, 30),
--INVALID
    (tomato, 500, 600)
-- ERROR: new row for relation "products_catalog" violates check constraint "valid_discount"

--INSERT INTO bookings
INSERT INTO bookings(check_in_date, check_out_date, num_guests)
--VALID
VALUES
    ('2025-10-01', '2025-10-05', 2),
--INVALID
    ('2025-10-10', '2025-10-12', 0);
-- ERROR: new row for relation "bookings" violates check constraint "bookings_num_guests_check"

--PART 2
--TASK 2.1
CREATE TABLE customers(
    customer_id INTEGER NOT NULL ,
    email TEXT NOT NULL ,
    phone TEXT ,
    registration_date DATE NOT NULL
);

--TASK 2.2
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_game TEXT NOT NULL ,
    quantity INTEGER NOT NULL CHECK ( quantity>= 0 ),
    unit_price NUMERIC NOT NULL CHECK ( unit_price > 0 ),
    last_updated TIMESTAMP NOT NULL
);

--INSERT INTO customers
INSERT INTO customers(customer_id, email, phone, registration_date)
VALUES
--VALID
    (1, 'aigerim@example.com', '87015557777', '2024-01-15'),
--INVALID
    (NULL, 'invalid1@example.com', '87014445566', '2024-06-10');
-- ERROR: null value in column "registration_date" violates not-null constraint

--INSERT INTO inventory
INSERT INTO inventory(item_id, item_game, quantity, unit_price, last_updated)
--VALID
VALUES
    (101, 'Keyboard', 15, 8000, NOW()),
--INVALID
    (103, NULL, 10, 12000, NOW());
-- ERROR: null value in column "item_name" violates not-null constraint

--PART 3
--TASK 3.1
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Task 3.2
CREATE TABLE course_enrollments (
    enrollment_id SERIAL PRIMARY KEY,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)
);
--TASK 3.3
ALTER TABLE users
ADD CONSTRAINT unique_username UNIQUE (username);

ALTER TABLE users
ADD CONSTRAINT unique_email UNIQUE (email);

--PART 4
--TASK 4.1
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);
--TASK 4.2
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);
--TASK 4.3
-- 1  DIFFERENCE BETWEEN UNIQUE AND PRIMARY KEY
--  PRIMARY KEY uniquely identifies each row in a table and automatically implies:
--     - NOT NULL (it cannot contain NULL values)
--     - Only one PRIMARY KEY constraint per table
--  UNIQUE constraint also ensures that all values in a column (or group of columns)
--   are different, but unlike PRIMARY KEY:
--     - It CAN contain NULL values
--     - A table can have multiple UNIQUE constraints



-- 2  WHEN TO USE SINGLE-COLUMN VS. COMPOSITE PRIMARY KEY
-- --------------------------------------------------------
-- • SINGLE-COLUMN PRIMARY KEY:
--     - Used when one column alone can uniquely identify a row
--     - Example: student_id, emp_id, product_id, etc.
--
-- • COMPOSITE PRIMARY KEY:
--     - Used when the uniqueness of a row depends on a combination of multiple columns
--     - Example: (student_id, course_id) in a student_courses table
--       → because a student can take many courses, but the same student cannot take
--         the same course twice in the same record.
--
--  Use a composite key when no single column alone is sufficient to ensure uniqueness.



-- 3️  WHY A TABLE CAN HAVE ONLY ONE PRIMARY KEY BUT MULTIPLE UNIQUE CONSTRAINTS
-- -------------------------------------------------------------------------------
-- • A table can have only one PRIMARY KEY because it serves as the main unique identifier
--   for each record — the database engine uses it for indexing and relationships (foreign keys).
-- • However, a table can have several UNIQUE constraints, since different columns
--   might also require unique values (e.g., username, email).


--PART 5
--TASK 5.1
CREATE TABLE employees_dept(
    emp_id INTEGER PRIMARY KEY ,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);
--TASK 5.2
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id SERIAL PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

-- Task 5.3
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id SERIAL PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk(product_id),
    quantity INTEGER CHECK (quantity > 0)
);

--PART 6
--TASK 6.1
CREATE TABLE ecommerce_customers(
    customer_id SERIAL PRIMARY KEY ,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL

);

CREATE TABLE ecommerce_products (
    product_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE ecommerce_orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES ecommerce_customers(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE ecommerce_order_details (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES ecommerce_orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES ecommerce_products(product_id),
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price > 0)
);