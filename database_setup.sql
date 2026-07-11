CREATE DATABASE IF NOT EXISTS servicepilot;
USE servicepilot;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS activity_logs;
DROP TABLE IF EXISTS audit_logs;
DROP TABLE IF EXISTS company_settings;
DROP TABLE IF EXISTS employee_attendance;
DROP TABLE IF EXISTS referral_rewards;
DROP TABLE IF EXISTS complaints;
DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS reminders;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS payment_receipts;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS coupons;
DROP TABLE IF EXISTS purchase_history;
DROP TABLE IF EXISTS suppliers;
DROP TABLE IF EXISTS inventory_logs;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS job_images;
DROP TABLE IF EXISTS job_stages;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS services;
DROP TABLE IF EXISTS vehicle_images;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS mechanics;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS branches;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS role_permissions;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS roles;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Roles
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

-- 2. Permissions
CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- 3. Role Permissions Mapping
CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

-- 4. Users
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    status ENUM('Active', 'Suspended', 'Pending') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(id),
    INDEX idx_user_email (email)
);

-- 5. Branches (Multi-branch support)
CREATE TABLE branches (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    email VARCHAR(100) NOT NULL,
    status ENUM('Active', 'Inactive') DEFAULT 'Active'
);

-- 6. Employees
CREATE TABLE employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    branch_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    attendance_status ENUM('Present', 'Absent', 'On Leave') DEFAULT 'Present',
    status ENUM('Active', 'Resigned', 'Suspended') DEFAULT 'Active',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (branch_id) REFERENCES branches(id)
);

-- 7. Mechanics Profile
CREATE TABLE mechanics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL UNIQUE,
    specialization VARCHAR(100),
    rating DECIMAL(3, 2) DEFAULT 5.00,
    current_job_id INT,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE
);

-- 8. Customers
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    address TEXT,
    loyalty_points INT DEFAULT 0,
    referral_code VARCHAR(50) UNIQUE,
    referred_by_id INT,
    status ENUM('Active', 'Inactive') DEFAULT 'Active',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (referred_by_id) REFERENCES customers(id) ON DELETE SET NULL
);

-- 9. Vehicles
CREATE TABLE vehicles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    vin VARCHAR(17) NOT NULL UNIQUE,
    license_plate VARCHAR(20) NOT NULL UNIQUE,
    brand VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    fuel_type ENUM('Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid') NOT NULL,
    insurance_policy_no VARCHAR(100),
    insurance_expiry DATE,
    puc_expiry DATE,
    warranty_expiry DATE,
    mileage INT NOT NULL DEFAULT 0,
    status ENUM('Active', 'Archived') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    INDEX idx_vin (vin)
);

-- 10. Vehicle Images
CREATE TABLE vehicle_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
);

-- 11. Services Catalog
CREATE TABLE services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    time_required DECIMAL(4, 2) NOT NULL, -- in hours
    quality VARCHAR(50),
    image_url VARCHAR(255),
    status ENUM('Available', 'Discontinued') DEFAULT 'Available'
);

-- 12. Bookings
CREATE TABLE bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_uid VARCHAR(30) NOT NULL UNIQUE, -- Serial: SP-YYYY-XXXXXX
    customer_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    service_id INT NOT NULL,
    branch_id INT NOT NULL,
    mechanic_id INT,
    booking_date DATE NOT NULL,
    time_slot VARCHAR(20) NOT NULL,
    status ENUM('Pending', 'Accepted', 'In Progress', 'Completed', 'Cancelled') DEFAULT 'Pending',
    additional_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (service_id) REFERENCES services(id),
    FOREIGN KEY (branch_id) REFERENCES branches(id),
    FOREIGN KEY (mechanic_id) REFERENCES mechanics(id) ON DELETE SET NULL,
    UNIQUE KEY uq_slot_mechanic (booking_date, time_slot, mechanic_id),
    INDEX idx_booking_uid (booking_uid)
);

