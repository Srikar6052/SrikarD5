<<<<<<< HEAD
-- ─────────────────────────────────────────
-- DATABASE SETUP
-- ─────────────────────────────────────────
CREATE DATABASE fraud_db;
USE fraud_db;

-- ─────────────────────────────────────────
-- INITIAL INSPECTION
-- ─────────────────────────────────────────
SELECT * FROM cc_transactions;

SELECT
    COUNT(*)                  AS total,
    SUM(amount IS NULL)       AS null_amount,
    SUM(merchant IS NULL)     AS null_merchant,
    SUM(city IS NULL)         AS null_city,
    SUM(is_fraud IS NULL)     AS null_fraud
FROM cc_transactions;

-- ─────────────────────────────────────────
-- REMOVE DUPLICATES
-- ─────────────────────────────────────────
SELECT transaction_id, customer_id, COUNT(*) AS cnt
FROM cc_transactions
GROUP BY transaction_id, customer_id
HAVING cnt > 1;

SET sql_safe_updates = 0;

DELETE t1
FROM cc_transactions t1
JOIN cc_transactions t2
    ON  t1.transaction_id = t2.transaction_id
    AND t1.customer_id    = t2.customer_id
    AND t1.id             > t2.id;

-- ─────────────────────────────────────────
-- CLEAN: AMOUNT COLUMN
-- ─────────────────────────────────────────
UPDATE cc_transactions
SET amount = REPLACE(REPLACE(REPLACE(TRIM(amount), '₹', ''), ',', ''), ' ', '')
WHERE amount IS NOT NULL;

UPDATE cc_transactions
SET amount = NULL
WHERE amount IN ('NA', 'N/A', 'None', 'null', '');

UPDATE cc_transactions
SET amount = NULL
WHERE amount IS NOT NULL
  AND amount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

ALTER TABLE cc_transactions
MODIFY amount DECIMAL(12,2);

-- Fill NULL amounts with average
UPDATE cc_transactions
JOIN (
    SELECT ROUND(AVG(amount), 2) AS avg_amount
    FROM cc_transactions
    WHERE amount IS NOT NULL
) AS t
SET cc_transactions.amount = t.avg_amount
WHERE cc_transactions.amount IS NULL;

-- Fill failed transactions with 0
UPDATE cc_transactions
SET amount = 0
WHERE amount IS NULL
  AND status = 'Failed';

DELETE FROM cc_transactions
WHERE amount IS NULL;

SELECT
    MIN(amount)           AS min_amt,
    MAX(amount)           AS max_amt,
    SUM(amount IS NULL)   AS nulls
FROM cc_transactions;

-- ─────────────────────────────────────────
-- CLEAN: DISCOUNT COLUMN
-- ─────────────────────────────────────────
UPDATE cc_transactions
SET discount = REPLACE(
                 REPLACE(
                   REPLACE(
                     REPLACE(TRIM(discount), '₹', ''),
                   ',', ''),
                 '%', ''),
               ' ', '')
WHERE discount IS NOT NULL;

UPDATE cc_transactions
SET discount = NULL
WHERE discount IN ('NA', 'N/A', 'None', 'null', '');

UPDATE cc_transactions
SET discount = NULL
WHERE discount IS NOT NULL
  AND discount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

ALTER TABLE cc_transactions
MODIFY discount DECIMAL(12,2);

UPDATE cc_transactions
SET discount = 0
WHERE discount IS NULL;

SELECT
    MIN(discount)           AS min_discount,
    MAX(discount)           AS max_discount,
    SUM(discount IS NULL)   AS nulls
FROM cc_transactions;

-- ─────────────────────────────────────────
-- CLEAN: DATE COLUMN
-- ─────────────────────────────────────────
UPDATE cc_transactions
SET trans_date =
    CASE
        WHEN trans_date LIKE '%-%' THEN STR_TO_DATE(trans_date, '%d-%m-%Y')
        WHEN trans_date LIKE '%/%' THEN STR_TO_DATE(trans_date, '%Y/%m/%d')
        ELSE NULL
    END;

UPDATE cc_transactions
SET trans_date = NULL
WHERE trans_date IN ('NA', 'N/A', 'None', 'null', '');

ALTER TABLE cc_transactions
MODIFY trans_date DATE;

ALTER TABLE cc_transactions
CHANGE trans_date `date` DATE;

-- ─────────────────────────────────────────
-- CLEAN: MERCHANT NAMES
-- ─────────────────────────────────────────
UPDATE cc_transactions SET merchant = 'Amazon'   WHERE merchant IN ('Amazn', 'AMZN');
UPDATE cc_transactions SET merchant = 'Flipkart' WHERE merchant IN ('Flipkrt', 'FLPKRT');
UPDATE cc_transactions SET merchant = 'Swiggy'   WHERE merchant = 'Swigy';
UPDATE cc_transactions SET merchant = 'Zomato'   WHERE merchant = 'Zomoto';

-- ─────────────────────────────────────────
-- CLEAN: CITY NAMES
-- ─────────────────────────────────────────
UPDATE cc_transactions SET city = 'Hyderabad' WHERE city IN ('Hyd', 'HYD');
UPDATE cc_transactions SET city = 'Bangalore' WHERE city IN ('Bengalore', 'Bengaluru');
UPDATE cc_transactions SET city = 'Mumbai'    WHERE city = 'Bombay';
UPDATE cc_transactions SET city = 'Chennai'   WHERE city = 'Madras';
UPDATE cc_transactions SET city = 'Kolkata'   WHERE city = 'Calcutta';

-- ─────────────────────────────────────────
-- CLEAN: IS_FRAUD & CUSTOMER RATING
-- ─────────────────────────────────────────
UPDATE cc_transactions
SET is_fraud = 0
WHERE is_fraud IS NULL;

UPDATE cc_transactions
SET customer_rating = (
    SELECT avg_rating FROM (
        SELECT ROUND(AVG(customer_rating)) AS avg_rating
        FROM cc_transactions
        WHERE customer_rating IS NOT NULL
    ) AS temp
)
WHERE customer_rating IS NULL;

UPDATE cc_transactions
SET customer_rating = NULL
WHERE customer_rating NOT BETWEEN 1 AND 5;

-- ─────────────────────────────────────────
-- DROP UNNECESSARY COLUMNS
-- ─────────────────────────────────────────
ALTER TABLE cc_transactions DROP COLUMN country;
ALTER TABLE cc_transactions DROP COLUMN net_amount;
ALTER TABLE cc_transactions DROP COLUMN discount_clean;
ALTER TABLE cc_transactions DROP COLUMN trans_date_clean;

-- ─────────────────────────────────────────
-- MODIFY COLUMN DATA TYPES
-- ─────────────────────────────────────────
ALTER TABLE cc_transactions
    MODIFY amount         DECIMAL(12,2),
    MODIFY discount       DECIMAL(12,2),
    MODIFY tax_percent    DECIMAL(5,2),
    MODIFY customer_rating INT,
    MODIFY is_fraud       TINYINT;

