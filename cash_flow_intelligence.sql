-- ============================================
-- CASH FLOW INTELLIGENCE SYSTEM
-- Author: [Your Name]
-- Database: ar_system
-- ============================================

CREATE DATABASE IF NOT EXISTS ar_system;
USE ar_system;

-- ============================================
-- TABLE 1: CUSTOMERS
-- ============================================
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(100),
    phone VARCHAR(20),
    city VARCHAR(50),
    created_at DATE
);

-- ============================================
-- TABLE 2: INVOICES
-- ============================================
CREATE TABLE invoices (
    invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'UNPAID',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ============================================
-- TABLE 3: PAYMENTS
-- ============================================
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount_paid DECIMAL(10,2) NOT NULL,
    payment_mode VARCHAR(30),
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);

-- ============================================
-- SAMPLE DATA: CUSTOMERS
-- ============================================
INSERT INTO customers VALUES
(1, 'Tata Consultancy Services', 'accounts@tcs.com', '9876543210', 'Mumbai', '2024-01-10'),
(2, 'Infosys Limited', 'finance@infosys.com', '9823456789', 'Bangalore', '2024-01-15'),
(3, 'Wipro Technologies', 'billing@wipro.com', '9812345678', 'Hyderabad', '2024-02-01'),
(4, 'HCL Technologies', 'pay@hcl.com', '9801234567', 'Noida', '2024-02-10'),
(5, 'Tech Mahindra', 'ar@techmahindra.com', '9798765432', 'Pune', '2024-03-01');

-- ============================================
-- SAMPLE DATA: INVOICES
-- ============================================
INSERT INTO invoices VALUES
(1, 1, '2024-01-15', '2024-02-15', 150000.00, 'UNPAID'),
(2, 1, '2024-02-01', '2024-03-01', 85000.00, 'PAID'),
(3, 2, '2024-02-10', '2024-03-10', 200000.00, 'UNPAID'),
(4, 2, '2024-03-01', '2024-04-01', 95000.00, 'OVERDUE'),
(5, 3, '2024-03-15', '2024-04-15', 175000.00, 'UNPAID'),
(6, 3, '2024-04-01', '2024-05-01', 120000.00, 'OVERDUE'),
(7, 4, '2024-04-10', '2024-05-10', 300000.00, 'UNPAID'),
(8, 4, '2024-05-01', '2024-06-01', 50000.00, 'PAID'),
(9, 5, '2024-05-15', '2024-06-15', 225000.00, 'OVERDUE'),
(10, 5, '2024-06-01', '2024-07-01', 180000.00, 'UNPAID');

-- ============================================
-- SAMPLE DATA: PAYMENTS
-- ============================================
INSERT INTO payments VALUES
(1, 2, '2024-02-28', 85000.00, 'BANK TRANSFER'),
(2, 8, '2024-05-20', 50000.00, 'CHEQUE'),
(3, 4, '2024-04-05', 50000.00, 'ONLINE'),
(4, 6, '2024-05-10', 60000.00, 'BANK TRANSFER'),
(5, 9, '2024-06-10', 100000.00, 'ONLINE');

-- ============================================
-- QUERY 1: INVOICE AGING REPORT
-- ============================================
SELECT 
    c.company_name,
    i.invoice_id,
    i.amount,
    i.status,
    DATEDIFF('2024-08-01', i.due_date) AS days_overdue,
    CASE 
        WHEN DATEDIFF('2024-08-01', i.due_date) <= 0 THEN 'Not Yet Due'
        WHEN DATEDIFF('2024-08-01', i.due_date) <= 30 THEN '0-30 Days'
        WHEN DATEDIFF('2024-08-01', i.due_date) <= 60 THEN '31-60 Days'
        WHEN DATEDIFF('2024-08-01', i.due_date) <= 90 THEN '61-90 Days'
        ELSE '90+ Days Critical'
    END AS aging_bucket
FROM invoices i
JOIN customers c ON i.customer_id = c.customer_id
WHERE i.status != 'PAID'
ORDER BY days_overdue DESC;

-- ============================================
-- QUERY 2: RUNNING TOTAL OF PAYMENTS
-- ============================================
SELECT 
    c.company_name,
    p.payment_date,
    p.amount_paid,
    p.payment_mode,
    SUM(p.amount_paid) OVER(
        PARTITION BY c.company_name 
        ORDER BY p.payment_date
    ) AS running_total_paid
FROM payments p
JOIN invoices i ON p.invoice_id = i.invoice_id
JOIN customers c ON i.customer_id = c.customer_id
ORDER BY c.company_name, p.payment_date;

-- ============================================
-- QUERY 3: CUSTOMER RISK VIEW
-- ============================================
CREATE VIEW customer_risk_view AS
SELECT 
    c.customer_id,
    c.company_name,
    COUNT(i.invoice_id) AS total_invoices,
    SUM(CASE WHEN i.status = 'OVERDUE' THEN 1 ELSE 0 END) AS overdue_count,
    SUM(i.amount) AS total_billed,
    CASE 
        WHEN SUM(CASE WHEN i.status = 'OVERDUE' THEN 1 ELSE 0 END) >= 2 THEN 'HIGH RISK'
        WHEN SUM(CASE WHEN i.status = 'OVERDUE' THEN 1 ELSE 0 END) = 1 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END AS risk_level
FROM customers c
JOIN invoices i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.company_name;

-- ============================================
-- STORED PROCEDURE: GET OVERDUE INVOICES
-- ============================================
DELIMITER //
CREATE PROCEDURE GetOverdueInvoices(IN min_days INT)
BEGIN
    SELECT 
        c.company_name,
        i.invoice_id,
        i.amount,
        DATEDIFF('2024-08-01', i.due_date) AS days_overdue
    FROM invoices i
    JOIN customers c ON i.customer_id = c.customer_id
    WHERE DATEDIFF('2024-08-01', i.due_date) >= min_days
    ORDER BY days_overdue DESC;
END //
DELIMITER ;

-- ============================================
-- TRIGGER: AUTO UPDATE INVOICE STATUS
-- ============================================
CREATE TRIGGER after_payment_insert
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE v_invoice_amount DECIMAL(10,2);
    DECLARE v_total_paid DECIMAL(10,2);
    
    SELECT amount INTO v_invoice_amount 
    FROM invoices WHERE invoice_id = NEW.invoice_id;
    
    SELECT SUM(amount_paid) INTO v_total_paid 
    FROM payments WHERE invoice_id = NEW.invoice_id;
    
    IF v_total_paid >= v_invoice_amount THEN
        UPDATE invoices SET status = 'PAID' 
        WHERE invoice_id = NEW.invoice_id;
    END IF;
END //