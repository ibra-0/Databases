
CREATE DATABASE university_main
    WITH OWNER = CURRENT_USER
    TEMPLATE = template0
    ENCODING = 'UTF8';

CREATE DATABASE university_archive
    WITH CONNECTION LIMIT = 50
    TEMPLATE = template0;

CREATE DATABASE university_test
    WITH CONNECTION LIMIT = 10
    IS_TEMPLATE = true;


CREATE TABLESPACE student_data
    LOCATION '/data/students';

CREATE TABLESPACE course_data
    OWNER CURRENT_USER
    LOCATION '/data/courses';

CREATE DATABASE university_distributed
    TABLESPACE = student_data;
    
    
    CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone CHAR(15),
    date_of_birth DATE,
    enrollment_date DATE,
    gpa NUMERIC(3,2),
    is_active BOOLEAN DEFAULT TRUE,
    graduation_year SMALLINT
);

CREATE TABLE professors (
    professor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    office_number VARCHAR(20),
    hire_date DATE,
    salary NUMERIC(12,2), 
    is_tenured BOOLEAN DEFAULT FALSE,
    years_experience INT
);

CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_code CHAR(8) UNIQUE, 
    course_title VARCHAR(100) NOT NULL,
    description TEXT,
    credits SMALLINT,
    max_enrollment INT,
    course_fee NUMERIC(8,2),
    is_online BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);