-- ─────────────────────────────────────────
-- FEATURE ENGINEERING
-- ─────────────────────────────────────────
ALTER TABLE cc_transactions ADD COLUMN amount_bucket VARCHAR(20);

UPDATE cc_transactions
SET amount_bucket =
    CASE
        WHEN amount < 1000  THEN 'Low'
        WHEN amount < 10000 THEN 'Medium'
        ELSE 'High'
    END;

ALTER TABLE cc_transactions ADD COLUMN risk_score INT;

UPDATE cc_transactions
SET risk_score =
    CASE
        WHEN is_fraud    = 1      THEN 90
        WHEN risk_level  = 'High' THEN 70
        WHEN risk_level  = 'Medium' THEN 40
        ELSE 10
    END;

-- ─────────────────────────────────────────
-- FINAL CHECKS
-- ─────────────────────────────────────────
SELECT COUNT(*) FROM cc_transactions;
SHOW TABLES;
use fraud_db;
SELECT * FROM cc_transactions;-- ─────────────────────────────────────────
=======
-- ─────────────────────────────────────────
>>>>>>> 35241ea6f25d9726dcded332d26b6c51239da0ff
-- DATABASE SETUP
-- ─────────────────────────────────────────
CREATE DATABASE fraud_db;
USE fraud_db;

-- ─────────────────────────────────────────
-- INITIAL INSPECTION
-- ─────────────────────────────────────────
SELECT * FROM cc_transactions;

SELECT
    COUNT(*)                  AS total,
    SUM(amount IS NULL)       AS null_amount,
    SUM(merchant IS NULL)     AS null_merchant,
    SUM(city IS NULL)         AS null_city,
    SUM(is_fraud IS NULL)     AS null_fraud
FROM cc_transactions;

-- ─────────────────────────────────────────
-- REMOVE DUPLICATES
-- ─────────────────────────────────────────
SELECT transaction_id, customer_id, COUNT(*) AS cnt
FROM cc_transactions
GROUP BY transaction_id, customer_id
HAVING cnt > 1;

SET sql_safe_updates = 0;

DELETE t1
FROM cc_transactions t1
JOIN cc_transactions t2
    ON  t1.transaction_id = t2.transaction_id
    AND t1.customer_id    = t2.customer_id
    AND t1.id             > t2.id;

-- ─────────────────────────────────────────
-- CLEAN: AMOUNT COLUMN
-- ─────────────────────────────────────────
UPDATE cc_transactions
SET amount = REPLACE(REPLACE(REPLACE(TRIM(amount), '₹', ''), ',', ''), ' ', '')
WHERE amount IS NOT NULL;

UPDATE cc_transactions
SET amount = NULL
WHERE amount IN ('NA', 'N/A', 'None', 'null', '');

UPDATE cc_transactions
SET amount = NULL
WHERE amount IS NOT NULL
  AND amount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

ALTER TABLE cc_transactions
MODIFY amount DECIMAL(12,2);

-- Fill NULL amounts with average
UPDATE cc_transactions
JOIN (
    SELECT ROUND(AVG(amount), 2) AS avg_amount
    FROM cc_transactions
    WHERE amount IS NOT NULL
) AS t
SET cc_transactions.amount = t.avg_amount
WHERE cc_transactions.amount IS NULL;

-- Fill failed transactions with 0
UPDATE cc_transactions
SET amount = 0
WHERE amount IS NULL
  AND status = 'Failed';

DELETE FROM cc_transactions
WHERE amount IS NULL;

SELECT
    MIN(amount)           AS min_amt,
    MAX(amount)           AS max_amt,
    SUM(amount IS NULL)   AS nulls
FROM cc_transactions;

-- ─────────────────────────────────────────
-- CLEAN: DISCOUNT COLUMN
-- ─────────────────────────────────────────
UPDATE cc_transactions
SET discount = REPLACE(
                 REPLACE(
                   REPLACE(
                     REPLACE(TRIM(discount), '₹', ''),
                   ',', ''),
                 '%', ''),
               ' ', '')
WHERE discount IS NOT NULL;

UPDATE cc_transactions
SET discount = NULL
WHERE discount IN ('NA', 'N/A', 'None', 'null', '');

UPDATE cc_transactions
SET discount = NULL
WHERE discount IS NOT NULL
  AND discount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

ALTER TABLE cc_transactions
MODIFY discount DECIMAL(12,2);

UPDATE cc_transactions
SET discount = 0
WHERE discount IS NULL;

SELECT
    MIN(discount)           AS min_discount,
    MAX(discount)           AS max_discount,
    SUM(discount IS NULL)   AS nulls
FROM cc_transactions;

-- ─────────────────────────────────────────
-- CLEAN: DATE COLUMN
-- ─────────────────────────────────────────
UPDATE cc_transactions
SET trans_date =
    CASE
        WHEN trans_date LIKE '%-%' THEN STR_TO_DATE(trans_date, '%d-%m-%Y')
        WHEN trans_date LIKE '%/%' THEN STR_TO_DATE(trans_date, '%Y/%m/%d')
        ELSE NULL
    END;

UPDATE cc_transactions
SET trans_date = NULL
WHERE trans_date IN ('NA', 'N/A', 'None', 'null', '');

ALTER TABLE cc_transactions
MODIFY trans_date DATE;

ALTER TABLE cc_transactions
CHANGE trans_date `date` DATE;

-- ─────────────────────────────────────────
-- CLEAN: MERCHANT NAMES
-- ─────────────────────────────────────────
UPDATE cc_transactions SET merchant = 'Amazon'   WHERE merchant IN ('Amazn', 'AMZN');
UPDATE cc_transactions SET merchant = 'Flipkart' WHERE merchant IN ('Flipkrt', 'FLPKRT');
UPDATE cc_transactions SET merchant = 'Swiggy'   WHERE merchant = 'Swigy';
UPDATE cc_transactions SET merchant = 'Zomato'   WHERE merchant = 'Zomoto';

-- ─────────────────────────────────────────
-- CLEAN: CITY NAMES
-- ─────────────────────────────────────────
UPDATE cc_transactions SET city = 'Hyderabad' WHERE city IN ('Hyd', 'HYD');
UPDATE cc_transactions SET city = 'Bangalore' WHERE city IN ('Bengalore', 'Bengaluru');
UPDATE cc_transactions SET city = 'Mumbai'    WHERE city = 'Bombay';
UPDATE cc_transactions SET city = 'Chennai'   WHERE city = 'Madras';
UPDATE cc_transactions SET city = 'Kolkata'   WHERE city = 'Calcutta';

-- ─────────────────────────────────────────
-- CLEAN: IS_FRAUD & CUSTOMER RATING
-- ─────────────────────────────────────────
UPDATE cc_transactions
SET is_fraud = 0
WHERE is_fraud IS NULL;

