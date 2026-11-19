-- =============================================================
-- RecallChain — FRESH RESET for Presentation
-- Run this ONCE in MySQL Workbench before your presentation.
-- It keeps all products, batches, customers, sales, etc.
-- but wipes all recalls, notifications, and audit logs clean.
-- =============================================================

USE recallchain;

SET FOREIGN_KEY_CHECKS = 0;

-- 1. Remove all recall-related records (child tables first)
TRUNCATE TABLE recall_returns;
TRUNCATE TABLE notifications;
TRUNCATE TABLE audit_logs;
TRUNCATE TABLE recall_batches;
TRUNCATE TABLE recalls;

SET FOREIGN_KEY_CHECKS = 1;

-- 2. Reset every batch back to 'active' (some were marked 'recalled' by triggers)
UPDATE batches SET status = 'active';

-- 3. Quick sanity check — should all say 0 rows + all batches 'active'
SELECT 'recalls'        AS table_name, COUNT(*) AS row_count FROM recalls
UNION ALL
SELECT 'recall_batches', COUNT(*) FROM recall_batches
UNION ALL
SELECT 'recall_returns', COUNT(*) FROM recall_returns
UNION ALL
SELECT 'notifications',  COUNT(*) FROM notifications
UNION ALL
SELECT 'audit_logs',     COUNT(*) FROM audit_logs;

SELECT batch_id, batch_code, status FROM batches;
