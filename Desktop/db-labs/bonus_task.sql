CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin VARCHAR(12) UNIQUE NOT NULL CHECK (iin ~ '^[0-9]{12}$'),
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    status VARCHAR(20) CHECK (status IN ('active', 'blocked', 'frozen')) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt DECIMAL(15,2) DEFAULT 5000000.00);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number VARCHAR(34) UNIQUE NOT NULL,
    currency VARCHAR(3) CHECK (currency IN ('KZT', 'USD', 'EUR', 'RUB')),
    balance DECIMAL(15,2) DEFAULT 0.00 CHECK (balance >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    CONSTRAINT chk_closed CHECK ((is_active = true AND closed_at IS NULL) OR
                                 (is_active = false AND closed_at IS NOT NULL)));

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(15,6) NOT NULL,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP DEFAULT '9999-12-31 23:59:59');

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INTEGER REFERENCES accounts(account_id),
    to_account_id INTEGER REFERENCES accounts(account_id),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    currency VARCHAR(3) NOT NULL,
    exchange_rate DECIMAL(15,6) DEFAULT 1.0,
    amount_kzt DECIMAL(15,2) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('transfer', 'deposit', 'withdrawal')),
    status VARCHAR(20) CHECK (status IN ('pending', 'completed', 'failed', 'reversed')) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    description TEXT,
    CONSTRAINT chk_accounts CHECK (from_account_id != to_account_id OR from_account_id IS NULL));

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    action VARCHAR(10) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100) DEFAULT CURRENT_USER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET);

CREATE INDEX idx_accounts_customer ON accounts(customer_id);
CREATE INDEX idx_accounts_number ON accounts(account_number);
CREATE INDEX idx_transactions_from ON transactions(from_account_id, created_at);
CREATE INDEX idx_transactions_to ON transactions(to_account_id, created_at);
CREATE INDEX idx_transactions_created ON transactions(created_at DESC);
CREATE INDEX idx_exchange_rates_current ON exchange_rates(valid_from DESC, valid_to DESC);
CREATE INDEX idx_customers_iin ON customers(iin);
CREATE INDEX idx_audit_record ON audit_log(table_name, record_id);

CREATE OR REPLACE FUNCTION log_audit_trail()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log (table_name, record_id, action, new_values)
        VALUES (TG_TABLE_NAME, NEW.customer_id, 'INSERT', to_jsonb(NEW));
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values)
        VALUES (TG_TABLE_NAME, NEW.customer_id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values)
        VALUES (TG_TABLE_NAME, OLD.customer_id, 'DELETE', to_jsonb(OLD));
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_customers_audit
AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER trg_accounts_audit
AFTER INSERT OR UPDATE OR DELETE ON accounts
FOR EACH ROW EXECUTE FUNCTION log_audit_trail();

CREATE TRIGGER trg_transactions_audit
AFTER INSERT OR UPDATE OR DELETE ON transactions
FOR EACH ROW EXECUTE FUNCTION log_audit_trail();


INSERT INTO customers (iin, full_name, phone, email, daily_limit_kzt) VALUES
('123456789012', 'Алиев Али Алиевич', '+77011234567', 'ali@mail.kz', 10000000.00),
('234567890123', 'Берик Болат Болатович', '+77022345678', 'berik@mail.kz', 7500000.00),
('345678901234', 'Сара Самал Самаловна', '+77033456789', 'sara@mail.kz', 5000000.00),
('456789012345', 'Дамир Досым Досымович', '+77044567890', 'damir@mail.kz', 3000000.00),
('567890123456', 'Ерке Ерлан Ерланович', '+77055678901', 'yerke@mail.kz', 8000000.00);

INSERT INTO accounts (customer_id, account_number, currency, balance) VALUES
(1, 'KZ12345678901234567890', 'KZT', 5000000.00),
(1, 'KZ09876543210987654321', 'USD', 50000.00),
(2, 'KZ23456789012345678901', 'KZT', 2000000.00),
(2, 'KZ34567890123456789012', 'EUR', 30000.00),
(3, 'KZ45678901234567890123', 'KZT', 1000000.00),
(4, 'KZ56789012345678901234', 'USD', 15000.00),
(5, 'KZ67890123456789012345', 'KZT', 8000000.00);