UPDATE cc_transactions
SET customer_rating = (
    SELECT avg_rating FROM (
        SELECT ROUND(AVG(customer_rating)) AS avg_rating
        FROM cc_transactions
        WHERE customer_rating IS NOT NULL
    ) AS temp
)
WHERE customer_rating IS NULL;

UPDATE cc_transactions
SET customer_rating = NULL
WHERE customer_rating NOT BETWEEN 1 AND 5;

-- ─────────────────────────────────────────
-- DROP UNNECESSARY COLUMNS
-- ─────────────────────────────────────────
ALTER TABLE cc_transactions DROP COLUMN country;
ALTER TABLE cc_transactions DROP COLUMN net_amount;
ALTER TABLE cc_transactions DROP COLUMN discount_clean;
ALTER TABLE cc_transactions DROP COLUMN trans_date_clean;

-- ─────────────────────────────────────────
-- MODIFY COLUMN DATA TYPES
-- ─────────────────────────────────────────
ALTER TABLE cc_transactions
    MODIFY amount         DECIMAL(12,2),
    MODIFY discount       DECIMAL(12,2),
    MODIFY tax_percent    DECIMAL(5,2),
    MODIFY customer_rating INT,
    MODIFY is_fraud       TINYINT;

-- ─────────────────────────────────────────
-- FEATURE ENGINEERING
-- ─────────────────────────────────────────
ALTER TABLE cc_transactions ADD COLUMN amount_bucket VARCHAR(20);

UPDATE cc_transactions
SET amount_bucket =
    CASE
        WHEN amount < 1000  THEN 'Low'
        WHEN amount < 10000 THEN 'Medium'
        ELSE 'High'
    END;

ALTER TABLE cc_transactions ADD COLUMN risk_score INT;

UPDATE cc_transactions
SET risk_score =
    CASE
        WHEN is_fraud    = 1      THEN 90
        WHEN risk_level  = 'High' THEN 70
        WHEN risk_level  = 'Medium' THEN 40
        ELSE 10
    END;

-- ─────────────────────────────────────────
-- FINAL CHECKS
-- ─────────────────────────────────────────
SELECT COUNT(*) FROM cc_transactions;
SHOW TABLES;
use fraud_db;
<<<<<<< HEAD
SELECT * FROM cc_transactions;CREATE DATABASE DRIVEDB;
USE DRIVEDB;
CREATE TABLE DRIVE(
  DRIVE_ID INT AUTO_INCREMENT PRIMARY KEY,
  JOB VARCHAR(50),
  PACKAGE INT,
  DRIVE_DATE DATE
) AUTO_INCREMENT=230;
INSERT INTO DRIVE (JOB, PACKAGE, DRIVE_DATE) VALUES
('Software Developer', 600000, '2023-10-10'),
('Backend Developer', 550000, '2023-09-15'),
('Frontend Developer', 450000, '2023-11-20'),
('Data Administration', 350000, NULL),
('System Analyst', 700000, '2024-01-05');
SELECT * FROM DRIVE;
SELECT JOB, PACKAGE FROM DRIVE;
SELECT DISTINCT JOB FROM DRIVE;
SELECT * FROM DRIVE WHERE PACKAGE > 500000;
SELECT * FROM DRIVE WHERE DRIVE_DATE > '2023-10-01';
SELECT * FROM DRIVE WHERE JOB = 'software developer';
SELECT JOB, PACKAGE, PACKAGE * 1.10 AS Increased_Package FROM DRIVE;
SELECT JOB, PACKAGE, PACKAGE / 1000 AS Package_in_Thousands FROM DRIVE;
SELECT PACKAGE, PACKAGE % 100000 AS Remainder FROM DRIVE;
SELECT * FROM DRIVE WHERE PACKAGE <> 500000;
SELECT * FROM DRIVE WHERE PACKAGE BETWEEN 400000 AND 600000;
SELECT * FROM DRIVE WHERE JOB = 'software developer' AND PACKAGE > 400000;
SELECT * FROM DRIVE WHERE JOB IN ('frontend developer', 'backend developer');
SELECT * FROM DRIVE WHERE JOB <> 'data administration';
SELECT * FROM DRIVE WHERE PACKAGE BETWEEN 400000 AND 600000;
SELECT * FROM DRIVE WHERE PACKAGE NOT BETWEEN 400000 AND 600000;
SELECT * FROM DRIVE WHERE JOB IN ('software developer', 'backend developer');
SELECT * FROM DRIVE WHERE JOB NOT IN ('frontend developer', 'data administration');
SELECT * FROM DRIVE WHERE JOB LIKE 'f%';
SELECT * FROM DRIVE WHERE JOB LIKE '%developer';
SELECT * FROM DRIVE WHERE JOB NOT LIKE '%developer%';
SELECT * FROM DRIVE WHERE DRIVE_DATE IS NULL;
SELECT * FROM DRIVE WHERE DRIVE_DATE IS NOT NULL;
SELECT * FROM DRIVE WHERE PACKAGE > 500000 AND JOB <> 'frontend developer';
SELECT * FROM DRIVE WHERE DRIVE_DATE IS NULL OR PACKAGE < 400000;
SELECT * FROM DRIVE WHERE JOB LIKE '%data%';
SELECT * FROM DRIVE WHERE JOB LIKE '%developer';
SELECT * FROM DRIVE WHERE PACKAGE LIKE '5%';
SELECT * FROM DRIVE WHERE YEAR(DRIVE_DATE) = 2023;
SELECT * FROM DRIVE WHERE JOB LIKE 's%developer';
SELECT * FROM DRIVE WHERE PACKAGE NOT LIKE '5%';
SELECT * FROM DRIVE WHERE JOB NOT LIKE 'developer%';
SELECT * FROM DRIVE WHERE YEAR(DRIVE_DATE) <> 2023;
SELECT * FROM DRIVE LIMIT 2;
SELECT * FROM DRIVE LIMIT 3, 2;
SELECT * FROM DRIVE WHERE JOB = 'data administration' LIMIT 1, 2;
SELECT * FROM DRIVE WHERE JOB LIKE '%developer%' LIMIT 2, 2;
SELECT * FROM DRIVE WHERE DRIVE_DATE IS NULL;
SELECT * FROM DRIVE WHERE DRIVE_DATE IS NOT NULL;