-- 13. Job Stages
CREATE TABLE job_stages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    mechanic_id INT NOT NULL,
    stage_name ENUM('Inspection', 'Repair Started', 'Repair Completed', 'Quality Check', 'Ready for Delivery') NOT NULL,
    description TEXT,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (mechanic_id) REFERENCES mechanics(id)
);

-- 14. Job Images (Before & After proofs)
CREATE TABLE job_images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_stage_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    type ENUM('BEFORE', 'AFTER') NOT NULL,
    FOREIGN KEY (job_stage_id) REFERENCES job_stages(id) ON DELETE CASCADE
);

-- 15. Inventory Items
CREATE TABLE inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    unit VARCHAR(20) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    low_stock_threshold INT NOT NULL DEFAULT 5,
    location VARCHAR(50),
    status ENUM('In Stock', 'Out of Stock') DEFAULT 'In Stock'
);

-- 16. Inventory Transaction Logs
CREATE TABLE inventory_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    inventory_id INT NOT NULL,
    type ENUM('Stock In', 'Stock Out') NOT NULL,
    quantity INT NOT NULL,
    reason VARCHAR(255),
    user_id INT NOT NULL,
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (inventory_id) REFERENCES inventory(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- 17. Suppliers
CREATE TABLE suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    phone VARCHAR(15),
    email VARCHAR(100),
    address TEXT
);

-- 18. Purchase History
CREATE TABLE purchase_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    purchase_date DATE NOT NULL,
    invoice_no VARCHAR(100),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);

-- 19. Coupons
CREATE TABLE coupons (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    discount_percentage INT NOT NULL,
    max_discount DECIMAL(10, 2),
    min_order_value DECIMAL(10, 2) NOT NULL,
    expiry_date DATE NOT NULL,
    status ENUM('Active', 'Expired', 'Disabled') DEFAULT 'Active'
);

-- 20. Invoices
CREATE TABLE invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(50) NOT NULL UNIQUE,
    booking_id INT NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL,
    gst_amount DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    final_amount DECIMAL(10, 2) NOT NULL,
    pdf_path VARCHAR(255),
    signature_path VARCHAR(255),
    qr_code_path VARCHAR(255),
    barcode_path VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    INDEX idx_invoice_num (invoice_number)
);

-- 21. Payments
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    payment_method ENUM('Cash', 'UPI', 'Card', 'Net Banking') NOT NULL,
    payment_status ENUM('Pending', 'Paid', 'Refunded', 'Partial') DEFAULT 'Pending',
    paid_amount DECIMAL(10, 2) NOT NULL,
    transaction_id VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);

-- 22. Payment Receipts
CREATE TABLE payment_receipts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payment_id INT NOT NULL UNIQUE,
    receipt_no VARCHAR(50) NOT NULL UNIQUE,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE
);

-- 23. Notifications Log
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('Email', 'SMS', 'WhatsApp') NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 24. Service Reminders
CREATE TABLE reminders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    reminder_type ENUM('Oil Change', 'Insurance Renewal', 'PUC Renewal', 'Annual Service') NOT NULL,
    due_date DATE NOT NULL,
    status ENUM('Pending', 'Sent', 'Resolved') DEFAULT 'Pending',
    last_sent TIMESTAMP NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
);

-- 25. Reviews
CREATE TABLE reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    service_id INT NOT NULL,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (service_id) REFERENCES services(id)
);

-- 26. Complaints Management
CREATE TABLE complaints (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    status ENUM('Open', 'In Investigation', 'Resolved', 'Closed') DEFAULT 'Open',
    priority ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    assigned_to INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL
);

-- 27. Referral Rewards Track
CREATE TABLE referral_rewards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    referrer_id INT NOT NULL,
    referee_id INT NOT NULL UNIQUE,
    points_awarded INT DEFAULT 100,
    status ENUM('Pending', 'Claimed') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (referrer_id) REFERENCES customers(id),
    FOREIGN KEY (referee_id) REFERENCES customers(id)
);

