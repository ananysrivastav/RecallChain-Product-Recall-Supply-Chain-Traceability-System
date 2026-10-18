DROP DATABASE IF EXISTS recallchain;
CREATE DATABASE recallchain CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE recallchain;
CREATE TABLE users (
    user_id        INT AUTO_INCREMENT PRIMARY KEY,
    full_name      VARCHAR(120) NOT NULL,
    email          VARCHAR(120) NOT NULL UNIQUE,
    password_hash  VARCHAR(255) NOT NULL,
    role           ENUM('admin','manufacturer','warehouse_manager','retailer','auditor') NOT NULL,
    is_active      TINYINT(1) NOT NULL DEFAULT 1,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE suppliers (
    supplier_id    INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(120) NOT NULL,
    email          VARCHAR(120) UNIQUE,
    phone          VARCHAR(20),
    address        VARCHAR(255),
    is_active      TINYINT(1) NOT NULL DEFAULT 1,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE manufacturers (
    manufacturer_id INT AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(120) NOT NULL,
    email           VARCHAR(120) UNIQUE,
    phone           VARCHAR(20),
    address         VARCHAR(255),
    is_active       TINYINT(1) NOT NULL DEFAULT 1,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
CREATE TABLE raw_materials (
    material_id    INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(120) NOT NULL UNIQUE,
    unit           VARCHAR(20) NOT NULL
) ENGINE=InnoDB;
CREATE TABLE products (
    product_id     INT AUTO_INCREMENT PRIMARY KEY,
    sku            VARCHAR(40) NOT NULL UNIQUE,
    name           VARCHAR(150) NOT NULL,
    category       VARCHAR(80),
    description    TEXT,
    is_active      TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;
CREATE TABLE warehouses (
    warehouse_id   INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(120) NOT NULL,
    location       VARCHAR(255),
    is_active      TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;
CREATE TABLE retailers (
    retailer_id    INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(120) NOT NULL,
    address        VARCHAR(255),
    is_active      TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;
CREATE TABLE customers (
    customer_id    INT AUTO_INCREMENT PRIMARY KEY,
    name           VARCHAR(120) NOT NULL,
    email          VARCHAR(120) UNIQUE,
    phone          VARCHAR(20),
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_customer_contact CHECK (email IS NOT NULL OR phone IS NOT NULL)
) ENGINE=InnoDB;
CREATE TABLE material_lots (
    lot_id         INT AUTO_INCREMENT PRIMARY KEY,
    lot_code       VARCHAR(40) NOT NULL UNIQUE,
    material_id    INT NOT NULL,
    supplier_id    INT NOT NULL,
    received_date  DATE NOT NULL,
    expiry_date    DATE,
    quantity       DECIMAL(12,2) NOT NULL,
    CONSTRAINT chk_lot_qty   CHECK (quantity > 0),
    CONSTRAINT chk_lot_dates CHECK (expiry_date IS NULL OR expiry_date > received_date),
    CONSTRAINT fk_lot_material FOREIGN KEY (material_id) REFERENCES raw_materials(material_id),
    CONSTRAINT fk_lot_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
) ENGINE=InnoDB;
CREATE TABLE batches (
    batch_id          INT AUTO_INCREMENT PRIMARY KEY,
    batch_code        VARCHAR(40) NOT NULL UNIQUE,
    product_id        INT NOT NULL,
    manufacturer_id   INT NOT NULL,
    production_date   DATE NOT NULL,
    expiry_date       DATE,
    quantity_produced INT NOT NULL,
    status            ENUM('active','quarantined','recalled') NOT NULL DEFAULT 'active',
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_batch_qty   CHECK (quantity_produced > 0),
    CONSTRAINT chk_batch_dates CHECK (expiry_date IS NULL OR expiry_date > production_date),
    CONSTRAINT fk_batch_product      FOREIGN KEY (product_id)      REFERENCES products(product_id),
    CONSTRAINT fk_batch_manufacturer FOREIGN KEY (manufacturer_id) REFERENCES manufacturers(manufacturer_id)
) ENGINE=InnoDB;
CREATE TABLE batch_materials (
    batch_id       INT NOT NULL,
    lot_id         INT NOT NULL,
    quantity_used  DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (batch_id, lot_id),
    CONSTRAINT chk_bm_qty CHECK (quantity_used > 0),
    CONSTRAINT fk_bm_batch FOREIGN KEY (batch_id) REFERENCES batches(batch_id),
    CONSTRAINT fk_bm_lot   FOREIGN KEY (lot_id)   REFERENCES material_lots(lot_id)
) ENGINE=InnoDB;
CREATE TABLE warehouse_receipts (
    receipt_id     INT AUTO_INCREMENT PRIMARY KEY,
    batch_id       INT NOT NULL,
    warehouse_id   INT NOT NULL,
    received_date  DATE NOT NULL,
    quantity       INT NOT NULL,
    CONSTRAINT chk_receipt_qty CHECK (quantity > 0),
    CONSTRAINT fk_receipt_batch     FOREIGN KEY (batch_id)     REFERENCES batches(batch_id),
    CONSTRAINT fk_receipt_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
) ENGINE=InnoDB;
CREATE TABLE warehouse_stock (
    warehouse_id     INT NOT NULL,
    batch_id         INT NOT NULL,
    quantity_on_hand INT NOT NULL DEFAULT 0,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (warehouse_id, batch_id),
    CONSTRAINT chk_wstock_qty CHECK (quantity_on_hand >= 0),
    CONSTRAINT fk_wstock_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    CONSTRAINT fk_wstock_batch     FOREIGN KEY (batch_id)     REFERENCES batches(batch_id)
) ENGINE=InnoDB;
CREATE TABLE shipments (
    shipment_id    INT AUTO_INCREMENT PRIMARY KEY,
    batch_id       INT NOT NULL,
    warehouse_id   INT NOT NULL,
    retailer_id    INT NOT NULL,
    shipment_date  DATE NOT NULL,
    quantity       INT NOT NULL,
    CONSTRAINT chk_shipment_qty CHECK (quantity > 0),
    CONSTRAINT fk_ship_batch     FOREIGN KEY (batch_id)     REFERENCES batches(batch_id),
    CONSTRAINT fk_ship_warehouse FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id),
    CONSTRAINT fk_ship_retailer  FOREIGN KEY (retailer_id)  REFERENCES retailers(retailer_id)
) ENGINE=InnoDB;
CREATE TABLE retailer_stock (
    retailer_id      INT NOT NULL,
    batch_id         INT NOT NULL,
    quantity_on_hand INT NOT NULL DEFAULT 0,
    updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (retailer_id, batch_id),
    CONSTRAINT chk_rstock_qty CHECK (quantity_on_hand >= 0),
    CONSTRAINT fk_rstock_retailer FOREIGN KEY (retailer_id) REFERENCES retailers(retailer_id),
    CONSTRAINT fk_rstock_batch    FOREIGN KEY (batch_id)    REFERENCES batches(batch_id)
) ENGINE=InnoDB;
CREATE TABLE sales (
    sale_id        INT AUTO_INCREMENT PRIMARY KEY,
    batch_id       INT NOT NULL,
    retailer_id    INT NOT NULL,
    customer_id    INT NOT NULL,
    sale_date      DATE NOT NULL,
    quantity       INT NOT NULL,
    CONSTRAINT chk_sale_qty CHECK (quantity > 0),
    CONSTRAINT fk_sale_batch    FOREIGN KEY (batch_id)    REFERENCES batches(batch_id),
    CONSTRAINT fk_sale_retailer FOREIGN KEY (retailer_id) REFERENCES retailers(retailer_id),
    CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;
CREATE TABLE recalls (
    recall_id      INT AUTO_INCREMENT PRIMARY KEY,
    reason         VARCHAR(255) NOT NULL,
    severity       ENUM('low','medium','high','critical') NOT NULL DEFAULT 'medium',
    source_lot_id  INT NULL,
    initiated_by   INT NULL,
    recall_date    DATE NOT NULL,
    closed_date    DATE NULL,
    status         ENUM('open','in_progress','closed') NOT NULL DEFAULT 'open',
    CONSTRAINT chk_recall_dates  CHECK (closed_date IS NULL OR closed_date >= recall_date),
    CONSTRAINT chk_recall_closed CHECK (status <> 'closed' OR closed_date IS NOT NULL),
    CONSTRAINT fk_recall_lot  FOREIGN KEY (source_lot_id) REFERENCES material_lots(lot_id),
    CONSTRAINT fk_recall_user FOREIGN KEY (initiated_by)  REFERENCES users(user_id)
) ENGINE=InnoDB;
CREATE TABLE recall_batches (
    recall_id      INT NOT NULL,
    batch_id       INT NOT NULL,
    PRIMARY KEY (recall_id, batch_id),
    CONSTRAINT fk_rb_recall FOREIGN KEY (recall_id) REFERENCES recalls(recall_id),
    CONSTRAINT fk_rb_batch  FOREIGN KEY (batch_id)  REFERENCES batches(batch_id)
) ENGINE=InnoDB;
CREATE TABLE recall_returns (
    return_id            INT AUTO_INCREMENT PRIMARY KEY,
    recall_id            INT NOT NULL,
    sale_id              INT NOT NULL,
    quantity             INT NOT NULL,
    resolution           ENUM('refund','replacement') NOT NULL,
    replacement_batch_id INT NULL,
    status               ENUM('requested','received','completed','rejected') NOT NULL DEFAULT 'requested',
    requested_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at         TIMESTAMP NULL,
    CONSTRAINT chk_return_qty   CHECK (quantity > 0),
    CONSTRAINT chk_return_repl  CHECK (resolution = 'replacement' OR replacement_batch_id IS NULL),
    CONSTRAINT fk_ret_recall FOREIGN KEY (recall_id)            REFERENCES recalls(recall_id),
    CONSTRAINT fk_ret_sale   FOREIGN KEY (sale_id)              REFERENCES sales(sale_id),
    CONSTRAINT fk_ret_batch  FOREIGN KEY (replacement_batch_id) REFERENCES batches(batch_id)
) ENGINE=InnoDB;
CREATE TABLE notifications (
    notification_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    recall_id       INT NOT NULL,
    sale_id         INT NOT NULL,
    customer_id     INT NOT NULL,
    channel         ENUM('email','sms') NOT NULL DEFAULT 'email',
    status          ENUM('pending','processing','sent','failed') NOT NULL DEFAULT 'pending',
    attempts        TINYINT UNSIGNED NOT NULL DEFAULT 0,
    last_error      VARCHAR(255) NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    sent_at         TIMESTAMP NULL,
    UNIQUE KEY uq_notification (recall_id, sale_id, channel),
    CONSTRAINT fk_notif_recall   FOREIGN KEY (recall_id)   REFERENCES recalls(recall_id),
    CONSTRAINT fk_notif_sale     FOREIGN KEY (sale_id)     REFERENCES sales(sale_id),
    CONSTRAINT fk_notif_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
) ENGINE=InnoDB;
CREATE TABLE audit_logs (
    audit_id       BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name     VARCHAR(64) NOT NULL,
    record_id      VARCHAR(64) NOT NULL,
    action         ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    old_values     JSON NULL,
    new_values     JSON NULL,
    changed_by     INT NULL,
    changed_at     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    CONSTRAINT fk_audit_user FOREIGN KEY (changed_by) REFERENCES users(user_id)
) ENGINE=InnoDB;
CREATE INDEX idx_batches_product_status ON batches(product_id, status);
CREATE INDEX idx_batches_expiry         ON batches(expiry_date);
CREATE INDEX idx_shipments_batch_retail ON shipments(batch_id, retailer_id);
CREATE INDEX idx_sales_batch_customer   ON sales(batch_id, customer_id);
CREATE INDEX idx_recalls_status_date    ON recalls(status, recall_date);
CREATE INDEX idx_notifications_queue    ON notifications(status, created_at);
CREATE INDEX idx_audit_record           ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_time             ON audit_logs(changed_at);
DELIMITER $$
CREATE FUNCTION fn_batch_is_blocked(p_batch_id INT) RETURNS TINYINT(1)
READS SQL DATA
BEGIN
    DECLARE v_status VARCHAR(20);
    SELECT status INTO v_status FROM batches WHERE batch_id = p_batch_id;
    RETURN COALESCE(v_status IN ('recalled','quarantined'), 0);
END$$
CREATE TRIGGER trg_receipts_bi BEFORE INSERT ON warehouse_receipts
FOR EACH ROW
BEGIN
    DECLARE v_produced INT DEFAULT 0;
    DECLARE v_received INT DEFAULT 0;
    IF fn_batch_is_blocked(NEW.batch_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch is recalled/quarantined: receipt blocked';
    END IF;
    SELECT quantity_produced INTO v_produced FROM batches WHERE batch_id = NEW.batch_id;
    SELECT COALESCE(SUM(quantity), 0) INTO v_received FROM warehouse_receipts WHERE batch_id = NEW.batch_id;
    IF v_received + NEW.quantity > v_produced THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Receipts exceed quantity produced for this batch';
    END IF;
END$$
CREATE TRIGGER trg_receipts_ai AFTER INSERT ON warehouse_receipts
FOR EACH ROW
BEGIN
    INSERT INTO warehouse_stock (warehouse_id, batch_id, quantity_on_hand)
    VALUES (NEW.warehouse_id, NEW.batch_id, NEW.quantity)
    ON DUPLICATE KEY UPDATE quantity_on_hand = quantity_on_hand + NEW.quantity;
END$$
CREATE TRIGGER trg_shipments_bi BEFORE INSERT ON shipments
FOR EACH ROW
BEGIN
    DECLARE v_stock INT DEFAULT 0;
    IF fn_batch_is_blocked(NEW.batch_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch is recalled/quarantined: shipment blocked';
    END IF;
    SELECT quantity_on_hand INTO v_stock FROM warehouse_stock
     WHERE warehouse_id = NEW.warehouse_id AND batch_id = NEW.batch_id FOR UPDATE;
    IF v_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient warehouse stock for this batch';
    END IF;
END$$
CREATE TRIGGER trg_shipments_ai AFTER INSERT ON shipments
FOR EACH ROW
BEGIN
    UPDATE warehouse_stock SET quantity_on_hand = quantity_on_hand - NEW.quantity
     WHERE warehouse_id = NEW.warehouse_id AND batch_id = NEW.batch_id;
    INSERT INTO retailer_stock (retailer_id, batch_id, quantity_on_hand)
    VALUES (NEW.retailer_id, NEW.batch_id, NEW.quantity)
    ON DUPLICATE KEY UPDATE quantity_on_hand = quantity_on_hand + NEW.quantity;
END$$
CREATE TRIGGER trg_sales_bi BEFORE INSERT ON sales
FOR EACH ROW
BEGIN
    DECLARE v_stock INT DEFAULT 0;
    IF fn_batch_is_blocked(NEW.batch_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Batch is recalled/quarantined: sale blocked';
    END IF;
    SELECT quantity_on_hand INTO v_stock FROM retailer_stock
     WHERE retailer_id = NEW.retailer_id AND batch_id = NEW.batch_id FOR UPDATE;
    IF v_stock < NEW.quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient retailer stock for this batch';
    END IF;
END$$
CREATE TRIGGER trg_sales_ai AFTER INSERT ON sales
FOR EACH ROW
BEGIN
    UPDATE retailer_stock SET quantity_on_hand = quantity_on_hand - NEW.quantity
     WHERE retailer_id = NEW.retailer_id AND batch_id = NEW.batch_id;
END$$
CREATE TRIGGER trg_recall_batches_ai AFTER INSERT ON recall_batches
FOR EACH ROW
BEGIN
    UPDATE batches SET status = 'recalled' WHERE batch_id = NEW.batch_id;
    INSERT INTO notifications (recall_id, sale_id, customer_id, channel)
    SELECT NEW.recall_id, s.sale_id, s.customer_id, IF(c.email IS NOT NULL, 'email', 'sms')
      FROM sales s JOIN customers c ON c.customer_id = s.customer_id
     WHERE s.batch_id = NEW.batch_id
    ON DUPLICATE KEY UPDATE attempts = attempts;
    INSERT INTO audit_logs (table_name, record_id, action, new_values, changed_by)
    VALUES ('recall_batches', CONCAT(NEW.recall_id, '-', NEW.batch_id), 'INSERT',
            JSON_OBJECT('recall_id', NEW.recall_id, 'batch_id', NEW.batch_id), @app_user_id);
END$$
CREATE TRIGGER trg_recalls_bu BEFORE UPDATE ON recalls
FOR EACH ROW
BEGIN
    IF NEW.status = 'closed' AND OLD.status <> 'closed' AND NEW.closed_date IS NULL THEN
        SET NEW.closed_date = CURDATE();
    END IF;
END$$
CREATE TRIGGER trg_returns_bi BEFORE INSERT ON recall_returns
FOR EACH ROW
BEGIN
    DECLARE v_sold INT DEFAULT 0;
    DECLARE v_prev INT DEFAULT 0;
    SELECT s.quantity INTO v_sold
      FROM sales s JOIN recall_batches rb ON rb.batch_id = s.batch_id
     WHERE s.sale_id = NEW.sale_id AND rb.recall_id = NEW.recall_id;
    IF v_sold = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'This sale is not part of the given recall';
    END IF;
    SELECT COALESCE(SUM(quantity), 0) INTO v_prev FROM recall_returns
     WHERE sale_id = NEW.sale_id AND status <> 'rejected';
    IF v_prev + NEW.quantity > v_sold THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Return quantity exceeds quantity sold';
    END IF;
    IF NEW.replacement_batch_id IS NOT NULL AND fn_batch_is_blocked(NEW.replacement_batch_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Replacement batch is recalled/quarantined';
    END IF;
END$$
CREATE TRIGGER trg_returns_bu BEFORE UPDATE ON recall_returns
FOR EACH ROW
BEGIN
    IF NEW.status = 'completed' AND OLD.status <> 'completed' AND NEW.completed_at IS NULL THEN
        SET NEW.completed_at = NOW();
    END IF;
END$$
CREATE TRIGGER trg_batches_au AFTER UPDATE ON batches
FOR EACH ROW
BEGIN
    IF NOT (OLD.status <=> NEW.status) THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('batches', NEW.batch_id, 'UPDATE',
                JSON_OBJECT('status', OLD.status), JSON_OBJECT('status', NEW.status), @app_user_id);
    END IF;
END$$
CREATE TRIGGER trg_recalls_ai AFTER INSERT ON recalls
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, new_values, changed_by)
    VALUES ('recalls', NEW.recall_id, 'INSERT',
            JSON_OBJECT('status', NEW.status, 'severity', NEW.severity, 'reason', NEW.reason), @app_user_id);
END$$
CREATE TRIGGER trg_recalls_au AFTER UPDATE ON recalls
FOR EACH ROW
BEGIN
    IF NOT (OLD.status <=> NEW.status) THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('recalls', NEW.recall_id, 'UPDATE',
                JSON_OBJECT('status', OLD.status), JSON_OBJECT('status', NEW.status), @app_user_id);
    END IF;
END$$
CREATE TRIGGER trg_returns_ai AFTER INSERT ON recall_returns
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, new_values, changed_by)
    VALUES ('recall_returns', NEW.return_id, 'INSERT',
            JSON_OBJECT('sale_id', NEW.sale_id, 'quantity', NEW.quantity,
                        'resolution', NEW.resolution, 'status', NEW.status), @app_user_id);
END$$
CREATE TRIGGER trg_returns_au AFTER UPDATE ON recall_returns
FOR EACH ROW
BEGIN
    IF NOT (OLD.status <=> NEW.status) THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values, changed_by)
        VALUES ('recall_returns', NEW.return_id, 'UPDATE',
                JSON_OBJECT('status', OLD.status), JSON_OBJECT('status', NEW.status), @app_user_id);
    END IF;
END$$
CREATE PROCEDURE sp_issue_recall(
    IN  p_batch_id  INT,
    IN  p_reason    VARCHAR(255),
    IN  p_severity  VARCHAR(10),
    IN  p_user_id   INT,
    OUT p_recall_id INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    SET @app_user_id = p_user_id;
    START TRANSACTION;
        INSERT INTO recalls (reason, severity, initiated_by, recall_date)
        VALUES (p_reason, p_severity, p_user_id, CURDATE());
        SET p_recall_id = LAST_INSERT_ID();
        INSERT INTO recall_batches (recall_id, batch_id) VALUES (p_recall_id, p_batch_id);
    COMMIT;
END$$
DELIMITER ;
CREATE VIEW vw_active_recalls AS
SELECT rc.recall_id, rc.severity, rc.status, rc.recall_date, rc.reason,
       b.batch_code, p.name AS product_name
FROM recalls rc
JOIN recall_batches rb ON rb.recall_id = rc.recall_id
JOIN batches b         ON b.batch_id   = rb.batch_id
JOIN products p        ON p.product_id = b.product_id
WHERE rc.status <> 'closed';
CREATE VIEW vw_recall_affected_customers AS
SELECT rb.recall_id, b.batch_code, s.sale_id, c.customer_id, c.name AS customer,
       c.email, c.phone, r.name AS retailer, s.sale_date, s.quantity
FROM recall_batches rb
JOIN batches b   ON b.batch_id    = rb.batch_id
JOIN sales s     ON s.batch_id    = b.batch_id
JOIN customers c ON c.customer_id = s.customer_id
JOIN retailers r ON r.retailer_id = s.retailer_id;
CREATE VIEW vw_recall_stock_exposure AS
SELECT rb.recall_id, b.batch_code, 'warehouse' AS location_type,
       w.name AS location_name, ws.quantity_on_hand
FROM recall_batches rb
JOIN batches b          ON b.batch_id      = rb.batch_id
JOIN warehouse_stock ws ON ws.batch_id     = b.batch_id
JOIN warehouses w       ON w.warehouse_id  = ws.warehouse_id
WHERE ws.quantity_on_hand > 0
UNION ALL
SELECT rb.recall_id, b.batch_code, 'retailer', r.name, rs.quantity_on_hand
FROM recall_batches rb
JOIN batches b         ON b.batch_id     = rb.batch_id
JOIN retailer_stock rs ON rs.batch_id    = b.batch_id
JOIN retailers r       ON r.retailer_id  = rs.retailer_id
WHERE rs.quantity_on_hand > 0;
CREATE VIEW vw_batch_raw_materials AS
SELECT b.batch_id, b.batch_code, rm.name AS material, ml.lot_id, ml.lot_code,
       sp.name AS supplier, bm.quantity_used, rm.unit
FROM batches b
JOIN batch_materials bm ON bm.batch_id    = b.batch_id
JOIN material_lots ml   ON ml.lot_id      = bm.lot_id
JOIN raw_materials rm   ON rm.material_id = ml.material_id
JOIN suppliers sp       ON sp.supplier_id = ml.supplier_id;
INSERT INTO users (full_name, email, password_hash, role) VALUES
('Admin User',        'admin@recallchain.test',   'CHANGE_ME_bcrypt_hash', 'admin'),
('Plant Manager',     'plant@recallchain.test',   'CHANGE_ME_bcrypt_hash', 'manufacturer'),
('Warehouse Manager', 'wh@recallchain.test',      'CHANGE_ME_bcrypt_hash', 'warehouse_manager');
SET @app_user_id = 1;
INSERT INTO suppliers (name, email, phone, address) VALUES
('Himalayan Raw Materials Pvt Ltd', 'contact@himraw.in',   '9876543210', 'Dehradun, Uttarakhand'),
('GreenLeaf Ingredients Co.',       'sales@greenleaf.com', '9123456780', 'Pune, Maharashtra');
INSERT INTO manufacturers (name, email, phone, address) VALUES
('Dev Bhoomi Herbals Pvt Ltd', 'plant@devbhoomi.in', '9811100001', 'Dehradun, Uttarakhand'),
('PureHive Foods Pvt Ltd',     'ops@purehive.in',    '9811100002', 'Pune, Maharashtra');
INSERT INTO raw_materials (name, unit) VALUES
('Aloe Vera Extract', 'kg'), ('Neem Extract', 'kg'), ('Raw Forest Honey', 'kg');
INSERT INTO material_lots (lot_code, material_id, supplier_id, received_date, expiry_date, quantity) VALUES
('LOT-ALOE-001',  1, 1, '2026-01-02', '2027-01-02',  500.00),
('LOT-NEEM-001',  2, 1, '2026-01-03', '2027-01-03',  300.00),
('LOT-HONEY-001', 3, 2, '2026-01-28', '2027-01-28', 2000.00);
INSERT INTO products (sku, name, category, description) VALUES
('PC-FW-100', 'Herbal Face Wash 100ml', 'Personal Care', 'Ayurvedic herbal face wash'),
('FD-HN-500', 'Organic Honey 500g',     'Food',          'Raw organic honey jar');
INSERT INTO batches (batch_code, product_id, manufacturer_id, production_date, expiry_date, quantity_produced) VALUES
('B-2026-0001', 1, 1, '2026-01-10', '2027-01-10', 5000),
('B-2026-0002', 2, 2, '2026-02-05', '2027-02-05', 3000),
('B-2026-0003', 2, 2, '2026-03-01', '2027-03-01', 2000);
INSERT INTO batch_materials (batch_id, lot_id, quantity_used) VALUES
(1, 1, 120.00), (1, 2, 60.00),
(2, 3, 1400.00),
(3, 3, 550.00);
INSERT INTO warehouses (name, location) VALUES
('Central Warehouse Dehradun', 'Dehradun, Uttarakhand'),
('North Depot Haridwar',       'Haridwar, Uttarakhand');
INSERT INTO retailers (name, address) VALUES
('MediCare Pharmacy', 'Rajpur Road, Dehradun'),
('Fresh Mart',        'Jwalapur, Haridwar');
INSERT INTO customers (name, email, phone) VALUES
('Rahul Verma', 'rahul@example.com', '9000011111'),
('Priya Singh', 'priya@example.com', '9000022222');
INSERT INTO warehouse_receipts (batch_id, warehouse_id, received_date, quantity) VALUES
(1, 1, '2026-01-15', 2000),
(2, 2, '2026-02-08', 1500),
(3, 2, '2026-03-05', 1000);
INSERT INTO shipments (batch_id, warehouse_id, retailer_id, shipment_date, quantity) VALUES
(1, 1, 1, '2026-01-20', 1000),
(2, 2, 2, '2026-02-10', 1200);
INSERT INTO sales (batch_id, retailer_id, customer_id, sale_date, quantity) VALUES
(1, 1, 1, '2026-01-25', 2),
(2, 2, 2, '2026-02-12', 3),
(2, 2, 1, '2026-02-14', 1);
INSERT INTO recalls (reason, severity, source_lot_id, initiated_by, recall_date)
VALUES ('Contamination detected during routine quality audit', 'high', 3, 1, '2026-02-21');
INSERT INTO recall_batches (recall_id, batch_id) VALUES (1, 2);
INSERT INTO recall_returns (recall_id, sale_id, quantity, resolution) VALUES (1, 2, 1, 'refund');
