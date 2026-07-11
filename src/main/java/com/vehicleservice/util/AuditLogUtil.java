package com.vehicleservice.util;

import java.sql.Connection;
import java.sql.PreparedStatement;

public class AuditLogUtil {

    /**
     * Inserts an operation record into the audit log table.
     */
    public static void log(Integer userId, String action, String tableName, Integer recordId, String ipAddress) {
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            String query = "INSERT INTO audit_logs (user_id, action, table_name, record_id, ip_address) VALUES (?, ?, ?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(query);
            
            if (userId != null) {
                ps.setInt(1, userId);
            } else {
                ps.setNull(1, java.sql.Types.INTEGER);
            }
            ps.setString(2, action);
            ps.setString(3, tableName);
            if (recordId != null) {
                ps.setInt(4, recordId);
            } else {
                ps.setNull(4, java.sql.Types.INTEGER);
            }
            ps.setString(5, ipAddress != null ? ipAddress : "0.0.0.0");
            
            ps.executeUpdate();
            ps.close();
        } catch (Exception e) {
            System.err.println("[AuditLogUtil] Error writing audit log entry");
            e.printStackTrace();
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