-- 28. Employee Attendance Logs
CREATE TABLE employee_attendance (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT NOT NULL,
    date DATE NOT NULL,
    status ENUM('Present', 'Absent', 'On Leave') NOT NULL,
    check_in TIME,
    check_out TIME,
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
    UNIQUE KEY uq_emp_date (employee_id, date)
);

-- 29. System Settings
CREATE TABLE company_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT NOT NULL,
    description TEXT
);

-- 30. Audit Logs
CREATE TABLE audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(255) NOT NULL,
    table_name VARCHAR(100),
    record_id INT,
    before_state JSON,
    after_state JSON,
    ip_address VARCHAR(45) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 31. Recent Activity Logs
CREATE TABLE activity_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    activity_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Seed Data
-- Insert Roles
INSERT INTO roles (id, name, description) VALUES
(1, 'Super Admin', 'Full control over all branches, settings, and roles'),
(2, 'Admin', 'Branch manager with operational control'),
(3, 'Customer', 'Vehicle owner who books and tracks services'),
(4, 'Mechanic', 'Service technician who performs vehicle repairs'),
(5, 'Receptionist', 'Front desk officer handling bookings and payments'),
(6, 'Inventory Manager', 'Manages parts stock, logs, and purchase orders'),
(7, 'Accountant', 'Manages invoicing, payments, and financial reports');

-- Insert Default Locations (Branches)
INSERT INTO branches (id, name, address, phone, email, status) VALUES
(1, 'Downtown Service Center', '123 Main St, Cityville', '555-0100', 'downtown@servicepilot.com', 'Active'),
(2, 'Northside Auto Care', '456 Oak Rd, Townsville', '555-0200', 'northside@servicepilot.com', 'Active'),
(3, 'West End Garage', '789 Pine Ave, West City', '555-0300', 'westend@servicepilot.com', 'Active');

-- Insert Users (Password: 123456)
INSERT INTO users (id, name, email, phone, password_hash, role_id, status) VALUES
(1, 'Super Admin User', 'superadmin@servicepilot.com', '1111111111', '$2a$10$bTOYZmRvknmbLHGMSZTZyeSPLOncgCpzMkEKNoW36NUJ4VuZi5iQm', 1, 'Active'),
(2, 'Goutam Admin', 'goutam@gmail.com', '9926432885', '$2a$10$bTOYZmRvknmbLHGMSZTZyeSPLOncgCpzMkEKNoW36NUJ4VuZi5iQm', 2, 'Active'),
(3, 'Industry Test Customer', 'test@industry.com', '2222222222', '$2a$10$bTOYZmRvknmbLHGMSZTZyeSPLOncgCpzMkEKNoW36NUJ4VuZi5iQm', 3, 'Active'),
(4, 'John Mechanic', 'mechanic@servicepilot.com', '3333333333', '$2a$10$bTOYZmRvknmbLHGMSZTZyeSPLOncgCpzMkEKNoW36NUJ4VuZi5iQm', 4, 'Active'),
(5, 'Alice Receptionist', 'receptionist@servicepilot.com', '4444444444', '$2a$10$bTOYZmRvknmbLHGMSZTZyeSPLOncgCpzMkEKNoW36NUJ4VuZi5iQm', 5, 'Active'),
(6, 'Bob Inventory Manager', 'inventory@servicepilot.com', '5555555555', '$2a$10$bTOYZmRvknmbLHGMSZTZyeSPLOncgCpzMkEKNoW36NUJ4VuZi5iQm', 6, 'Active'),
(7, 'Charlie Accountant', 'accountant@servicepilot.com', '6666666666', '$2a$10$bTOYZmRvknmbLHGMSZTZyeSPLOncgCpzMkEKNoW36NUJ4VuZi5iQm', 7, 'Active');

-- Insert Customer Profile
INSERT INTO customers (id, user_id, address, loyalty_points, referral_code) VALUES
(1, 3, '456 Client Boulevard, Cityville', 150, 'REF-TEST-CUSTOMER');

