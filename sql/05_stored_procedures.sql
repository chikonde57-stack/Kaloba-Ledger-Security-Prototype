
USE kaloba_ledger;

DROP PROCEDURE IF EXISTS sp_record_credit_sale;
DROP PROCEDURE IF EXISTS sp_record_repayment;
DROP PROCEDURE IF EXISTS sp_void_entry;
DROP PROCEDURE IF EXISTS sp_set_customer_type;

DELIMITER $$


CREATE PROCEDURE sp_record_credit_sale (
    IN p_customer_id INT,
    IN p_items       VARCHAR(200),
    IN p_amount      DECIMAL(10,2)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_active   BOOLEAN       DEFAULT NULL;
    DECLARE v_type_id  INT           DEFAULT NULL;
    DECLARE v_limit    DECIMAL(10,2) DEFAULT 0;
    DECLARE v_balance  DECIMAL(10,2) DEFAULT 0;
    DECLARE v_msg      VARCHAR(255);

   
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;


    IF p_amount IS NULL OR p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Amount must be greater than zero';
    END IF;
    IF p_items IS NULL OR CHAR_LENGTH(TRIM(p_items)) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Items description is required';
    END IF;

    START TRANSACTION;


    SELECT is_active, type_id
      INTO v_active, v_type_id
      FROM customers
     WHERE customer_id = p_customer_id
       FOR UPDATE;

    IF v_active IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found';
    END IF;
    IF v_active = FALSE THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer account is inactive: credit not allowed';
    END IF;

    SELECT credit_limit INTO v_limit
      FROM customer_types WHERE type_id = v_type_id;

    
    SELECT (SELECT COALESCE(SUM(amount), 0) FROM credit_sales
             WHERE customer_id = p_customer_id AND is_voided = FALSE)
         - (SELECT COALESCE(SUM(amount), 0) FROM repayments
             WHERE customer_id = p_customer_id AND is_voided = FALSE)
      INTO v_balance;


    IF v_balance + p_amount > v_limit THEN
        SET v_msg = CONCAT('Credit limit exceeded: balance K', v_balance,
                           ' + sale K', p_amount, ' > limit K', v_limit);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    INSERT INTO credit_sales (customer_id, items_description, amount, sale_date, recorded_by)
    VALUES (p_customer_id, TRIM(p_items), p_amount, CURDATE(), USER());

    COMMIT;

    SELECT 'Credit sale recorded'          AS message,
           LAST_INSERT_ID()                AS sale_id,
           v_balance + p_amount            AS new_balance,
           v_limit - (v_balance + p_amount) AS available_credit;
END$$


CREATE PROCEDURE sp_record_repayment (
    IN p_customer_id INT,
    IN p_amount      DECIMAL(10,2)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_found    INT           DEFAULT NULL;
    DECLARE v_balance  DECIMAL(10,2) DEFAULT 0;
    DECLARE v_msg      VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_amount IS NULL OR p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Amount must be greater than zero';
    END IF;

    START TRANSACTION;

    SELECT customer_id INTO v_found
      FROM customers
     WHERE customer_id = p_customer_id
       FOR UPDATE;

    IF v_found IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found';
    END IF;

    SELECT (SELECT COALESCE(SUM(amount), 0) FROM credit_sales
             WHERE customer_id = p_customer_id AND is_voided = FALSE)
         - (SELECT COALESCE(SUM(amount), 0) FROM repayments
             WHERE customer_id = p_customer_id AND is_voided = FALSE)
      INTO v_balance;

    IF p_amount > v_balance THEN
        SET v_msg = CONCAT('Repayment of K', p_amount,
                           ' exceeds outstanding balance of K', v_balance);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
    END IF;

    INSERT INTO repayments (customer_id, amount, repayment_date, recorded_by)
    VALUES (p_customer_id, p_amount, CURDATE(), USER());

    COMMIT;

    SELECT 'Repayment recorded'    AS message,
           LAST_INSERT_ID()        AS repayment_id,
           v_balance - p_amount    AS new_balance;
END$$


CREATE PROCEDURE sp_void_entry (
    IN p_entry_type VARCHAR(10),
    IN p_entry_id   INT,
    IN p_reason     VARCHAR(200)
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_rows INT DEFAULT 0;

    IF p_reason IS NULL OR CHAR_LENGTH(TRIM(p_reason)) < 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A clear void reason (at least 5 characters) is required';
    END IF;

    IF UPPER(p_entry_type) = 'SALE' THEN
        UPDATE credit_sales
           SET is_voided = TRUE, void_reason = TRIM(p_reason)
         WHERE sale_id = p_entry_id AND is_voided = FALSE;
        SET v_rows = ROW_COUNT();   -- capture immediately: ROW_COUNT() changes after every statement
    ELSEIF UPPER(p_entry_type) = 'REPAYMENT' THEN
        UPDATE repayments
           SET is_voided = TRUE, void_reason = TRIM(p_reason)
         WHERE repayment_id = p_entry_id AND is_voided = FALSE;
        SET v_rows = ROW_COUNT();
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Entry type must be SALE or REPAYMENT';
    END IF;

    IF v_rows = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Entry not found or already voided';
    END IF;

    SELECT CONCAT(UPPER(p_entry_type), ' #', p_entry_id, ' voided') AS message;
END$$


CREATE PROCEDURE sp_set_customer_type (
    IN p_customer_id INT,
    IN p_type_id     INT
)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_new_limit DECIMAL(10,2) DEFAULT NULL;
    DECLARE v_found     INT           DEFAULT NULL;
    DECLARE v_balance   DECIMAL(10,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT credit_limit INTO v_new_limit
      FROM customer_types WHERE type_id = p_type_id;
    IF v_new_limit IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer type not found';
    END IF;

    START TRANSACTION;

    SELECT customer_id INTO v_found
      FROM customers WHERE customer_id = p_customer_id FOR UPDATE;
    IF v_found IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found';
    END IF;

    SELECT (SELECT COALESCE(SUM(amount), 0) FROM credit_sales
             WHERE customer_id = p_customer_id AND is_voided = FALSE)
         - (SELECT COALESCE(SUM(amount), 0) FROM repayments
             WHERE customer_id = p_customer_id AND is_voided = FALSE)
      INTO v_balance;

    IF v_balance > v_new_limit THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot change type: current balance is above the new credit limit';
    END IF;

    UPDATE customers SET type_id = p_type_id WHERE customer_id = p_customer_id;

    COMMIT;

    SELECT 'Customer type updated' AS message, p_customer_id AS customer_id,
           p_type_id AS new_type_id, v_new_limit AS new_credit_limit;
END$$

DELIMITER ;

SHOW PROCEDURE STATUS WHERE Db = 'kaloba_ledger';