CREATE DATABASE COMPANYDB;
USE COMPANYDB;
CREATE TABLE EMP (
  EMP_ID INT AUTO_INCREMENT PRIMARY KEY,
  ENAME VARCHAR(50),
  JOB VARCHAR(50),
  MGR INT,
  HIREDATE DATE,
  SAL DECIMAL(10,2),
  COMM DECIMAL(10,2),
  DEPT_NO INT
);
INSERT INTO EMP (ENAME, JOB, MGR, HIREDATE, SAL, COMM, DEPT_NO) VALUES
('SMITH', 'CLERK', 7902, '1980-12-17', 800, NULL, 20),
('ALLEN', 'SALESMAN', 7698, '1981-02-20', 1600, 300, 30),
('WARD', 'SALESMAN', 7698, '1981-02-22', 1250, 500, 30),
('JONES', 'MANAGER', 7839, '1981-04-02', 2975, NULL, 20),
('MARTIN', 'SALESMAN', 7698, '1981-09-28', 1250, 1400, 30),
('BLAKE', 'MANAGER', 7839, '1981-05-01', 2850, NULL, 30),
('CLARK', 'MANAGER', 7839, '1981-06-09', 2450, NULL, 10),
('SCOTT', 'ANALYST', 7566, '1982-12-09', 3000, NULL, 20),
('KING', 'PRESIDENT', NULL, '1981-11-17', 5000, NULL, 10),
('TURNER', 'SALESMAN', 7698, '1981-09-08', 1500, 0, 30);
SELECT * FROM EMP;
SELECT * FROM EMP;
SELECT ENAME FROM EMP;
SELECT ENAME, SAL FROM EMP;
SELECT ENAME, COMM FROM EMP;
SELECT EMP_ID, DEPT_NO FROM EMP;
SELECT ENAME, HIREDATE FROM EMP;
SELECT ENAME, JOB FROM EMP;
SELECT ENAME, JOB, SAL FROM EMP;
SELECT ENAME, SAL * 12 AS Annual_Salary FROM EMP;
SELECT *, SAL * 12 + 2000 AS Annual_with_Bonus FROM EMP;
SELECT ENAME, SAL + IFNULL(COMM, 0) AS Total_Salary FROM EMP;
SELECT * FROM EMP WHERE ENAME = 'JONES';
SELECT * FROM EMP WHERE HIREDATE > '1981-01-01';
SELECT ENAME, JOB, (SAL * 6) AS Half_Term_Salary FROM EMP;
SELECT ENAME, SAL, SAL * 12 AS Annual_Salary
FROM EMP
WHERE SAL * 12 > 12000;
SELECT ENAME, HIREDATE FROM EMP WHERE HIREDATE < '1981-01-01';
SELECT * FROM EMP WHERE JOB = 'MANAGER';
SELECT MIN(SAL) AS Min_Salary FROM EMP;
SELECT AVG(SAL) AS Avg_Salary FROM EMP;
SELECT SUM(SAL) AS Total_Salary FROM EMP;
SELECT COUNT(SAL) AS Total_Salaries FROM EMP;
SELECT MAX(SAL) AS Max_Salary, MAX(COMM) AS Max_Comm FROM EMP;
SELECT COUNT(*) AS Total_Employees FROM EMP;
SELECT COUNT(*) AS Emp_Count_Dept20 FROM EMP WHERE DEPT_NO = 20;
SELECT SUM(SAL) AS Total_Salary
FROM EMP
WHERE DEPT_NO IN (10, 20) AND JOB IN ('MANAGER', 'CLERK');
SELECT DEPT_NO, COUNT(*) AS Emp_Count, AVG(SAL) AS Avg_Salary
FROM EMP
WHERE DEPT_NO IN (10, 30)
GROUP BY DEPT_NO;
SELECT COUNT(*) AS Emp_Count
FROM EMP
WHERE SAL < 2000 AND DEPT_NO = 10;
SELECT SUM(SAL) AS Total_Salary
FROM EMP
WHERE JOB = 'CLERK';
SELECT AVG(SAL) AS Average_Salary FROM EMP;
SELECT COUNT(*) AS Emp_Count FROM EMP WHERE ENAME LIKE 'A%';
SELECT COUNT(*) AS Emp_Count FROM EMP WHERE JOB IN ('CLERK', 'MANAGER');
SELECT SUM(SAL) AS Total_Salary
FROM EMP
WHERE MONTH(HIREDATE) = 2;
SELECT COUNT(*) AS Emp_Count FROM EMP WHERE MGR = 7839;
SELECT COUNT(*) AS Emp_Comm FROM EMP WHERE COMM IS NOT NULL AND DEPT_NO = 30;
SELECT JOB, AVG(SAL) AS Avg_Sal, SUM(SAL) AS Total_Sal, COUNT(*) AS Emp_Count, MAX(SAL) AS Max_Sal
FROM EMP
WHERE JOB = 'PRESIDENT';
SELECT COUNT(*) AS Emp_Count, SUM(SAL) AS Total_Sal
FROM EMP
WHERE ENAME LIKE '%LL%';
SELECT MIN(SAL) AS Min_Salary
FROM EMP
WHERE DEPT_NO = 10 AND JOB = 'MANAGER';
SELECT JOB, SUM(SAL) AS Total_Sal FROM EMP GROUP BY JOB;
SELECT DEPT_NO, COUNT(*) AS Salesmen_Count
FROM EMP
WHERE JOB = 'SALESMAN'
GROUP BY DEPT_NO;
SELECT DEPT_NO, AVG(SAL) AS Avg_Sal
FROM EMP
WHERE DEPT_NO <> 20
GROUP BY DEPT_NO;
SELECT JOB, COUNT(*) AS Emp_Count
FROM EMP
WHERE ENAME LIKE '%L%'
GROUP BY JOB;
SELECT DEPT_NO, COUNT(*) AS Emp_Count, AVG(SAL) AS Avg_Sal
FROM EMP
WHERE SAL > 2000
GROUP BY DEPT_NO;
SELECT DEPT_NO, SUM(SAL) AS Total_Sal, COUNT(*) AS Emp_Count
FROM EMP
WHERE JOB = 'SALESMAN'
GROUP BY DEPT_NO;
SELECT JOB, COUNT(*) AS Emp_Count, MAX(SAL) AS Max_Sal
FROM EMP
GROUP BY JOB;
SELECT DEPT_NO, MAX(SAL) AS Max_Sal FROM EMP GROUP BY DEPT_NO;
SELECT DEPT_NO, COUNT(*) AS Emp_Count
FROM EMP
GROUP BY DEPT_NO
HAVING AVG(SAL) > 2000;
SELECT DEPT_NO, COUNT(*) AS Clerk_Count
FROM EMP
WHERE JOB = 'CLERK'
GROUP BY DEPT_NO;
SELECT DEPT_NO, SUM(SAL) AS Total_Sal
FROM EMP
GROUP BY DEPT_NO
HAVING COUNT(*) >= 4;
SELECT JOB, COUNT(*) AS Emp_Count
FROM EMP
WHERE SAL > 1200
GROUP BY JOB
HAVING SUM(SAL) > 2000;
SELECT DEPT_NO, COUNT(*) AS Emp_Count
FROM EMP
WHERE ENAME LIKE '%A%'
GROUP BY DEPT_NO;
SELECT JOB, COUNT(*) AS Emp_Count, SUM(SAL) AS Total_Sal
FROM EMP
WHERE SAL > 1200
GROUP BY JOB
HAVING SUM(SAL) > 3000;
SELECT DEPT_NO, COUNT(*) AS Clerk_Count
FROM EMP
WHERE JOB = 'CLERK'
GROUP BY DEPT_NO
HAVING COUNT(*) >= 2;
SELECT JOB, COUNT(*) AS Emp_Count, SUM(SAL) AS Total_Sal
FROM EMP
WHERE SAL > 1200
GROUP BY JOB
HAVING SUM(SAL) > 3800;
SELECT DEPT_NO, COUNT(*) AS Manager_Count
FROM EMP
WHERE JOB = 'MANAGER'
GROUP BY DEPT_NO
HAVING COUNT(*) = 2;
SELECT JOB, MAX(SAL) AS Max_Sal
FROM EMP
GROUP BY JOB
HAVING MAX(SAL) >= 2000;
SELECT SAL, COUNT(*) AS Occurrences
FROM EMP
GROUP BY SAL
HAVING COUNT(*) > 1;
SELECT HIREDATE, COUNT(*) AS Occurrences
FROM EMP
GROUP BY HIREDATE
HAVING COUNT(*) > 1;
SELECT DEPT_NO, AVG(SAL) AS Avg_Sal
FROM EMP
GROUP BY DEPT_NO
HAVING AVG(SAL) < 3000;
SELECT DEPT_NO, COUNT(*) AS Emp_Count
FROM EMP
WHERE ENAME LIKE '%A%' OR ENAME LIKE '%S%'
GROUP BY DEPT_NO
HAVING COUNT(*) >= 8;
SELECT JOB, MIN(SAL) AS Min_Sal, MAX(SAL) AS Max_Sal
FROM EMP
GROUP BY JOB
HAVING MIN(SAL) > 2000 AND MAX(SAL) < 4000;