-- Insert Employee Profiles
INSERT INTO employees (id, user_id, branch_id, title, salary) VALUES
(1, 4, 1, 'Senior Car Mechanic', 45000.00),
(2, 5, 1, 'Front Desk Receptionist', 25000.00),
(3, 6, 1, 'Parts Manager', 32000.00),
(4, 7, 1, 'Senior Accountant', 40000.00);

-- Insert Mechanic Profile
INSERT INTO mechanics (id, employee_id, specialization) VALUES
(1, 1, 'Engine Diagnostics & Transmission');

-- Insert Services Catalog
INSERT INTO services (id, service_name, description, price, time_required, quality, image_url) VALUES
(1, 'Oil Change', 'Premium engine oil replacement and system check', 1500.00, 1.0, 'Premium Synthetics', 'oilchange.jpg'),
(2, 'Tire Replacement & Balancing', 'Brand new high-grip tires and alignment services', 4500.00, 2.0, 'A-Grade Rubber', 'tire.jpg'),
(3, 'Brake Inspection & Cleaning', 'Inspect calipers, lines, pads and execute rotor resurfacing', 1200.00, 1.5, 'OEM Spec', 'picfront1.jpg'),
(4, 'Battery Diagnostic & Check', 'Load testing of battery and health diagnostic verification', 650.00, 0.5, 'Multi-point Scan', 'oilchange.jpg'),
(5, 'Engine Diagnostics & Repair', 'Comprehensive scanning of dashboard warning lights and engine component repair', 8500.00, 4.0, 'Certified Technician', 'engine.jpg');

-- Insert default settings
INSERT INTO company_settings (setting_key, setting_value, description) VALUES
('company_name', 'ServicePilot Ltd.', 'Name of the auto-care dealership'),
('company_gst', '27AAAAA1111A1Z1', 'GST Registration Number'),
('company_address', '123 Service Street, Indore, MP 452001', 'Primary HQ Address'),
('company_email', 'support@servicepilot.com', 'Primary support email address'),
('company_phone', '+91 9876543210', 'Primary helpdesk contact number');
-- ═══════════════════════════════════════════════════════════
-- ServicePilot Database Upgrade v2.0
-- Enterprise Transformation Migration
-- ═══════════════════════════════════════════════════════════

-- Helper: Use procedures to safely add columns
DELIMITER //
CREATE PROCEDURE sp_add_column_if_not_exists(
    IN tbl VARCHAR(64), IN col VARCHAR(64), IN col_def VARCHAR(255))