INSERT INTO exchange_rates (from_currency, to_currency, rate) VALUES
('USD', 'KZT', 450.50),
('KZT', 'USD', 0.00222),
('EUR', 'KZT', 490.25),
('KZT', 'EUR', 0.00204),
('RUB', 'KZT', 5.10),
('KZT', 'RUB', 0.196),
('USD', 'EUR', 0.92),
('EUR', 'USD', 1.087);

INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, completed_at) VALUES
(1, 3, 100000.00, 'KZT', 1.0, 100000.00, 'transfer', 'completed', NOW() - INTERVAL '1 day'),
(2, 4, 1000.00, 'USD', 450.50, 450500.00, 'transfer', 'completed', NOW() - INTERVAL '2 hours'),
(5, 1, 500000.00, 'KZT', 1.0, 500000.00, 'transfer', 'completed', NOW() - INTERVAL '1 hour');


--Tassk 1
CREATE OR REPLACE PROCEDURE process_transfer(
    p_from_account TEXT,
    p_to_account TEXT,
    p_amount NUMERIC,
    p_currency TEXT,
    p_description TEXT
)
LANGUAGE plpgsql
AS $procedure$
DECLARE
    v_from_account_id INT;
    v_to_account_id INT;

    v_from_customer INT;
    v_to_customer INT;

    v_from_balance NUMERIC;
    v_from_currency TEXT;
    v_to_currency TEXT;

    v_status TEXT;
    v_daily_limit NUMERIC;
    v_used_today NUMERIC;

    v_rate NUMERIC := 1;
    v_amount_kzt NUMERIC;


BEGIN
    SAVEPOINT before;
--1
    SELECT account_id, customer_id, balance, currency
    INTO v_from_account_id, v_from_customer, v_from_balance, v_from_currency
    FROM accounts
    WHERE account_number = p_from_account AND is_active = true
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Sender account not found';
    END IF;

    SAVEPOINT before_2;

--2
   SELECT account_id, customer_id, currency
    INTO v_to_account_id, v_to_customer, v_to_currency
    FROM accounts
    WHERE account_number = p_to_account AND is_active = true
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Receiver account not found';
    END IF;

        SAVEPOINT before_3;

--3
     SELECT status, daily_limit_kzt
    INTO v_status, v_daily_limit
    FROM customers
    WHERE customer_id = v_from_customer;

    IF v_status <> 'active' THEN
        RAISE EXCEPTION 'Customer is not active';
    END IF;

        SAVEPOINT before_4;


    -- 4
     SELECT COALESCE(SUM(amount_kzt), 0)
    INTO v_used_today
    FROM transactions
    WHERE from_account_id = v_from_account_id
      AND created_at::date = CURRENT_DATE
      AND status = 'completed';

    IF p_currency = 'KZT' THEN
        v_amount_kzt := p_amount;
    ELSE
        SELECT rate INTO v_rate
        FROM exchange_rates
        WHERE from_currency = p_currency AND to_currency = 'KZT'
        LIMIT 1;

        IF v_rate IS NULL THEN
            RAISE EXCEPTION 'No exchange rate for % → KZT', p_currency;
        END IF;

        v_amount_kzt := p_amount * v_rate;
    END IF;

    IF v_used_today + v_amount_kzt > v_daily_limit THEN
        RAISE EXCEPTION 'Daily limit exceeded';
    END IF;

        SAVEPOINT before_5;


  --5
    IF v_from_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;


        SAVEPOINT before_6;


    --6
    IF v_from_currency <> v_to_currency THEN
        SELECT rate INTO v_rate
        FROM exchange_rates
        WHERE from_currency = v_from_currency AND to_currency = v_to_currency
        LIMIT 1;

        IF v_rate IS NULL THEN
            RAISE EXCEPTION 'No conversion rate % → %', v_from_currency, v_to_currency;
        END IF;

        p_amount := p_amount * v_rate;
    END IF;

        SAVEPOINT before_7;


    --7
    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = v_from_account_id;

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = v_to_account_id;

        SAVEPOINT before_8;


    --8

    INSERT INTO transactions(
        from_account_id, to_account_id, amount, currency,
        exchange_rate, amount_kzt, type, status, created_at, description
    )
    VALUES (
        v_from_account_id, v_to_account_id, p_amount, p_currency,
        v_rate, v_amount_kzt, 'transfer', 'completed', NOW(), p_description
    );

        SAVEPOINT before_9;


    --9
    INSERT INTO audit_log(table_name, record_id, action, new_values)
    VALUES (
        'transactions',
        currval('transactions_transaction_id_seq'),
        'INSERT',
        jsonb_build_object(
            'from', p_from_account,
            'to', p_to_account,
            'amount', p_amount
        )
    );

