
USE kaloba_ledger;

-- Clean start (safe to re-run)
DROP USER IF EXISTS 'kl_owner'@'localhost', 'kl_helper'@'localhost',
                    'kl_auditor'@'localhost', 'kl_app'@'localhost';
DROP ROLE IF EXISTS 'role_owner', 'role_helper', 'role_auditor', 'role_app';


CREATE ROLE 'role_owner', 'role_helper', 'role_auditor', 'role_app';


GRANT SELECT ON kaloba_ledger.customers            TO 'role_owner';
GRANT SELECT ON kaloba_ledger.customer_types       TO 'role_owner';
GRANT SELECT ON kaloba_ledger.credit_sales         TO 'role_owner';
GRANT SELECT ON kaloba_ledger.repayments           TO 'role_owner';
GRANT SELECT ON kaloba_ledger.audit_log            TO 'role_owner';
GRANT SELECT ON kaloba_ledger.v_customer_directory TO 'role_owner';
GRANT SELECT ON kaloba_ledger.v_customer_balances  TO 'role_owner';
GRANT SELECT ON kaloba_ledger.v_debtors            TO 'role_owner';
GRANT SELECT ON kaloba_ledger.v_customer_history   TO 'role_owner';
GRANT INSERT ON kaloba_ledger.customers            TO 'role_owner';

GRANT UPDATE (full_name, phone, nrc_enc, area, is_active)
             ON kaloba_ledger.customers            TO 'role_owner';
GRANT UPDATE (credit_limit) ON kaloba_ledger.customer_types TO 'role_owner';
GRANT EXECUTE ON PROCEDURE kaloba_ledger.sp_record_credit_sale TO 'role_owner';
GRANT EXECUTE ON PROCEDURE kaloba_ledger.sp_record_repayment   TO 'role_owner';
GRANT EXECUTE ON PROCEDURE kaloba_ledger.sp_void_entry         TO 'role_owner';
GRANT EXECUTE ON PROCEDURE kaloba_ledger.sp_set_customer_type  TO 'role_owner';

GRANT SELECT ON kaloba_ledger.customer_types       TO 'role_helper';
GRANT SELECT ON kaloba_ledger.credit_sales         TO 'role_helper';
GRANT SELECT ON kaloba_ledger.repayments           TO 'role_helper';
GRANT SELECT ON kaloba_ledger.v_customer_directory TO 'role_helper';
GRANT SELECT ON kaloba_ledger.v_customer_balances  TO 'role_helper';
GRANT SELECT ON kaloba_ledger.v_debtors            TO 'role_helper';
GRANT SELECT ON kaloba_ledger.v_customer_history   TO 'role_helper';

GRANT INSERT (full_name, phone, area) ON kaloba_ledger.customers TO 'role_helper';
GRANT EXECUTE ON PROCEDURE kaloba_ledger.sp_record_credit_sale TO 'role_helper';
GRANT EXECUTE ON PROCEDURE kaloba_ledger.sp_record_repayment   TO 'role_helper';

GRANT SELECT ON kaloba_ledger.customers            TO 'role_auditor';
GRANT SELECT ON kaloba_ledger.customer_types       TO 'role_auditor';
GRANT SELECT ON kaloba_ledger.credit_sales         TO 'role_auditor';
GRANT SELECT ON kaloba_ledger.repayments           TO 'role_auditor';
GRANT SELECT ON kaloba_ledger.audit_log            TO 'role_auditor';
GRANT SELECT ON kaloba_ledger.v_customer_directory TO 'role_auditor';
GRANT SELECT ON kaloba_ledger.v_customer_balances  TO 'role_auditor';
GRANT SELECT ON kaloba_ledger.v_debtors            TO 'role_auditor';
GRANT SELECT ON kaloba_ledger.v_customer_history   TO 'role_auditor';


GRANT SELECT ON kaloba_ledger.v_customer_directory TO 'role_app';
GRANT SELECT ON kaloba_ledger.v_customer_balances  TO 'role_app';
GRANT SELECT ON kaloba_ledger.app_users            TO 'role_app';


CREATE USER 'kl_owner'@'localhost'   IDENTIFIED BY 'Owner#Kaloba2026!'
    FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1;
CREATE USER 'kl_helper'@'localhost'  IDENTIFIED BY 'Helper#Kaloba2026!'
    FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1;
CREATE USER 'kl_auditor'@'localhost' IDENTIFIED BY 'Auditor#Kaloba2026!'
    FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1;
CREATE USER 'kl_app'@'localhost'     IDENTIFIED BY 'App#Kaloba2026!'
    FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1;

GRANT 'role_owner'   TO 'kl_owner'@'localhost';
GRANT 'role_helper'  TO 'kl_helper'@'localhost';
GRANT 'role_auditor' TO 'kl_auditor'@'localhost';
GRANT 'role_app'     TO 'kl_app'@'localhost';

SET DEFAULT ROLE 'role_owner'   TO 'kl_owner'@'localhost';
SET DEFAULT ROLE 'role_helper'  TO 'kl_helper'@'localhost';
SET DEFAULT ROLE 'role_auditor' TO 'kl_auditor'@'localhost';
SET DEFAULT ROLE 'role_app'     TO 'kl_app'@'localhost';


SELECT user, host, account_locked FROM mysql.user WHERE user LIKE 'kl\_%' OR user LIKE 'role\_%' ORDER BY user;
SHOW GRANTS FOR 'kl_helper'@'localhost' USING 'role_helper';