BEGIN
    SET @s = CONCAT('SELECT COUNT(*) INTO @exists FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name=''', tbl, ''' AND column_name=''', col, '''');
    PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    IF @exists = 0 THEN
        SET @s = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN `', col, '` ', col_def);
        PREPARE stmt FROM @s; EXECUTE stmt; DEALLOCATE PREPARE stmt;
    END IF;
END //
DELIMITER ;

-- 1. Users table
CALL sp_add_column_if_not_exists('users', 'profile_picture', 'VARCHAR(255) DEFAULT NULL');
CALL sp_add_column_if_not_exists('users', 'last_login', 'TIMESTAMP NULL DEFAULT NULL');

-- 2. Customers table
CALL sp_add_column_if_not_exists('customers', 'emergency_contact', 'VARCHAR(15) DEFAULT NULL');
CALL sp_add_column_if_not_exists('customers', 'notes', 'TEXT DEFAULT NULL');

-- 3. Vehicles table
CALL sp_add_column_if_not_exists('vehicles', 'engine_number', 'VARCHAR(50) DEFAULT NULL');
CALL sp_add_column_if_not_exists('vehicles', 'transmission', "ENUM('Manual','Automatic','CVT') DEFAULT 'Manual'");

-- 4. Reviews table
CALL sp_add_column_if_not_exists('reviews', 'booking_id', 'INT DEFAULT NULL');
CALL sp_add_column_if_not_exists('reviews', 'photo_url', 'VARCHAR(255) DEFAULT NULL');
CALL sp_add_column_if_not_exists('reviews', 'status', "ENUM('Pending','Approved','Rejected') DEFAULT 'Pending'");
CALL sp_add_column_if_not_exists('reviews', 'admin_reply', 'TEXT DEFAULT NULL');

-- 5. Bookings — extend status enum
ALTER TABLE bookings MODIFY COLUMN status ENUM(
    'Pending','Accepted','Inspection','Repair Started','In Progress',
    'Repair Completed','Quality Check','Ready for Delivery','Delivered',
    'Completed','Cancelled'
) DEFAULT 'Pending';

-- 6. Payments — refund support
CALL sp_add_column_if_not_exists('payments', 'refund_amount', 'DECIMAL(10,2) DEFAULT 0.00');
CALL sp_add_column_if_not_exists('payments', 'refund_reason', 'TEXT DEFAULT NULL');

-- 7. Notifications
CALL sp_add_column_if_not_exists('notifications', 'link', 'VARCHAR(255) DEFAULT NULL');
CALL sp_add_column_if_not_exists('notifications', 'category', "VARCHAR(50) DEFAULT 'General'");

-- Cleanup helper
DROP PROCEDURE IF EXISTS sp_add_column_if_not_exists;

-- 8. Email Templates table
CREATE TABLE IF NOT EXISTS email_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    template_key VARCHAR(50) NOT NULL UNIQUE,
    subject VARCHAR(255) NOT NULL,
    body_html TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. Seed templates
INSERT IGNORE INTO email_templates (template_key, subject, body_html) VALUES
('booking_confirmed', 'ServicePilot Booking Confirmed #{{booking_uid}}',
'<div style="font-family:Inter,Arial,sans-serif;max-width:600px;margin:0 auto;background:#0b0f19;color:#e2e8f0;border-radius:12px;overflow:hidden;"><div style="background:linear-gradient(135deg,#6366f1,#06b6d4);padding:24px;text-align:center;"><h1 style="margin:0;color:#fff;font-size:24px;">ServicePilot</h1><p style="margin:4px 0 0;color:rgba(255,255,255,0.8);font-size:14px;">Booking Confirmation</p></div><div style="padding:24px;"><p>Dear <strong>{{customer_name}}</strong>,</p><p>Your service booking has been confirmed.</p><table style="width:100%;border-collapse:collapse;margin:16px 0;"><tr><td style="padding:8px;color:#94a3b8;">Booking ID</td><td style="padding:8px;font-weight:600;">{{booking_uid}}</td></tr><tr><td style="padding:8px;color:#94a3b8;">Vehicle</td><td style="padding:8px;">{{vehicle_brand}} {{vehicle_model}} ({{license_plate}})</td></tr><tr><td style="padding:8px;color:#94a3b8;">Service</td><td style="padding:8px;">{{service_name}}</td></tr><tr><td style="padding:8px;color:#94a3b8;">Date</td><td style="padding:8px;">{{booking_date}} | {{time_slot}}</td></tr><tr><td style="padding:8px;color:#94a3b8;">Mechanic</td><td style="padding:8px;">{{mechanic_name}}</td></tr><tr><td style="padding:8px;color:#94a3b8;">Branch</td><td style="padding:8px;">{{branch_name}}</td></tr></table><p style="color:#94a3b8;font-size:13px;">Contact: support@servicepilot.com | +91 9876543210</p></div><div style="background:#111827;padding:16px;text-align:center;font-size:12px;color:#64748b;">2025 ServicePilot. All Rights Reserved.</div></div>'),

('status_updated', 'ServicePilot Service Update #{{booking_uid}}',
'<div style="font-family:Inter,Arial,sans-serif;max-width:600px;margin:0 auto;background:#0b0f19;color:#e2e8f0;border-radius:12px;overflow:hidden;"><div style="background:linear-gradient(135deg,#6366f1,#06b6d4);padding:24px;text-align:center;"><h1 style="margin:0;color:#fff;font-size:24px;">ServicePilot</h1><p style="margin:4px 0 0;color:rgba(255,255,255,0.8);font-size:14px;">Status Update</p></div><div style="padding:24px;"><p>Dear <strong>{{customer_name}}</strong>,</p><p>Your vehicle service status has been updated:</p><div style="background:#111827;border:1px solid rgba(99,102,241,0.3);border-radius:8px;padding:16px;margin:16px 0;text-align:center;"><p style="color:#94a3b8;margin:0 0 8px;font-size:13px;">CURRENT STATUS</p><h2 style="margin:0;color:#818cf8;font-size:22px;">{{status}}</h2></div><table style="width:100%;border-collapse:collapse;margin:16px 0;"><tr><td style="padding:8px;color:#94a3b8;">Booking</td><td style="padding:8px;">{{booking_uid}}</td></tr><tr><td style="padding:8px;color:#94a3b8;">Vehicle</td><td style="padding:8px;">{{vehicle_brand}} {{vehicle_model}} ({{license_plate}})</td></tr><tr><td style="padding:8px;color:#94a3b8;">Mechanic</td><td style="padding:8px;">{{mechanic_name}}</td></tr><tr><td style="padding:8px;color:#94a3b8;">Payment</td><td style="padding:8px;">{{payment_status}}</td></tr></table></div><div style="background:#111827;padding:16px;text-align:center;font-size:12px;color:#64748b;">2025 ServicePilot.</div></div>'),

('payment_received', 'ServicePilot Payment Received #{{booking_uid}}',
'<div style="font-family:Inter,Arial,sans-serif;max-width:600px;margin:0 auto;background:#0b0f19;color:#e2e8f0;border-radius:12px;overflow:hidden;"><div style="background:linear-gradient(135deg,#10b981,#06b6d4);padding:24px;text-align:center;"><h1 style="margin:0;color:#fff;font-size:24px;">ServicePilot</h1><p style="margin:4px 0 0;color:rgba(255,255,255,0.8);font-size:14px;">Payment Confirmation</p></div><div style="padding:24px;"><p>Dear <strong>{{customer_name}}</strong>,</p><p>We have received your payment. Thank you!</p><div style="background:#111827;border:1px solid rgba(16,185,129,0.3);border-radius:8px;padding:16px;margin:16px 0;text-align:center;"><p style="color:#94a3b8;margin:0 0 4px;font-size:13px;">AMOUNT PAID</p><h2 style="margin:0;color:#10b981;font-size:28px;">Rs.{{amount}}</h2><p style="color:#64748b;margin:8px 0 0;font-size:12px;">TXN: {{transaction_id}} | {{payment_method}}</p></div></div><div style="background:#111827;padding:16px;text-align:center;font-size:12px;color:#64748b;">2025 ServicePilot.</div></div>'),

('review_request', 'ServicePilot - How was your service experience?',
'<div style="font-family:Inter,Arial,sans-serif;max-width:600px;margin:0 auto;background:#0b0f19;color:#e2e8f0;border-radius:12px;overflow:hidden;"><div style="background:linear-gradient(135deg,#6366f1,#8b5cf6);padding:24px;text-align:center;"><h1 style="margin:0;color:#fff;font-size:24px;">ServicePilot</h1><p style="margin:4px 0 0;color:rgba(255,255,255,0.8);font-size:14px;">We value your feedback</p></div><div style="padding:24px;text-align:center;"><p>Dear <strong>{{customer_name}}</strong>,</p><p>Your vehicle <strong>{{vehicle_brand}} {{vehicle_model}}</strong> has been serviced. We would love to hear about your experience!</p><p style="color:#94a3b8;font-size:13px;">Log in to your dashboard to leave a review.</p></div><div style="background:#111827;padding:16px;text-align:center;font-size:12px;color:#64748b;">2025 ServicePilot.</div></div>');

-- 10. Seed company settings
INSERT IGNORE INTO company_settings (setting_key, setting_value) VALUES
('allow_impersonation', 'false'),
('company_name', 'ServicePilot Auto Care'),
('company_phone', '+91 9876543210'),
('company_email', 'support@servicepilot.com'),
('company_address', 'Near Highway Plaza, Indore, MP 452001'),
('gst_number', '23AABCU9603R1ZM'),
('gst_rate', '18');
