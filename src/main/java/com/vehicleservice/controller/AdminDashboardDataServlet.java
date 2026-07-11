package com.vehicleservice.controller;

import com.vehicleservice.util.DBUtil;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/AdminDashboardDataServlet")
public class AdminDashboardDataServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.setStatus(403);
            return;
        }

        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();

        try (Connection conn = DBUtil.getConnection()) {
            int totalCustomers = getCount(conn, "SELECT COUNT(*) FROM customers");
            int totalMechanics = getCount(conn, "SELECT COUNT(*) FROM mechanics");
            int totalBookings = getCount(conn, "SELECT COUNT(*) FROM bookings");
            double totalRevenue = getDouble(conn, "SELECT COALESCE(SUM(paid_amount),0) FROM payments WHERE payment_status='Paid'");
            int pendingPayments = getCount(conn, "SELECT COUNT(*) FROM payments WHERE payment_status='Pending'");
            int pendingServices = getCount(conn, "SELECT COUNT(*) FROM bookings WHERE status IN ('Pending','Accepted','Inspection','Repair Started','In Progress')");
            int todayAppointments = getCount(conn, "SELECT COUNT(*) FROM bookings WHERE booking_date = CURDATE()");
            int completedServices = getCount(conn, "SELECT COUNT(*) FROM bookings WHERE status IN ('Completed','Delivered')");
            int inventoryAlerts = getCount(conn, "SELECT COUNT(*) FROM inventory WHERE quantity <= low_stock_threshold");
            int totalReviews = getCount(conn, "SELECT COUNT(*) FROM reviews");
            double avgRating = getDouble(conn, "SELECT COALESCE(AVG(rating),0) FROM reviews WHERE status='Approved'");
            int unreadNotifications = getCount(conn, "SELECT COUNT(*) FROM notifications WHERE is_read=0");

            // Monthly revenue for chart (last 6 months)
            StringBuilder monthlyRevenue = new StringBuilder("[");
            StringBuilder monthLabels = new StringBuilder("[");
            PreparedStatement ps = conn.prepareStatement(
                "SELECT DATE_FORMAT(p.created_at,'%Y-%m') AS m, COALESCE(SUM(p.paid_amount),0) AS rev " +
                "FROM payments p WHERE p.payment_status='Paid' AND p.created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH) " +
                "GROUP BY m ORDER BY m");
            ResultSet rs = ps.executeQuery();
            boolean first = true;
            while (rs.next()) {
                if (!first) { monthlyRevenue.append(","); monthLabels.append(","); }
                monthLabels.append("\"").append(rs.getString("m")).append("\"");
                monthlyRevenue.append(rs.getDouble("rev"));
                first = false;
            }
            monthlyRevenue.append("]");
            monthLabels.append("]");
            rs.close(); ps.close();

            // Status distribution for doughnut
            int sPending = getCount(conn, "SELECT COUNT(*) FROM bookings WHERE status='Pending'");
            int sAccepted = getCount(conn, "SELECT COUNT(*) FROM bookings WHERE status='Accepted'");
            int sInProgress = getCount(conn, "SELECT COUNT(*) FROM bookings WHERE status IN ('Inspection','Repair Started','In Progress','Repair Completed','Quality Check')");
            int sReady = getCount(conn, "SELECT COUNT(*) FROM bookings WHERE status='Ready for Delivery'");
            int sDelivered = getCount(conn, "SELECT COUNT(*) FROM bookings WHERE status IN ('Delivered','Completed')");
            int sCancelled = getCount(conn, "SELECT COUNT(*) FROM bookings WHERE status='Cancelled'");

            // Recent activity (last 10)
            StringBuilder recentActivity = new StringBuilder("[");
            ps = conn.prepareStatement("SELECT activity_type, description, timestamp FROM activity_logs ORDER BY timestamp DESC LIMIT 10");
            rs = ps.executeQuery();
            first = true;
            while (rs.next()) {
                if (!first) recentActivity.append(",");
                recentActivity.append("{\"type\":\"").append(escape(rs.getString("activity_type")))
                    .append("\",\"desc\":\"").append(escape(rs.getString("description")))
                    .append("\",\"time\":\"").append(rs.getTimestamp("timestamp")).append("\"}");
                first = false;
            }
            recentActivity.append("]");
            rs.close(); ps.close();

            out.print("{\"totalCustomers\":" + totalCustomers +
                ",\"totalMechanics\":" + totalMechanics +
                ",\"totalBookings\":" + totalBookings +
                ",\"totalRevenue\":" + totalRevenue +
                ",\"pendingPayments\":" + pendingPayments +
                ",\"pendingServices\":" + pendingServices +
                ",\"todayAppointments\":" + todayAppointments +
                ",\"completedServices\":" + completedServices +
                ",\"inventoryAlerts\":" + inventoryAlerts +
                ",\"totalReviews\":" + totalReviews +
                ",\"avgRating\":" + String.format("%.1f", avgRating) +
                ",\"unreadNotifications\":" + unreadNotifications +
                ",\"monthLabels\":" + monthLabels +
                ",\"monthlyRevenue\":" + monthlyRevenue +
                ",\"statusDist\":[" + sPending + "," + sAccepted + "," + sInProgress + "," + sReady + "," + sDelivered + "," + sCancelled + "]" +
                ",\"recentActivity\":" + recentActivity +
                "}");

        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"error\":\"" + escape(e.getMessage()) + "\"}");
        }
    }

    private int getCount(Connection c, String sql) throws Exception {
        PreparedStatement ps = c.prepareStatement(sql);
        ResultSet rs = ps.executeQuery();
        rs.next();
        int val = rs.getInt(1);
        rs.close(); ps.close();
        return val;
    }

    private double getDouble(Connection c, String sql) throws Exception {
        PreparedStatement ps = c.prepareStatement(sql);
        ResultSet rs = ps.executeQuery();
        rs.next();
        double val = rs.getDouble(1);
        rs.close(); ps.close();
        return val;
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ").replace("\r", "");
    }
}