END;
$procedure$;

CALL process_transfer(
    'KZ12345678901234567890',
    'KZ23456789012345678901',
    50000,
    'KZT',
    'Test transfer'
);

--Task 2
CREATE OR REPLACE VIEW customer_balance_summary AS
WITH acc_converted AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.daily_limit_kzt,
        a.account_id,
        a.account_number,
        a.currency,
        a.balance,
        CASE
            WHEN a.currency = 'KZT' THEN a.balance
            ELSE a.balance * (
                SELECT rate
                FROM exchange_rates
                WHERE from_currency = a.currency
                  AND to_currency = 'KZT'
                ORDER BY valid_from DESC
                LIMIT 1
            )
        END AS balance_kzt
    FROM customers c
    LEFT JOIN accounts a ON c.customer_id = a.customer_id
),
total_per_customer AS (
    SELECT
        customer_id,
        SUM(balance_kzt) AS total_balance_kzt
    FROM acc_converted
    GROUP BY customer_id
)
SELECT
    ac.customer_id,
    ac.full_name,
    ac.account_id,
    ac.account_number,
    ac.currency,
    ac.balance,
    ac.balance_kzt,
    ac.daily_limit_kzt,
    t.total_balance_kzt,
    ROUND((t.total_balance_kzt / ac.daily_limit_kzt) * 100, 2)
        AS limit_usage_percent,
    RANK() OVER (ORDER BY t.total_balance_kzt DESC) AS balance_rank
FROM acc_converted ac
JOIN total_per_customer t USING (customer_id)
ORDER BY ac.customer_id, ac.account_id;

CREATE OR REPLACE VIEW daily_transaction_report AS
WITH base AS (
    SELECT
        DATE(created_at) AS tx_date,
        type,
        SUM(amount_kzt) AS total_volume,
        COUNT(*) AS tx_count,
        AVG(amount_kzt) AS avg_amount
    FROM transactions
    WHERE status = 'completed'
    GROUP BY DATE(created_at), type
)
SELECT
    tx_date,
    type,
    total_volume,
    tx_count,
    avg_amount,
    SUM(total_volume) OVER (PARTITION BY type ORDER BY tx_date) AS running_total,
    ROUND(
        (total_volume - LAG(total_volume) OVER (PARTITION BY type ORDER BY tx_date))
        / NULLIF(LAG(total_volume) OVER (PARTITION BY type ORDER BY tx_date), 0)
        * 100,
        2
    ) AS day_over_day_growth
FROM base
ORDER BY tx_date, type;


CREATE OR REPLACE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
WITH tx AS (
    SELECT
        t.*,
        a.customer_id
    FROM transactions t
    JOIN accounts a ON t.from_account_id = a.account_id
)
SELECT
    transaction_id,
    customer_id,
    from_account_id,
    to_account_id,
    amount_kzt,
    created_at,
    CASE WHEN amount_kzt > 5000000 THEN true ELSE false END AS high_value_flag,
    COUNT(*) OVER (
        PARTITION BY customer_id, DATE_TRUNC('hour', created_at)
    ) > 10 AS high_frequency_flag,
    CASE
        WHEN EXTRACT(EPOCH FROM (created_at - LAG(created_at) OVER (
                PARTITION BY customer_id ORDER BY created_at
            ))) < 60
        THEN true ELSE false
    END AS rapid_sequence_flag
FROM tx;



--task 3
CREATE INDEX idx_accounts_account_number
ON accounts(account_number);

EXPLAIN ANALYZE
SELECT *
FROM accounts
WHERE account_number = 'KZ12345678901234567890';

--BEFORE
--Seq Scan on accounts  (cost=0.00..1.09 rows=1 width=145) (actual time=0.666..0.668 rows=1 loops=1)
--Filter: ((account_number)::text = 'KZ12345678901234567890'::text)
--Rows Removed by Filter: 6
--Planning Time: 11.340 ms
--Execution Time: 1.694 ms

--AFTER
--Seq Scan on accounts  (cost=0.00..1.09 rows=1 width=145) (actual time=0.017..0.017 rows=1 loops=1)
-- Filter: ((account_number)::text = 'KZ12345678901234567890'::text)
-- --Rows Removed by Filter: 6
--Planning Time: 2.208 ms
--Execution Time: 0.033 ms


