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
SELECT * FROM cc_transactions;