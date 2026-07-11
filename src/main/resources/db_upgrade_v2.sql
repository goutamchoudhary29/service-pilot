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
