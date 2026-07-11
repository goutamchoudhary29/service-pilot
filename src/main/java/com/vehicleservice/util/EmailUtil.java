package com.vehicleservice.util;

import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.Properties;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class EmailUtil {

    // Thread pool to send emails asynchronously (prevents UI lag)
    private static final ExecutorService executorService = Executors.newCachedThreadPool();

    /**
     * Send email in a background thread.
     */
    public static void sendEmailAsync(final String recipient, final String subject, final String content) {
        executorService.submit(new Runnable() {
            @Override
            public void run() {
                sendEmailSync(recipient, subject, content);
            }
        });
    }

    /**
     * Synchronous sending logic.
     */
    private static void sendEmailSync(String recipient, String subject, String content) {
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            
            // Load SMTP settings from database
            String host = getSetting(conn, "smtp_host", "smtp-relay.brevo.com");
            String port = getSetting(conn, "smtp_port", "587");
            final String username = getSetting(conn, "smtp_username", "servicepilot@yopmail.com"); // default fallback
            final String password = getSetting(conn, "smtp_password", ""); // SMTP key

            if (password == null || password.trim().isEmpty()) {
                System.out.println("[EmailUtil] Warning: SMTP Password is not set. Simulating dispatch by logging notification.");
                logNotification(conn, recipient, subject, content);
                return;
            }

            Properties props = new Properties();
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");
            props.put("mail.smtp.host", host);
            props.put("mail.smtp.port", port);

            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(username, password);
                }
            });

            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(username, "ServicePilot System"));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(recipient));
            message.setSubject(subject);
            message.setContent(content, "text/html; charset=utf-8");

            Transport.send(message);
            System.out.println("[EmailUtil] Email sent successfully to: " + recipient);

            // Log email notification inside notifications table
            logNotification(conn, recipient, subject, content);

        } catch (Exception e) {
            System.err.println("[EmailUtil] Error dispatching email to " + recipient);
            e.printStackTrace();
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }

    private static String getSetting(Connection conn, String key, String defaultValue) {
        try {
            String query = "SELECT setting_value FROM company_settings WHERE setting_key = ?";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, key);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String val = rs.getString("setting_value");
                if (val != null && !val.trim().isEmpty()) {
                    return val;
                }
            }
            rs.close();
            ps.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return defaultValue;
    }

    private static void logNotification(Connection conn, String recipient, String subject, String content) {
        try {
            // Find user_id by email
            String userQuery = "SELECT id FROM users WHERE email = ?";
            PreparedStatement userPs = conn.prepareStatement(userQuery);
            userPs.setString(1, recipient);
            ResultSet userRs = userPs.executeQuery();
            if (userRs.next()) {
                int userId = userRs.getInt("id");
                
                String insertNotif = "INSERT INTO notifications (user_id, title, message, type) VALUES (?, ?, ?, 'Email')";
                PreparedStatement notifPs = conn.prepareStatement(insertNotif);
                notifPs.setInt(1, userId);
                notifPs.setString(2, subject);
                notifPs.setString(3, content.substring(0, Math.min(content.length(), 500))); // truncate for DB size
                notifPs.executeUpdate();
                notifPs.close();
            }
            userRs.close();
            userPs.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    /**
     * Send professional HTML status email for any booking.
     */
    public static void sendBookingStatusEmail(int bookingId) {
        executorService.submit(new Runnable() {
            @Override
            public void run() {
                try (Connection conn = DBUtil.getConnection()) {
                    String sql = "SELECT b.booking_uid, u.name AS cname, u.email AS cemail, " +
                        "v.brand, v.model, v.license_plate, s.service_name, b.status AS service_status, " +
                        "COALESCE(mu.name,'Unassigned') AS mech_name, " +
                        "COALESCE(p.payment_status,'Pending') AS pay_status " +
                        "FROM bookings b " +
                        "JOIN customers c ON b.customer_id=c.id " +
                        "JOIN users u ON c.user_id=u.id " +
                        "JOIN vehicles v ON b.vehicle_id=v.id " +
                        "JOIN services s ON b.service_id=s.id " +
                        "LEFT JOIN mechanics m ON b.mechanic_id=m.id " +
                        "LEFT JOIN employees e ON m.employee_id=e.id " +
                        "LEFT JOIN users mu ON e.user_id=mu.id " +
                        "LEFT JOIN invoices inv ON inv.booking_id=b.id " +
                        "LEFT JOIN payments p ON p.invoice_id=inv.id " +
                        "WHERE b.id=?";
                    PreparedStatement ps = conn.prepareStatement(sql);
                    ps.setInt(1, bookingId);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        PreparedStatement tps = conn.prepareStatement("SELECT subject, body_html FROM email_templates WHERE template_key='status_updated'");
                        ResultSet trs = tps.executeQuery();
                        if (trs.next()) {
                            String subject = trs.getString("subject").replace("{{booking_uid}}", rs.getString("booking_uid"));
                            String body = trs.getString("body_html")
                                .replace("{{customer_name}}", rs.getString("cname"))
                                .replace("{{booking_uid}}", rs.getString("booking_uid"))
                                .replace("{{vehicle_brand}}", rs.getString("brand"))
                                .replace("{{vehicle_model}}", rs.getString("model"))
                                .replace("{{license_plate}}", rs.getString("license_plate"))
                                .replace("{{status}}", rs.getString("service_status"))
                                .replace("{{mechanic_name}}", rs.getString("mech_name"))
                                .replace("{{payment_status}}", rs.getString("pay_status"));
                            sendEmailSync(rs.getString("cemail"), subject, body);
                        }
                        trs.close(); tps.close();
                    }
                    rs.close(); ps.close();
                } catch (Exception e) {
                    System.err.println("[EmailUtil] sendBookingStatusEmail failed: " + e.getMessage());
                }
            }
        });
    }
}
