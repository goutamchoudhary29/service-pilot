package com.vehicleservice.controller;

import com.vehicleservice.util.DBUtil;
import com.vehicleservice.util.SecurityUtil;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet("/ManageCustomerServlet")
public class ManageCustomerServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.sendRedirect("admin_login.jsp?error=Access+Denied");
            return;
        }

        String action = request.getParameter("action");
        String userIdStr = request.getParameter("userId");

        if (action == null || userIdStr == null) {
            response.sendRedirect("admin_dashboard.jsp?tab=customers&error=Invalid+request");
            return;
        }

        int userId;
        try { userId = Integer.parseInt(userIdStr); } catch (NumberFormatException e) {
            response.sendRedirect("admin_dashboard.jsp?tab=customers&error=Invalid+user+ID");
            return;
        }

        try (Connection conn = DBUtil.getConnection()) {
            switch (action) {
                case "edit":
                    editCustomer(conn, request, userId);
                    response.sendRedirect("admin_dashboard.jsp?tab=customers&success=Customer+updated");
                    break;
                case "disable":
                    updateStatus(conn, userId, "Suspended");
                    response.sendRedirect("admin_dashboard.jsp?tab=customers&success=Customer+disabled");
                    break;
                case "enable":
                    updateStatus(conn, userId, "Active");
                    response.sendRedirect("admin_dashboard.jsp?tab=customers&success=Customer+enabled");
                    break;
                case "resetPassword":
                    resetPassword(conn, userId);
                    response.sendRedirect("admin_dashboard.jsp?tab=customers&success=Password+reset+to+123456");
                    break;
                case "delete":
                    deleteCustomer(conn, userId);
                    response.sendRedirect("admin_dashboard.jsp?tab=customers&success=Customer+deleted");
                    break;
                case "updateNotes":
                    String notes = request.getParameter("notes");
                    PreparedStatement nps = conn.prepareStatement("UPDATE customers SET notes=? WHERE user_id=?");
                    nps.setString(1, notes);
                    nps.setInt(2, userId);
                    nps.executeUpdate();
                    nps.close();
                    response.sendRedirect("admin_dashboard.jsp?tab=customers&success=Notes+updated");
                    break;
                default:
                    response.sendRedirect("admin_dashboard.jsp?tab=customers&error=Unknown+action");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?tab=customers&error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    private void editCustomer(Connection conn, HttpServletRequest req, int userId) throws Exception {
        String name = req.getParameter("name");
        String email = req.getParameter("email");
        String phone = req.getParameter("phone");
        String address = req.getParameter("address");
        String emergencyContact = req.getParameter("emergencyContact");

        PreparedStatement ps = conn.prepareStatement("UPDATE users SET name=?, email=?, phone=? WHERE id=?");
        ps.setString(1, name);
        ps.setString(2, email);
        ps.setString(3, phone);
        ps.setInt(4, userId);
        ps.executeUpdate();
        ps.close();

        PreparedStatement ps2 = conn.prepareStatement("UPDATE customers SET address=?, emergency_contact=? WHERE user_id=?");
        ps2.setString(1, address);
        ps2.setString(2, emergencyContact);
        ps2.setInt(3, userId);
        ps2.executeUpdate();
        ps2.close();
    }

    private void updateStatus(Connection conn, int userId, String status) throws Exception {
        PreparedStatement ps = conn.prepareStatement("UPDATE users SET status=? WHERE id=?");
        ps.setString(1, status);
        ps.setInt(2, userId);
        ps.executeUpdate();
        ps.close();
    }

    private void resetPassword(Connection conn, int userId) throws Exception {
        String hash = SecurityUtil.hashPassword("123456");
        PreparedStatement ps = conn.prepareStatement("UPDATE users SET password_hash=? WHERE id=?");
        ps.setString(1, hash);
        ps.setInt(2, userId);
        ps.executeUpdate();
        ps.close();
    }

    private void deleteCustomer(Connection conn, int userId) throws Exception {
        // Delete in order: payments -> invoices -> job_stages -> job_images -> bookings -> vehicles -> customers -> users
        int custId = -1;
        PreparedStatement cps = conn.prepareStatement("SELECT id FROM customers WHERE user_id=?");
        cps.setInt(1, userId);
        ResultSet crs = cps.executeQuery();
        if (crs.next()) custId = crs.getInt("id");
        crs.close(); cps.close();

        if (custId > 0) {
            conn.prepareStatement("DELETE p FROM payments p JOIN invoices i ON p.invoice_id=i.id WHERE i.customer_id=" + custId).executeUpdate();
            conn.prepareStatement("DELETE FROM invoices WHERE customer_id=" + custId).executeUpdate();
            conn.prepareStatement("DELETE js FROM job_stages js JOIN bookings b ON js.booking_id=b.id WHERE b.customer_id=" + custId).executeUpdate();
            conn.prepareStatement("DELETE ji FROM job_images ji JOIN bookings b ON ji.booking_id=b.id WHERE b.customer_id=" + custId).executeUpdate();
            conn.prepareStatement("DELETE FROM bookings WHERE customer_id=" + custId).executeUpdate();
            conn.prepareStatement("DELETE FROM vehicles WHERE customer_id=" + custId).executeUpdate();
            conn.prepareStatement("DELETE FROM reviews WHERE customer_id=" + custId).executeUpdate();
            conn.prepareStatement("DELETE FROM customers WHERE id=" + custId).executeUpdate();
        }
        conn.prepareStatement("DELETE FROM notifications WHERE user_id=" + userId).executeUpdate();
        conn.prepareStatement("DELETE FROM users WHERE id=" + userId).executeUpdate();
    }
}
