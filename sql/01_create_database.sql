
DROP DATABASE IF EXISTS kaloba_ledger;

-- utf8mb4 stores any character (including Bemba/Nyanja names with accents).
CREATE DATABASE kaloba_ledger
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE kaloba_ledger;

SELECT 'Database kaloba_ledger created' AS status;