select *from emp
where ename like '%^_A%' escape '^';


create database college;
use college;
create table students(
id int primary key ,
name varchar(50), 
age int,
dept varchar(20)
);
create table courses(
course_id int,
course_name varchar(20),
credits int
);
create table teachers(
teacher_id int,
teacher_name varchar(50),
salary int
);
show tables;
create table dummy(
name text,
age int,
dob date);
alter table dummy modify column age int not null;
alter table dummy modify column dob date default '2024-02-03';
alter table students modify column id int auto_increment;
desc students;
desc dummy;
select * from dummy;	
insert into students values (1,'sai',20,'maths'); 
insert into students (name,age,dept) values ('raju',22,'maths'),
('prabhas',21,'physics'),
('charan',20,'chemistry');
select * from students;
update students set age=20 where id =2;
set sql_safe_updates=0;
update students set dept='mpc';
delete PK     ! ߤ�lZ      [Content_Types].xml �(�                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ���n�0E�����Ub袪*�>�-R�{V��Ǽ��QU�
l"%3��3Vƃ�ښl	�w%�=���^i7+���-d&�0�A�6�l4��L60#�Ò�S
O����X� �*��V$z�3��3������%p)O�^����5}nH"d�s�Xg�L�`���|�ԟ�|�P�rۃs��PK   �>[               word/numbering.xml��In�0��������Y4hѢ(
4= -�6�(�N��Ew��g�IJ��"Uv�x󯔐|�D��"�ss���51�T3��G�z�/�ڷ�wW#�'�{�9�jO4�ngon6�s*亞���$p��*I�����$�#���"I�b�D<�ѕI؜�,y�-�p�2&�j���2�*`��p�d%�p�`.-/U��rߢ�.tӀ�$��.�/�!��Eq���&'WUȺm����m�.w�����ō6��"�4���]1Y'�F��E�]a��Փ��:&뎃�������Kˣ�پ���� ��'6D<?9�}��G�S$Ȫ$uC�ᮈH� ��?t����5���[vj�$��� ��I�~��q�._W$�۴����aUSE srikardb;
CREATE TABLE Insta_post (
    post_id INT PRIMARY KEY,
    user_id INT,
    username VARCHAR(50),
    caption VARCHAR(255),
    likes INT,
    comments INT,
    created_at DATE
);

INSERT INTO Insta_post VALUES
(101, 1, 'yash_123', 'Morning vibes 🌞', 120, 15, '2023-01-01'),
(102, 2, 'neha_insta', 'Travel diaries ✈️', 300, 40, '2023-02-10'),
(103, 3, 'raj_cool', 'My new painting 🎨', 95, 10, '2023-02-20'),
(104, 1, 'yash_123', 'Happy Holi! 🌈', 500, 80, '2023-03-08'),
(105, 4, 'anita_star', 'Workout motivation 💪', 250, 25, '2023-03-15'),
(106, 5, 'vikas_travel', 'Beautiful sunset 🌅', 400, 60, '2023-03-20'),
(107, 3, 'raj_cool', 'Foodie life 🍕', 150, 20, '2023-04-05'),
(108, 2, 'neha_insta', 'Best friends ❤️', 600, 100, '2023-04-12'),
(109, 5, 'vikas_travel', 'Mountain trek 🏔️', 550, 90, '2023-04-25'),
(110, 4, 'anita_star', 'Self care Sunday 🧘‍♀️', 200, 18, '2023-05-01');

select * from insta_post;

select * from insta_post where likes >(select avg(likes) from insta_post);
select * from insta_post where comments > (select avg(comments) from insta_post);
select * from insta_post where likes = (select max(likes) from insta_post);
select * from insta_post where likes = (select min(likes) from insta_post);
select caption from insta_post where likes =(select max(likes) from insta_post where likes<(select max(likes) from insta_post));
select* from insta_post where created_at =(select created_at from insta_post where likes =(select max(likes) from insta_post));
select * from insta_post where likes >(select likes*2 from insta_post where post_id=103);
select * from insta_post where created_at>(select max(created_at) from insta_post);
select * from insta_post where comments > (select max(comments) from insta_post);
select * from insta_post where likes>(select avg(likes) from insta_post);
select * from insta_post where likes>(select avg(likes)from insta_post where created_at between '2023-03-01' and '2023-03-31');
select * from insta_post where comments > (select avg(comments) from insta_post where created_at between '2023-04-01' and '2023-04-30');
select * from insta_post where likes = (select max(likes) from insta_post where created_at between '2023-04-01' and '2023-04-30');
select username from insta_post where likes=(select max(likes) from insta_post);
select username from insta_post where likes=(select min(likes) from insta_post);
select * from insta_post where length(caption)>(select avg(length(caption))from insta_post);
select * from insta_post where username in (select username from insta_post where likes >500);
select * from insta_post where username in (select username from insta_post where likes<100);
select * from insta_post where likes >(select sum(likes) from insta_post where username ='raj_cool');
select * from insta_post where likes >(select likes from insta_post where username='yash_123');
select * from insta_post where comments in (select comments from insta_post where username='neha_insta');
select * from insta_post where created_at <(select min(created_at) from insta_post where username='vikas_travel');
select * from insta_post where created_at <(select max(created_at) from insta_post where username='anita_star');
select * from insta_post where username in (SELECT username FROM insta_post GROUP BY username HAVING COUNT(*) > (SELECT COUNT(*) FROM insta_post WHERE username = 'yash_123'));
select * from insta_post where username in (SELECT username FROM insta_post GROUP BY username HAVING COUNT(*) < (SELECT COUNT(*) FROM insta_post WHERE username = 'raj_cool'));
select * from insta_post where likes >(select avg(likes)+100 from insta_post);
select * from insta_post where comments >(select avg(comments)+20 from insta_post);
select * from insta_post where likes=((select max(likes) from insta_post)+(select min(likes) from insta_post)/2);
select * from insta_post where created_at =(select created_at from insta_post group by(created_at) having count(*)>1)use srikardb;
create table emp(
empid int primary key,
name varchar(50),
department varchar(20),
salary decimal(10,2),
age int,
city varchar(20)
);
insert into emp(empid,name,department,salary,age,city) values
(1, 'Amit', 'HR', 35000, 29, 'Delhi'),
(2, 'Sneha', 'Finance', 48000, 32, 'Mumbai'),
(3, 'Ravi', 'IT', 55000, 28, 'Bangalore'),
(4, 'Priya', 'Sales', 40000, 30, 'Chennai'),
(5, 'Karan', 'Finance', 60000, 35, 'Delhi'),
(6, 'Meena', 'HR', 30000, 26, 'Pune'),
(7, 'Suresh', 'IT', 70000, 40, 'Hyderabad'),
(8, 'Divya', 'Sales', 42000, 27, 'Mumbai'),
(9, 'Vikram', 'Finance', 65000, 36, 'Bangalore'),
(10, 'Nisha', 'IT', 72000, 31, 'Delhi'),
(11, 'Rohit', 'HR', 31000, 25, 'Chennai'),
(12, 'Pooja', 'Sales', 38000, 29, 'Pune'),
(13, 'Anil', 'Finance', 58000, 34, 'Hyderabad'),
(14, 'Neha', 'IT', 64000, 33, 'Mumbai'),
(15, 'Rajesh', 'Sales', 45000, 37, 'Delhi'),
(16, 'Komal', 'HR', 33000, 28, 'Bangalore'),
(17, 'Deepak', 'Finance', 52000, 30, 'Chennai'),
(18, 'Swati', 'IT', 76000, 38, 'Pune'),
(19, 'Arjun', 'Sales', 47000, 29, 'Hyderabad'),
(20, 'Lakshmi', 'Finance', 61000, 32, 'Delhi'),
(21, 'Manoj', 'IT', 69000, 36, 'Bangalore'),
(22, 'Sakshi', 'Sales', 39000, 26, 'Mumbai'),
(23, 'Harish', 'HR', 29500, 24, 'Chennai'),
(24, 'Kavita', 'Finance', 57000, 35, 'Hyderabad'),
(25, 'Sunil', 'IT', 73000, 39, 'Delhi'),
(26, 'Ramesh', 'Sales', 46000, 33, 'Pune'),
(27, 'Jyoti', 'Finance', 59000, 31, 'Bangalore'),
(28, 'Ashok', 'IT', 71000, 34, 'Mumbai'),
(29, 'Tanvi', 'Sales', 41000, 27, 'Delhi'),
(30, 'Gaurav', 'HR', 34000, 29, 'Hyderabad');

select * from emp where salary >
(select avg(salary) from emp);

select * from emp where age <
(select min(age) from emp where department="HR");

select * from emp where city =
(select city from emp where name="ravi");

select * from emp where salary=
(select salary from emp where name="karan");

select * from emp where salary>
(select salary from emp where name="sneha");

select * from emp where department=
(select department from emp where name="nisha");

select * from emp where city in
(select city from emp where department="Finance");

select * from emp where age >
(select max(age) from emp where department="Sales");

select * from emp where salary >
(select max(salary) from emp where department="HR");

select 	* from emp where department in
(select department from emp where salary>70000  );


CREATE DATABASE EMPDB;
USE EMPDB;
CREATE TABLE DEPT (
  DEPTNO INT PRIMARY KEY,
  DNAME VARCHAR(20),
  LOC VARCHAR(20)
);
CREATE TABLE EMP (
  EMPNO INT PRIMARY KEY,
  ENAME VARCHAR(20),
  JOB VARCHAR(20),
  MGR INT,
  HIREDATE DATE,
  SAL DECIMAL(10,2),
  COMM DECIMAL(10,2),
  DEPTNO INT,
  FOREIGN KEY (DEPTNO) REFERENCES DEPT(DEPTNO)
);
INSERT INTO DEPT VALUES
(10, 'ACCOUNTING', 'NEW YORK'),
(20, 'RESEARCH', 'DALLAS'),
(30, 'SALES', 'CHICAGO'),
(40, 'OPERATIONS', 'BOSTON');
INSERT INTO EMP VALUES
(7369, 'SMITH', 'CLERK', 7902, '1980-12-17', 800, NULL, 20),
(7499, 'ALLEN', 'SALESMAN', 7698, '1981-02-20', 1600, 300, 30),
(7521, 'WARD', 'SALESMAN', 7698, '1981-02-22', 1250, 500, 30),
(7566, 'JONES', 'MANAGER', 7839, '1981-04-02', 2975, NULL, 20),
(7654, 'MARTIN', 'SALESMAN', 7698, '1981-09-28', 1250, 1400, 30),
(7698, 'BLAKE', 'MANAGER', 7839, '1981-05-01', 2850, NULL, 30),
(7782, 'CLARK', 'MANAGER', 7839, '1981-06-09', 2450, NULL, 10),
(7788, 'SCOTT', 'ANALYST', 7566, '1982-12-09', 3000, NULL, 20),
(7839, 'KING', 'PRESIDENT', NULL, '1981-11-17', 5000, NULL, 10),
(7934, 'MILLER', 'CLERK', 7782, '1982-01-23', 1300, NULL, 10);
SELECT ENAME, SAL FROM EMP ORDER BY ENAME ASC, SAL DESC;
SELECT DEPTNO, COUNT(*) AS TOTAL_EMPS FROM EMP GROUP BY DEPTNO ORDER BY TOTAL_EMPS;
SELECT * FROM EMP ORDER BY JOB, SAL DESC;
SELECT * FROM EMP WHERE SAL > (SELECT SAL FROM EMP WHERE ENAME='MILLER');
SELECT * FROM EMP 
WHERE JOB='SALESMAN' AND DEPTNO=(SELECT DEPTNO FROM EMP WHERE ENAME='WARD');
SELECT * FROM EMP 
WHERE SAL BETWEEN 1000 AND 3000 
AND HIREDATE > (SELECT HIREDATE FROM EMP WHERE ENAME='SMITH');
SELECT ENAME, HIREDATE 
FROM EMP 
WHERE COMM IS NULL 
AND SAL > (SELECT SAL FROM EMP WHERE ENAME='MILLER') 
AND JOB IN ('SALESMAN', 'ANALYST', 'PRESIDENT', 'MANAGER');
SELECT * FROM EMP 
WHERE SAL > (SELECT SAL FROM EMP WHERE ENAME='SMITH') 
AND SAL < (SELECT SAL FROM EMP WHERE ENAME='SCOTT')
AND HIREDATE > (SELECT HIREDATE FROM EMP WHERE ENAME='ALLEN')
AND HIREDATE < (SELECT HIREDATE FROM EMP WHERE ENAME='ADAMS');
SELECT EMPNO, ENAME, (SAL*12) AS ANNUAL_SAL 
FROM EMP 
WHERE (SAL*12) > ((SELECT SAL FROM EMP WHERE ENAME='WARD')*12);
SELECT ENAME, SAL 
FROM EMP 
WHERE SAL > (SELECT SAL FROM EMP WHERE ENAME='MILLER')
AND DEPTNO = (SELECT DEPTNO FROM DEPT WHERE LOC='NEW YORK');
SELECT * FROM EMP 
WHERE HIREDATE > (SELECT HIREDATE FROM EMP WHERE ENAME='ALLEN')
AND DEPTNO = (SELECT DEPTNO FROM DEPT WHERE DNAME='RESEARCH');
SELECT DNAME 
FROM DEPT 
WHERE DEPTNO = (SELECT DEPTNO FROM EMP WHERE ENAME='SMITH');
SELECT D.DNAME, D.LOC, D.DEPTNO 
FROM EMP E JOIN DEPT D ON E.DEPTNO=D.DEPTNO 
WHERE E.ENAME LIKE '%R';
SELECT ENAME 
FROM EMP 
WHERE SAL = (SELECT MAX(SAL) FROM EMP);
SELECT ENAME, SAL, COMM 
FROM EMP 
WHERE COMM = (SELECT MIN(COMM) FROM EMP WHERE COMM IS NOT NULL);
SELECT E.* 
FROM EMP E JOIN DEPT D ON E.DEPTNO=D.DEPTNO 
WHERE D.DNAME LIKE '%A%';
SELECT * 
FROM EMP
WHERE SAL > ALL (SELECT SAL FROM EMP WHERE JOB = 'SALESMAN');
SELECT * 
FROM EMP
WHERE HIREDATE > ALL (SELECT HIREDATE FROM EMP WHERE JOB = 'CLERK');
SELECT ENAME, SAL 
FROM EMP
WHERE SAL < ANY (SELECT SAL FROM EMP WHERE JOB = 'MANAGER');
SELECT ENAME, HIREDATE 
FROM EMP
WHERE HIREDATE < ALL (SELECT HIREDATE FROM EMP WHERE JOB = 'MANAGER');
SELECT ENAME 
FROM EMP
WHERE HIREDATE > ALL (SELECT HIREDATE FROM EMP WHERE JOB = 'MANAGER')
AND SAL > ALL (SELECT SAL FROM EMP WHERE JOB = 'CLERK');
SELECT * 
FROM EMP
WHERE JOB = 'CLERK'
AND HIREDATE < ANY (SELECT HIREDATE FROM EMP WHERE JOB = 'SALESMAN');
SELECT ENAME 
FROM EMP
WHERE HIREDATE > ALL (SELECT HIREDATE FROM EMP WHERE DEPTNO = 10);
SELECT D.DNAME, COUNT(E.EMPNO) AS TOTAL_EMPS
FROM DEPT D 
JOIN EMP E ON D.DEPTNO = E.DEPTNO
GROUP BY D.DNAME;
SELECT D.DNAME, MIN(E.SAL) AS MIN_SAL, MAX(E.SAL) AS MAX_SAL
FROM DEPT D 
JOIN EMP E ON D.DEPTNO = E.DEPTNO
GROUP BY D.DNAME
HAVING COUNT(E.EMPNO) >= 5;
SELECT E.*, D.*
FROM EMP E 
JOIN DEPT D ON E.DEPTNO = D.DEPTNO
WHERE E.HIREDATE > (SELECT HIREDATE FROM EMP WHERE ENAME = 'CLARK');
SELECT E.ENAME, D.LOC
FROM EMP E 
JOIN DEPT D ON E.DEPTNO = D.DEPTNO;
SELECT D.DNAME, E.SAL
FROM EMP E 
JOIN DEPT D ON E.DEPTNO = D.DEPTNO
WHERE E.SAL > 2340;
SELECT D.DNAME, E.EMPNO
FROM EMP E 
JOIN DEPT D ON E.DEPTNO = D.DEPTNO
WHERE E.EMPNO IN (7839, 7902)
AND D.LOC = 'NEW YORK';
SELECT ENAME, SAL
FROM EMP 
NATURAL JOIN DEPT
WHERE DNAME = 'ACCOUNTING';
SELECT DNAME, COUNT(*) AS TOTAL_EMPS
FROM EMP 
NATURAL JOIN DEPT
GROUP BY DNAME;
select min(sal) as third_min_sal
from emp where sal>
(select min(sal) from emp 
where sal> (Select min(Sal) from emp));
select * from emp cross join dept;

SELECT DISTINCT sal
FROM emp
ORDER BY sal ASC
LIMIT 1 OFFSET 4;

SELECT DISTINCT sal
FROM emp
ORDER BY sal DESC
LIMIT 1 OFFSET 7;

SELECT ename
FROM emp
WHERE sal = (
    SELECT DISTINCT sal
    FROM emp
    ORDER BY sal ASC
    LIMIT 1 OFFSET 2
);

SELECT empno
FROM emp
WHERE sal = (
    SELECT DISTINCT sal
    FROM emp
    ORDER BY sal DESC
    LIMIT 1 OFFSET 1
);

SELECT ename
FROM emp
WHERE hiredate < (
    SELECT MAX(hiredate)
    FROM emp
);

select *
from emp 
where sal>(select avg(sal) from emp);

select * from emp 
where sal>(Select min(sal) from emp where job='manager');

SELECT e1.ENAME, e1.SAL, e1.DEPTNO
FROM EMP e1
WHERE e1.SAL > (
    SELECT AVG(e2.SAL)
    FROM EMP e2
    WHERE e1.DEPTNO = e2.DEPTNO
);


SELECT d.DNAME
FROM DEPT d
WHERE EXISTS (
    SELECT 1
    FROM EMP e
    WHERE d.DEPTNO = e.DEPTNO
);

SELECT d.DNAME
FROM DEPT d
WHERE NOT EXISTS (
    SELECT 1
    FROM EMP e
    WHERE d.DEPTNO = e.DEPTNO
);

select dname 
from dept d
where not exists (select deptno from emp e  where  d.DEPTNO = e.DEPTNO and job='manager');

select * from emp;

SELECT ename, job FROM emp;

SELECT * FROM emp WHERE deptno = 20;

SELECT ename, sal, sal * 1.7 AS increased_salary
FROM emp;

SELECT * FROM emp
WHERE sal > 2000 AND sal < 4000;

SELECT * FROM emp
WHERE job IN ('MANAGER', 'ANALYST');

SELECT * FROM emp
WHERE sal NOT BETWEEN 1000 AND 3000;

SELECT * FROM emp
WHERE ename LIKE 'S%';

SELECT * FROM emp
WHERE mgr IS NULL;

SELECT SUM(sal) AS total_salary
FROM emp;

SELECT deptno, MAX(sal) AS max_salary
FROM emp
GROUP BY deptno;

SELECT * FROM emp
ORDER BY sal DESC;

SELECT ename, sal
FROM emp
WHERE sal > (SELECT AVG(sal) FROM emp);

SELECT e.*
FROM emp e
WHERE sal = (
    SELECT MAX(sal) 
    FROM emp 
    WHERE deptno = e.deptno
);

SELECT MAX(sal) AS second_highest
FROM emp
WHERE sal < (SELECT MAX(sal) FROM emp);

SELECT e.ename, d.dname
FROM emp e
INNER JOIN dept d ON e.deptno = d.deptno;

SELECT e.*, d.*
FROM emp e
LEFT JOIN dept d ON e.deptno = d.deptno;

SELECT e.*, d.*
FROM emp e
RIGHT JOIN dept d ON e.deptno = d.deptno;
	
SELECT *
FROM emp
NATURAL JOIN dept;

SELECT *
FROM emp
CROSS JOIN dept;

SELECT e1.ename AS emp_name, e2.ename AS manager_name
FROM emp e1
JOIN emp e2 ON e1.empno = e2.mgr;

SELECT ename, sal
FROM emp
WHERE sal > (SELECT sal FROM emp WHERE ename = 'SCOTT');

SELECT deptno, MAX(sal) AS max_salary
FROM emp
GROUP BY deptno
HAVING MAX(sal) > 3000;

SELECT deptno, SUM(sal) AS total_salary
FROM emp
GROUP BY deptno
HAVING SUM(sal) > 7000;

SELECT deptno, SUM(sal) AS total_salary
FROM emp
GROUP BY deptno;

SELECT deptno, SUM(sal) AS total_salary
FROM emp
GROUP BY deptno
HAVING SUM(sal) BETWEEN 5000 AND 10000;

SELECT job, MAX(sal) AS max_salary, AVG(sal) AS avg_salary
FROM emp
GROUP BY job
HAVING MAX(sal) > 3000;

SELECT deptno, COUNT(*) AS emp_count
FROM emp
GROUP BY deptno
HAVING COUNT(*) > 2;

SELECT deptno, AVG(sal) AS avg_salary
FROM emp
GROUP BY deptno
HAVING AVG(sal) > 2000;

SELECT *
FROM emp
WHERE deptno IN (10, 30);

SELECT *
FROM emp
WHERE ename LIKE '%R';

SELECT *
FROM emp
WHERE job <> 'CLERK' AND sal > 2000;

SELECT d.dname
FROM dept d
WHERE EXISTS (
    SELECT 1 FROM emp e
    WHERE e.deptno = d.deptno
);

SELECT d.dname
FROM dept d
WHERE NOT EXISTS (
    SELECT 1 FROM emp e
    WHERE e.deptno = d.deptno
);

SELECT DISTINCT e.ename
FROM emp e
WHERE e.empno IN (SELECT mgr FROM emp WHERE mgr IS NOT NULL);

SELECT e.ename
FROM emp e
WHERE e.empno NOT IN (SELECT DISTINCT mgr FROM emp WHERE mgr IS NOT NULL);

SELECT d.deptno, d.dname
FROM dept d
WHERE NOT EXISTS (
    SELECT 1 FROM emp e
    WHERE e.deptno = d.deptno
    AND e.job = 'MANAGER'
);

SELECT e.ename, e.sal, e.deptno
FROM emp e
WHERE e.sal > (
    SELECT AVG(sal) 
    FROM emp 
    WHERE deptno = e.deptno
);

SELECT e.*
FROM emp e
WHERE e.deptno IN (
    SELECT deptno FROM emp WHERE job = 'CLERK'
);

SELECT e.ename, e.deptno, m.ename AS manager_name, m.deptno AS manager_dept
FROM emp e
JOIN emp m ON e.mgr = m.empno
WHERE e.deptno <> m.deptno;

SELECT d.deptno, d.dname
FROM dept d
WHERE NOT EXISTS (
    SELECT 1 FROM emp e
    WHERE e.deptno = d.deptno
    AND e.sal <= 1000
);

SELECT e.*
FROM emp e
WHERE (SELECT COUNT(*) FROM emp WHERE deptno = e.deptno) = 1;

SELECT d.deptno, d.dname
FROM dept d
WHERE EXISTS (
    SELECT 1 FROM emp e
    WHERE e.deptno = d.deptno
    AND e.sal > 3000
);

SELECT e.ename, e.sal, e.deptno
FROM emp e
WHERE e.sal > (
    SELECT AVG(sal) 
    FROM emp 
    WHERE deptno = e.deptno
);

SELECT d.deptno, d.dname
FROM dept d
WHERE NOT EXISTS (
    SELECT 1 FROM emp e
    WHERE e.deptno = d.deptno
    AND e.sal > 3000
);

use drivedb;
show tables;	
select * FROM EMP;





create database deptdb;
use deptdb;
CREATE TABLE department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    salary DECIMAL(10,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES department(dept_id)
);

INSERT INTO department VALUES
(1, 'HR', 'Delhi'),
(2, 'IT', 'Mumbai'),
(3, 'Finance', 'Pune'),
(4, 'Sales', 'Chennai'),
(5, NULL, 'Bangalore');  -- Null department name

INSERT INTO employee VALUES
(101, 'Amit', 50000, 1),
(102, 'Riya', 60000, 2),
(103, 'John', 55000, NULL),  -- No department assigned
(104, 'Sara', 45000, 3),
(105, 'Neha', 40000, NULL);  -- No department assigned

SELECT e.emp_id, e.emp_name, e.salary, d.dept_name, d.location
FROM employee e
LEFT JOIN department d
ON e.dept_id = d.dept_id;

SELECT e.emp_id, e.emp_name, e.salary, d.dept_name, d.location
FROM employee e
RIGHT JOIN department d
ON e.dept_id = d.dept_id;





=======
SELECT * FROM cc_transactions;
>>>>>>> 35241ea6f25d9726dcded332d26b6c51239da0ff
