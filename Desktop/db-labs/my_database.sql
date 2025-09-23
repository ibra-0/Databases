CREATE DATABASE IF NOT EXISTS university;
USE university;

-- Создание таблицы студентов (1NF)
CREATE TABLE students_1nf (
    student_id INT,
    course_id VARCHAR(10),
    student_name VARCHAR(50),
    course_name VARCHAR(50),
    grade CHAR(1),
    PRIMARY KEY (student_id, course_id)
);