CREATE INDEX idx_customers_iin_hash
ON customers USING hash (iin);

EXPLAIN ANALYZE
SELECT * FROM customers
WHERE iin = '123456789012';


--BEFORE
--Seq Scan on customers  (cost=0.00..1.06 rows=1 width=624) (actual time=0.236..0.237 rows=1 loops=1)
--Filter: ((iin)::text = '123456789012'::text)
--Rows Removed by Filter: 4
--Planning Time: 3.029 ms
--Execution Time: 0.274 ms

--AFTER
--Seq Scan on customers  (cost=0.00..1.06 rows=1 width=624) (actual time=0.015..0.016 rows=1 loops=1)
--Filter: ((iin)::text = '123456789012'::text)
--Rows Removed by Filter: 4
--Planning Time: 1.189 ms
--Execution Time: 0.032 ms


CREATE INDEX idx_audit_newvalues_gin
ON audit_log USING gin (new_values);

EXPLAIN ANALYZE
SELECT * FROM audit_log
WHERE new_values ? 'amount';

--BEFORE
--Seq Scan on audit_log  (cost=0.00..2.16 rows=1 width=486) (actual time=0.733..0.734 rows=1 loops=1)
--Filter: (new_values ? 'amount'::text)
--Rows Removed by Filter: 12
--Planning Time: 1.901 ms
--Execution Time: 0.748 ms

--AFTER
--Seq Scan on audit_log  (cost=0.00..2.16 rows=1 width=486) (actual time=0.020..0.021 rows=1 loops=1)
--Filter: (new_values ? 'amount'::text)
--Rows Removed by Filter: 12
--Planning Time: 155.290 ms
--Execution Time: 0.036 ms


CREATE INDEX idx_accounts_active_only
ON accounts(customer_id)
WHERE is_active = true;

EXPLAIN ANALYZE
SELECT * FROM accounts
WHERE customer_id = 1 AND is_active = true;

--BEFORE
--Seq Scan on accounts  (cost=0.00..1.09 rows=1 width=145) (actual time=0.036..0.037 rows=2 loops=1)
--Filter: (is_active AND (customer_id = 1))R
--Rows Removed by Filter: 5
--Planning Time: 0.154 ms
--Execution Time: 0.069 ms

--AFTER
--Seq Scan on accounts  (cost=0.00..1.09 rows=1 width=145) (actual time=0.017..0.019 rows=2 loops=1)
--Filter: (is_active AND (customer_id = 1))
--Rows Removed by Filter: 5
--Planning Time: 4.494 ms
--Execution Time: 0.035 ms


CREATE INDEX idx_tx_from_created_desc
ON transactions(from_account_id, created_at DESC);

EXPLAIN ANALYZE
SELECT amount, amount_kzt, status
FROM transactions
WHERE from_account_id = 1
ORDER BY created_at DESC;

--BEFORE
--Sort  (cost=1.02..1.03 rows=1 width=102) (actual time=0.347..0.347 rows=1 loops=1)
--Sort Key: created_at DESC
--Sort Method: quicksort  Memory: 25kB
--->  Seq Scan on transactions  (cost=0.00..1.01 rows=1 width=102) (actual time=0.042..0.042 rows=1 loops=1)
--Filter: (from_account_id = 1)
--Planning Time: 2.525 ms
--Execution Time: 0.386 ms


--AFTER
--Sort  (cost=1.02..1.03 rows=1 width=102) (actual time=0.030..0.030 rows=1 loops=1)
--Sort Key: created_at DESC
--Sort Method: quicksort  Memory: 25kB
--->  Seq Scan on transactions  (cost=0.00..1.01 rows=1 width=102) (actual time=0.011..0.011 rows=1 loops=1)
-- --Filter: (from_account_id = 1)
--Planning Time: 1.231 ms
--Execution Time: 0.044 ms



CREATE INDEX idx_customers_email_lower
ON customers(LOWER(email));

EXPLAIN ANALYZE
SELECT * FROM customers
WHERE LOWER(email) = 'sara@mail.kz';

