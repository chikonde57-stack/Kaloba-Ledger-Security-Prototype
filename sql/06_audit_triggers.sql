
USE kaloba_ledger;

DROP TRIGGER IF EXISTS trg_credit_sales_ai;
DROP TRIGGER IF EXISTS trg_credit_sales_bu;
DROP TRIGGER IF EXISTS trg_credit_sales_au;
DROP TRIGGER IF EXISTS trg_credit_sales_bd;
DROP TRIGGER IF EXISTS trg_repayments_ai;
DROP TRIGGER IF EXISTS trg_repayments_bu;
DROP TRIGGER IF EXISTS trg_repayments_au;
DROP TRIGGER IF EXISTS trg_repayments_bd;
DROP TRIGGER IF EXISTS trg_customers_ai;
DROP TRIGGER IF EXISTS trg_customers_au;
DROP TRIGGER IF EXISTS trg_customer_types_au;
DROP TRIGGER IF EXISTS trg_audit_log_bu;
DROP TRIGGER IF EXISTS trg_audit_log_bd;

DELIMITER $$


CREATE TRIGGER trg_credit_sales_ai
AFTER INSERT ON credit_sales
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action, record_id, db_user, old_values, new_values)
    VALUES ('credit_sales', 'INSERT', NEW.sale_id, USER(), NULL,
            JSON_OBJECT('customer_id', NEW.customer_id,
                        'items',       NEW.items_description,
                        'amount',      NEW.amount,
                        'sale_date',   NEW.sale_date));
END$$


CREATE TRIGGER trg_credit_sales_bu
BEFORE UPDATE ON credit_sales
FOR EACH ROW
BEGIN
    IF OLD.is_voided = TRUE
       OR NEW.customer_id       <> OLD.customer_id
       OR NEW.amount            <> OLD.amount
       OR NEW.sale_date         <> OLD.sale_date
       OR NEW.items_description <> OLD.items_description
       OR NEW.recorded_by       <> OLD.recorded_by THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ledger entries cannot be edited. Use sp_void_entry to void a wrong entry.';
    END IF;
END$$

CREATE TRIGGER trg_credit_sales_au
AFTER UPDATE ON credit_sales
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action, record_id, db_user, old_values, new_values)
    VALUES ('credit_sales', 'UPDATE', NEW.sale_id, USER(),
            JSON_OBJECT('is_voided', OLD.is_voided, 'void_reason', OLD.void_reason, 'amount', OLD.amount),
            JSON_OBJECT('is_voided', NEW.is_voided, 'void_reason', NEW.void_reason, 'amount', NEW.amount));
END$$

CREATE TRIGGER trg_credit_sales_bd
BEFORE DELETE ON credit_sales
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Deleting credit sales is not allowed. Use sp_void_entry instead.';
END$$

CREATE TRIGGER trg_repayments_ai
AFTER INSERT ON repayments
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action, record_id, db_user, old_values, new_values)
    VALUES ('repayments', 'INSERT', NEW.repayment_id, USER(), NULL,
            JSON_OBJECT('customer_id',    NEW.customer_id,
                        'amount',         NEW.amount,
                        'repayment_date', NEW.repayment_date));
END$$

CREATE TRIGGER trg_repayments_bu
BEFORE UPDATE ON repayments
FOR EACH ROW
BEGIN
    IF OLD.is_voided = TRUE
       OR NEW.customer_id    <> OLD.customer_id
       OR NEW.amount         <> OLD.amount
       OR NEW.repayment_date <> OLD.repayment_date
       OR NEW.recorded_by    <> OLD.recorded_by THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ledger entries cannot be edited. Use sp_void_entry to void a wrong entry.';
    END IF;
END$$

CREATE TRIGGER trg_repayments_au
AFTER UPDATE ON repayments
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action, record_id, db_user, old_values, new_values)
    VALUES ('repayments', 'UPDATE', NEW.repayment_id, USER(),
            JSON_OBJECT('is_voided', OLD.is_voided, 'void_reason', OLD.void_reason, 'amount', OLD.amount),
            JSON_OBJECT('is_voided', NEW.is_voided, 'void_reason', NEW.void_reason, 'amount', NEW.amount));
END$$

CREATE TRIGGER trg_repayments_bd
BEFORE DELETE ON repayments
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Deleting repayments is not allowed. Use sp_void_entry instead.';
END$$


CREATE TRIGGER trg_customers_ai
AFTER INSERT ON customers
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action, record_id, db_user, old_values, new_values)
    VALUES ('customers', 'INSERT', NEW.customer_id, USER(), NULL,
            JSON_OBJECT('full_name', NEW.full_name, 'phone', NEW.phone,
                        'type_id',   NEW.type_id,   'area',  NEW.area,
                        'nrc_recorded', NEW.nrc_enc IS NOT NULL));
END$$

CREATE TRIGGER trg_customers_au
AFTER UPDATE ON customers
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action, record_id, db_user, old_values, new_values)
    VALUES ('customers', 'UPDATE', NEW.customer_id, USER(),
            JSON_OBJECT('full_name', OLD.full_name, 'phone', OLD.phone, 'type_id', OLD.type_id,
                        'area', OLD.area, 'is_active', OLD.is_active),
            JSON_OBJECT('full_name', NEW.full_name, 'phone', NEW.phone, 'type_id', NEW.type_id,
                        'area', NEW.area, 'is_active', NEW.is_active,
                        'nrc_changed', NOT (OLD.nrc_enc <=> NEW.nrc_enc)));
END$$


CREATE TRIGGER trg_customer_types_au
AFTER UPDATE ON customer_types
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, action, record_id, db_user, old_values, new_values)
    VALUES ('customer_types', 'UPDATE', NEW.type_id, USER(),
            JSON_OBJECT('type_name', OLD.type_name, 'credit_limit', OLD.credit_limit),
            JSON_OBJECT('type_name', NEW.type_name, 'credit_limit', NEW.credit_limit));
END$$


CREATE TRIGGER trg_audit_log_bu
BEFORE UPDATE ON audit_log
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The audit log is read-only.';
END$$

CREATE TRIGGER trg_audit_log_bd
BEFORE DELETE ON audit_log
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The audit log is read-only.';
END$$

DELIMITER ;

SELECT TRIGGER_NAME, ACTION_TIMING, EVENT_MANIPULATION, EVENT_OBJECT_TABLE
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'kaloba_ledger'
ORDER BY EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION;
