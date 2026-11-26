
USE kaloba_ledger;

CREATE OR REPLACE VIEW v_customer_directory AS
SELECT c.customer_id,
       c.full_name,
       c.phone,
       t.type_name,
       c.area,
       c.is_active
FROM customers c
JOIN customer_types t ON t.type_id = c.type_id;


CREATE OR REPLACE VIEW v_customer_balances AS
SELECT c.customer_id,
       c.full_name,
       c.phone,
       t.type_name,
       t.credit_limit,
       COALESCE(s.total_credit, 0)                                 AS total_credit,
       COALESCE(r.total_repaid, 0)                                 AS total_repaid,
       COALESCE(s.total_credit, 0) - COALESCE(r.total_repaid, 0)   AS balance,
       t.credit_limit
         - (COALESCE(s.total_credit, 0) - COALESCE(r.total_repaid, 0)) AS available_credit,
       c.is_active
FROM customers c
JOIN customer_types t ON t.type_id = c.type_id
LEFT JOIN (SELECT customer_id, SUM(amount) AS total_credit
           FROM credit_sales
           WHERE is_voided = FALSE
           GROUP BY customer_id) s ON s.customer_id = c.customer_id
LEFT JOIN (SELECT customer_id, SUM(amount) AS total_repaid
           FROM repayments
           WHERE is_voided = FALSE
           GROUP BY customer_id) r ON r.customer_id = c.customer_id;


CREATE OR REPLACE VIEW v_debtors AS
SELECT customer_id, full_name, phone, type_name, balance, is_active
FROM v_customer_balances
WHERE balance > 0
ORDER BY balance DESC;


CREATE OR REPLACE VIEW v_customer_history AS
SELECT s.customer_id, c.full_name, 'CREDIT SALE' AS entry_type, s.sale_id AS entry_id,
       s.sale_date AS entry_date, s.items_description AS description, s.amount,
       s.recorded_by, s.is_voided, s.void_reason
FROM credit_sales s
JOIN customers c ON c.customer_id = s.customer_id
UNION ALL
SELECT r.customer_id, c.full_name, 'REPAYMENT', r.repayment_id,
       r.repayment_date, 'Repayment received', r.amount,
       r.recorded_by, r.is_voided, r.void_reason
FROM repayments r
JOIN customers c ON c.customer_id = r.customer_id;

SELECT customer_id, full_name, type_name, credit_limit, total_credit,
       total_repaid, balance, available_credit
FROM v_customer_balances
ORDER BY customer_id;