--BEFORE
--Seq Scan on customers  (cost=0.00..1.07 rows=1 width=624) (actual time=1.409..1.411 rows=1 loops=1)
--Filter: (lower((email)::text) = 'sara@mail.kz'::text)
-- --Rows Removed by Filter: 4
--Planning Time: 0.151 ms
--Execution Time: 1.428 ms

--AFTER
--Seq Scan on customers  (cost=0.00..1.07 rows=1 width=624) (actual time=0.026..0.027 rows=1 loops=1)
--Filter: (lower((email)::text) = 'sara@mail.kz'::text)
--Rows Removed by Filter: 4
--Planning Time: 2.218 ms
--Execution Time: 0.043 ms

--Task 4
CREATE OR REPLACE PROCEDURE process_salary_batch(
    p_company_account TEXT,
    p_payments JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_id INT;
    v_company_balance NUMERIC;
    v_company_currency TEXT;

    v_total_required NUMERIC := 0;

    item JSONB;
    emp_iin TEXT;
    emp_amount NUMERIC;
    emp_description TEXT;

    v_emp_account_id INT;
    v_emp_currency TEXT;

    v_success INT := 0;
    v_failed INT := 0;
    v_failed_list JSONB := '[]'::jsonb;

    v_rate NUMERIC;
    v_amount_kzt NUMERIC;
BEGIN
    PERFORM pg_advisory_xact_lock(9999);

    SELECT account_id, balance, currency
    INTO v_company_id, v_company_balance, v_company_currency
    FROM accounts
    WHERE account_number = p_company_account AND is_active = TRUE
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Company account not found or inactive';
    END IF;

    FOR item IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        v_total_required := v_total_required + (item->>'amount')::NUMERIC;
    END LOOP;

    IF v_total_required > v_company_balance THEN
        RAISE EXCEPTION 'Insufficient company balance for salary batch';
    END IF;

    FOR item IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        SAVEPOINT sp_salary;

        emp_iin := item->>'iin';
        emp_amount := (item->>'amount')::NUMERIC;
        emp_description := item->>'description';

        BEGIN
            SELECT a.account_id, a.currency
            INTO v_emp_account_id, v_emp_currency
            FROM customers c
            JOIN accounts a ON a.customer_id = c.customer_id
            WHERE c.iin = emp_iin
              AND a.is_active = TRUE
            LIMIT 1
            FOR UPDATE;

            IF NOT FOUND THEN
                v_failed := v_failed + 1;
                v_failed_list := v_failed_list || jsonb_build_object(
                    'iin', emp_iin,
                    'reason', 'Employee account not found'
                );
                ROLLBACK TO sp_salary;
                CONTINUE;
            END IF;

            IF v_company_currency = v_emp_currency THEN
                v_amount_kzt := emp_amount;
                v_rate := 1;
            ELSE
                SELECT rate
                INTO v_rate
                FROM exchange_rates
                WHERE from_currency = v_company_currency
                  AND to_currency = v_emp_currency
                  AND NOW() BETWEEN valid_from AND valid_to
                LIMIT 1;

                IF v_rate IS NULL THEN
                    v_failed := v_failed + 1;
                    v_failed_list := v_failed_list || jsonb_build_object(
                        'iin', emp_iin,
                        'reason', 'Exchange rate not found'
                    );
                    ROLLBACK TO sp_salary;
                    CONTINUE;
                END IF;

                v_amount_kzt := emp_amount * v_rate;
            END IF;

            UPDATE accounts
            SET balance = balance + emp_amount
            WHERE account_id = v_emp_account_id;

            INSERT INTO transactions(
                from_account_id, to_account_id, amount,
                currency, exchange_rate, amount_kzt,
                type, status, description, created_at, completed_at
            ) VALUES (
                v_company_id, v_emp_account_id, emp_amount,
                v_company_currency, v_rate, v_amount_kzt,
                'transfer', 'completed', emp_description, NOW(), NOW()
            );

            v_success := v_success + 1;

        EXCEPTION WHEN OTHERS THEN
            v_failed := v_failed + 1;
            v_failed_list := v_failed_list || jsonb_build_object(
                'iin', emp_iin,
                'reason', SQLERRM
            );
            ROLLBACK TO sp_salary;
        END;
    END LOOP;

    UPDATE accounts
    SET balance = balance - v_total_required
    WHERE account_id = v_company_id;

    RAISE NOTICE 'Batch completed: %, failures: %', v_success, v_failed;
    RAISE NOTICE 'Failed list: %', v_failed_list;

END;
$$;


