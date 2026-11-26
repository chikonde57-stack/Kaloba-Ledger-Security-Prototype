
USE kaloba_ledger;


SET @kl_key = UNHEX(SHA2('Kaloba#Demo#Key#2026', 256));


INSERT INTO customer_types (type_id, type_name, credit_limit) VALUES
    (1, 'Regular',    500.00),
    (2, 'Wholesale', 5000.00);

INSERT INTO customers (customer_id, full_name, phone, nrc_enc, type_id, area, is_active) VALUES
 (1,  'Chanda Mulenga',     '+260971000101', AES_ENCRYPT('204518/10/1', @kl_key), 1, 'Kalingalinga', TRUE),
 (2,  'Mwila Banda',        '+260962000202', AES_ENCRYPT('311742/11/1', @kl_key), 1, 'Mtendere',     TRUE),
 (3,  'Natasha Phiri',      '+260977000303', AES_ENCRYPT('158906/10/1', @kl_key), 1, 'Chelstone',    TRUE),
 (4,  'Bwalya Tembo',       '+260955000404', AES_ENCRYPT('402377/61/1', @kl_key), 1, 'Matero',       TRUE),
 (5,  'Mutale Zulu',        '+260976000505', AES_ENCRYPT('267153/10/1', @kl_key), 1, 'Kalingalinga', TRUE),
 (6,  'Joseph Lungu',       '+260965000606', AES_ENCRYPT('389021/31/1', @kl_key), 1, 'Chawama',      TRUE),
 (7,  'Grace Mwale',        '+260978000707', AES_ENCRYPT('190664/10/1', @kl_key), 1, 'Kabwata',      TRUE),
 (8,  'Peter Sakala',       '+260969000808', AES_ENCRYPT('275480/10/1', @kl_key), 2, 'Kalingalinga', TRUE),
 (9,  'Ruth Njobvu',        '+260974000909', AES_ENCRYPT('336912/51/1', @kl_key), 2, 'Mtendere',     TRUE),
 (10, 'Emmanuel Chileshe',  '+260957001010', AES_ENCRYPT('228745/10/1', @kl_key), 1, 'Garden',       FALSE);


INSERT INTO credit_sales (customer_id, items_description, amount, sale_date, recorded_by, is_voided, void_reason) VALUES
 (1,  '25kg breakfast mealie meal',                 320.00, '2026-10-05', 'sample_data', FALSE, NULL),
 (1,  '2L cooking oil, 2kg sugar',                  160.00, '2026-10-20', 'sample_data', FALSE, NULL),
 (2,  '10kg rice, 2kg kapenta',                     300.00, '2026-10-03', 'sample_data', FALSE, NULL),
 (3,  'Bread x4, 1kg sugar, tea leaves',             95.00, '2026-10-08', 'sample_data', FALSE, NULL),
 (3,  'Bread x4, 1kg sugar, tea leaves',             95.00, '2026-10-08', 'sample_data', TRUE,  'Recorded twice by mistake'),
 (3,  'Washing powder 2kg, bath soap x3',           125.00, '2026-10-22', 'sample_data', FALSE, NULL),
 (4,  '5kg kapenta',                                150.00, '2026-10-15', 'sample_data', FALSE, NULL),
 (5,  'Bread x2, tray of eggs',                      85.00, '2026-11-02', 'sample_data', FALSE, NULL),
 (6,  '25kg roller mealie meal',                    260.00, '2026-10-11', 'sample_data', FALSE, NULL),
 (8,  'Wholesale: 4 x 25kg mealie meal',           1200.00, '2026-10-02', 'sample_data', FALSE, NULL),
 (8,  'Wholesale: 2 x 20L cooking oil',            1400.00, '2026-10-16', 'sample_data', FALSE, NULL),
 (8,  'Wholesale: 50kg sugar',                      600.00, '2026-11-03', 'sample_data', FALSE, NULL),
 (9,  'Wholesale: 3 cartons bath soap',             750.00, '2026-10-06', 'sample_data', FALSE, NULL),
 (9,  'Wholesale: 10 x 2kg sugar',                 1000.00, '2026-10-19', 'sample_data', FALSE, NULL),
 (10, 'Bag of charcoal, candles',                    90.00, '2026-09-20', 'sample_data', FALSE, NULL);


INSERT INTO repayments (customer_id, amount, repayment_date, recorded_by) VALUES
 (1,   30.00, '2026-10-25', 'sample_data'),
 (2,  150.00, '2026-10-17', 'sample_data'),
 (2,  150.00, '2026-10-31', 'sample_data'),
 (3,  100.00, '2026-11-01', 'sample_data'),
 (6,   60.00, '2026-10-28', 'sample_data'),
 (8, 1000.00, '2026-10-30', 'sample_data'),
 (9,  750.00, '2026-10-26', 'sample_data'),
 (9, 1000.00, '2026-11-05', 'sample_data');


SELECT 'customer_types' AS table_name, COUNT(*) AS row_count FROM customer_types
UNION ALL SELECT 'customers',    COUNT(*) FROM customers
UNION ALL SELECT 'credit_sales', COUNT(*) FROM credit_sales
UNION ALL SELECT 'repayments',   COUNT(*) FROM repayments;
