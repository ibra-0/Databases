CREATE TABLE accounts (
 id SERIAL PRIMARY KEY,
 name VARCHAR(100) NOT NULL,
 balance DECIMAL(10, 2) DEFAULT 0.00
);
CREATE TABLE products (
 id SERIAL PRIMARY KEY,
 shop VARCHAR(100) NOT NULL,
 product VARCHAR(100) NOT NULL,
 price DECIMAL(10, 2) NOT NULL
);
-- Insert test data
INSERT INTO accounts (name, balance) VALUES
 ('Alice', 1000.00),
 ('Bob', 500.00),
 ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
 ('Joe''s Shop', 'Coke', 2.50),
 ('Joe''s Shop', 'Pepsi', 3.00);

BEGIN;
UPDATE accounts SET balance = balance - 100.00
 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Bob';
COMMIT;

--a)Alice 900 and Bob 600
--b)If one of the Update had thrown error postgres would have issued and money would still be there
--c)Alice's balances have decreased, Bob's balance has not increased the data is corrupted.

--3.3
BEGIN;
UPDATE accounts SET balance = balance - 500.00
 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
-- Oops! Wrong amount, let's undo
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';
--a) Alice's balance after Rollback was 400
--b)after Rollbacl became 900
--c)for example bank system debited funds from A but was unable to credit to B, Roolback executed to cancel the debit

--3.4
BEGIN;
UPDATE accounts SET balance = balance - 100.00
 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Bob';
-- Oops, should transfer to Wally instead
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00
 WHERE name = 'Wally';
COMMIT;

SELECT * FROM accounts;
--a) after COMMIT balances are Bob,600.00, Alice,800.00, Wally,850.00
--b) yes  Bob's account  credited, but we Rllbacked to save point to cancel this in the final stage
--c)SAvepoint allows us to cancel last steps, but not cancel ALL Transaction

--3.5
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to make changes and COMMIT
-- Then re-run:
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT
--a) Terminal A before see coke and pepsi and after see fanta
--b) Coke and ppepsi
--c) READ COMMITTED reads the current data for each SELECT, SERIALIZABLE: No other transactions exist until it completes

--3.6
--Terminal 1:
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products
 WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2
SELECT MAX(price), MIN(price) FROM products
 WHERE shop = 'Joe''s Shop';
COMMIT;
--Terminal 2:
BEGIN;
INSERT INTO products (shop, product, price)
 VALUES ('Joe''s Shop', 'Sprite', 4.00);
COMMIT;
--a)no terminal 1 did not see inserted products only after COMMIT terminal 1
--b) phantom read is when in one transaction repeated SELECT return new row that were not present in the first SELECT because another transaction inserted them
--c)only SERIALIZABLE

--3.7
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to UPDATE but NOT commit
SELECT * FROM products WHERE shop = 'Joe''s Shop';
-- Wait for Terminal 2 to ROLLBACK
SELECT * FROM products WHERE shop = 'Joe''s Shop';
COMMIT;
--Terminal 2:
BEGIN;
UPDATE products SET price = 99.99
 WHERE product = 'Fanta';
-- Wait here (don't commit yet)
-- Then:
ROLLBACK;
--a)Yes, Terminal 1 saw the price as 99.99, even though Terminal 2 did not COMMIT
--b)A dirty read is a read of data that has been modified by another transaction but not yet committed
--c)Because it allows reading of uncommitted, potentially false data, which can lead to incorrect calculations, errors

--TASK 4
--1
BEGIN;

DO $$
DECLARE
    bob_balance DECIMAL(10,2);
BEGIN
    SELECT balance INTO bob_balance
    FROM accounts
    WHERE name = 'Bob';

    IF bob_balance < 200 THEN
        RAISE EXCEPTION 'Insufficient funds: Bob has only %', bob_balance;
    END IF;
END $$;

UPDATE accounts
SET balance = balance - 200
WHERE name = 'Bob';

UPDATE accounts
SET balance = balance + 200
WHERE name = 'Wally';

COMMIT;

--2
BEGIN;
INSERT INTO products(shop, product, price)
VALUES ('Joe''s Shop', 'Sprite', 2.75);
SAVEPOINT  after_insert;

UPDATE products
SET price = 3.25
WHERE product = 'Sprite' AND shop = 'Joe''s Shop';

SAVEPOINT after_update;

DELETE FROM products
WHERE product = 'Sprite' AND shop = 'Joe''s Shop';

