
USE kaloba_ledger;

CREATE TABLE customer_types (
    type_id       INT            NOT NULL AUTO_INCREMENT,
    type_name     VARCHAR(20)    NOT NULL,
    credit_limit  DECIMAL(10,2)  NOT NULL,
    CONSTRAINT pk_customer_types       PRIMARY KEY (type_id),
    CONSTRAINT uq_customer_types_name  UNIQUE (type_name),
    CONSTRAINT chk_credit_limit_pos    CHECK (credit_limit > 0)
) ENGINE = InnoDB;


CREATE TABLE customers (
    customer_id  INT             NOT NULL AUTO_INCREMENT,
    full_name    VARCHAR(100)    NOT NULL,
    phone        VARCHAR(15)     NOT NULL,
    nrc_enc      VARBINARY(255)  NULL,
    type_id      INT             NOT NULL DEFAULT 1,
    area         VARCHAR(60)     NULL,
    is_active    BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_customers         PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_phone   UNIQUE (phone),
    CONSTRAINT fk_customers_type    FOREIGN KEY (type_id)
        REFERENCES customer_types (type_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    -- Zambian mobile format: +260 followed by 9 digits
    CONSTRAINT chk_phone_format     CHECK (phone REGEXP '^\\+260[0-9]{9}$'),
    CONSTRAINT chk_full_name_len    CHECK (CHAR_LENGTH(TRIM(full_name)) >= 3)
) ENGINE = InnoDB;


CREATE TABLE credit_sales (
    sale_id            INT            NOT NULL AUTO_INCREMENT,
    customer_id        INT            NOT NULL,
    items_description  VARCHAR(200)   NOT NULL,
    amount             DECIMAL(10,2)  NOT NULL,
    sale_date          DATE           NOT NULL,
    recorded_by        VARCHAR(100)   NOT NULL,
    is_voided          BOOLEAN        NOT NULL DEFAULT FALSE,
    void_reason        VARCHAR(200)   NULL,
    CONSTRAINT pk_credit_sales           PRIMARY KEY (sale_id),
    CONSTRAINT fk_credit_sales_customer  FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_sale_amount_pos       CHECK (amount > 0),
    -- a voided entry must have a reason
    CONSTRAINT chk_sale_void_reason      CHECK (is_voided = FALSE OR void_reason IS NOT NULL)
) ENGINE = InnoDB;

CREATE TABLE repayments (
    repayment_id    INT            NOT NULL AUTO_INCREMENT,
    customer_id     INT            NOT NULL,
    amount          DECIMAL(10,2)  NOT NULL,
    repayment_date  DATE           NOT NULL,
    recorded_by     VARCHAR(100)   NOT NULL,
    is_voided       BOOLEAN        NOT NULL DEFAULT FALSE,
    void_reason     VARCHAR(200)   NULL,
    CONSTRAINT pk_repayments            PRIMARY KEY (repayment_id),
    CONSTRAINT fk_repayments_customer   FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_repayment_amount_pos CHECK (amount > 0),
    CONSTRAINT chk_repay_void_reason    CHECK (is_voided = FALSE OR void_reason IS NOT NULL)
) ENGINE = InnoDB;


CREATE TABLE app_users (
    user_id        INT          NOT NULL AUTO_INCREMENT,
    username       VARCHAR(50)  NOT NULL,
    password_hash  CHAR(60)     NOT NULL,
    app_role       VARCHAR(20)  NOT NULL,
    is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_app_users          PRIMARY KEY (user_id),
    CONSTRAINT uq_app_users_username UNIQUE (username),
    CONSTRAINT chk_app_role          CHECK (app_role IN ('owner', 'helper', 'auditor'))
) ENGINE = InnoDB;


CREATE TABLE audit_log (
    audit_id     BIGINT        NOT NULL AUTO_INCREMENT,
    table_name   VARCHAR(50)   NOT NULL,
    action       ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    record_id    INT           NOT NULL,
    db_user      VARCHAR(100)  NOT NULL,
    action_time  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_values   JSON          NULL,
    new_values   JSON          NULL,
    CONSTRAINT pk_audit_log PRIMARY KEY (audit_id)
) ENGINE = InnoDB;


CREATE INDEX idx_sales_customer       ON credit_sales (customer_id, is_voided);
CREATE INDEX idx_repayments_customer  ON repayments  (customer_id, is_voided);
CREATE INDEX idx_audit_table_record   ON audit_log   (table_name, record_id);

SHOW TABLES;