ROLLBACK TO after_insert;

COMMIT;

--3
CREATE TABLE bank_accounts (
    id SERIAL PRIMARY KEY,
    account_number VARCHAR(20) UNIQUE NOT NULL,
    owner_name VARCHAR(100) NOT NULL,
    balance DECIMAL(10, 2) NOT NULL
);

INSERT INTO bank_accounts (account_number, owner_name, balance)
VALUES ('ACC123', 'Alice', 1000.00);
--terminal 1
BEGIN;
SELECT balance FROM bank_accounts WHERE account_number = 'ACC123';
UPDATE bank_accounts SET balance = balance - 200 WHERE account_number = 'ACC123';
--not commited
COMMIT;
-- balance 800.00
--terminal2
BEGIN;
SELECT balance FROM bank_accounts WHERE account_number = 'ACC123';
--blance still 1000
UPDATE bank_accounts SET balance = balance - 300 WHERE account_number = 'ACC123';

COMMIT ;
SELECT balance FROM bank_accounts WHERE account_number = 'ACC123';
-- RESULT: 500

--4
-- Create Sells table
CREATE TABLE Sells (
    shop VARCHAR(100),
    product VARCHAR(100),
    price DECIMAL(10, 2),
    PRIMARY KEY (shop, product)
);

INSERT INTO Sells (shop, product, price) VALUES
('Joe''s Shop', 'Coke', 2.50),
('Joe''s Shop', 'Pepsi', 3.00),
('Joe''s Shop', 'Sprite', 2.75);

-- Joe wants to update all prices by 10%
UPDATE Sells SET price = price * 1.10 WHERE shop = 'Joe''s Shop';
-- This executes multiple row updates

-- Sally runs these queries concurrently:
SELECT MAX(price) as max_price FROM Sells WHERE shop = 'Joe''s Shop';
-- Might see: 3.30 (Pepsi's new price)

SELECT MIN(price) as min_price FROM Sells WHERE shop = 'Joe''s Shop';
-- Might see: 2.50 (Coke's old price, not updated yet)

-- Sally sees MAX (3.30) < MIN (2.50) - which is impossible!
BEGIN;
UPDATE Sells SET price = price * 1.10 WHERE shop = 'Joe''s Shop';
COMMIT;
-- All updates happen atomically
-- Option 1: Use transaction for consistent snapshot
BEGIN;
SELECT MAX(price) as max_price FROM Sells WHERE shop = 'Joe''s Shop';
SELECT MIN(price) as min_price FROM Sells WHERE shop = 'Joe''s Shop';
COMMIT;

-- Option 2: Use REPEATABLE READ isolation
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
SELECT MAX(price) as max_price, MIN(price) as min_price
FROM Sells WHERE shop = 'Joe''s Shop';
COMMIT;

-- Option 3: Single query (always consistent)
SELECT MAX(price) as max_price, MIN(price) as min_price
FROM Sells WHERE shop = 'Joe''s Shop';

-- Reset prices
UPDATE Sells SET price = CASE
    WHEN product = 'Coke' THEN 2.50
    WHEN product = 'Pepsi' THEN 3.00
    WHEN product = 'Sprite' THEN 2.75
END;

-- Problem demonstration (simulating concurrent access)
-- Terminal 1:
BEGIN;
UPDATE Sells SET price = 3.30 WHERE shop = 'Joe''s Shop' AND product = 'Pepsi';
-- Don't commit yet

-- Terminal 2:
SELECT MAX(price) FROM Sells WHERE shop = 'Joe''s Shop'; -- Might see 3.30
SELECT MIN(price) FROM Sells WHERE shop = 'Joe''s Shop'; -- Might see 2.50 (inconsistent!)

-- Terminal 1 continues:
UPDATE Sells SET price = 3.03 WHERE shop = 'Joe''s Shop' AND product = 'Coke';
UPDATE Sells SET price = 3.03 WHERE shop = 'Joe''s Shop' AND product = 'Sprite';
COMMIT;

-- Solution: Use proper transactions
-- Terminal 1:
BEGIN;
UPDATE Sells SET price = price * 1.10 WHERE shop = 'Joe''s Shop';
COMMIT; -- All or nothing

-- Terminal 2:
BEGIN;
SELECT MAX(price) as max_price, MIN(price) as min_price
FROM Sells WHERE shop = 'Joe''s Shop';
COMMIT; -- Consistent view