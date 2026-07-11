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

@WebServlet("/GlobalSearchServlet")
public class GlobalSearchServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.setStatus(403);
            return;
        }

        String q = request.getParameter("q");
        if (q == null || q.trim().isEmpty()) {
            response.setContentType("application/json");
            response.getWriter().print("{\"results\":[]}");
            return;
        }

        String pattern = "%" + q.trim() + "%";
        response.setContentType("application/json;charset=UTF-8");
        PrintWriter out = response.getWriter();
        StringBuilder sb = new StringBuilder("{\"results\":[");
        boolean first = true;

        try (Connection conn = DBUtil.getConnection()) {
            // Search customers
            PreparedStatement ps1 = conn.prepareStatement(
                "SELECT u.id, u.name, u.email, u.phone FROM users u JOIN customers c ON c.user_id=u.id " +
                "WHERE u.name LIKE ? OR u.email LIKE ? OR u.phone LIKE ? LIMIT 5");
            ps1.setString(1, pattern); ps1.setString(2, pattern); ps1.setString(3, pattern);
            ResultSet rs1 = ps1.executeQuery();
            while (rs1.next()) {
                if (!first) sb.append(","); first = false;
                sb.append("{\"type\":\"Customer\",\"id\":").append(rs1.getInt("id"))
                  .append(",\"title\":\"").append(esc(rs1.getString("name")))
                  .append("\",\"sub\":\"").append(esc(rs1.getString("email"))).append("\"}");
            }
            rs1.close(); ps1.close();

            // Search vehicles
            PreparedStatement ps2 = conn.prepareStatement(
                "SELECT id, brand, model, license_plate FROM vehicles " +
                "WHERE license_plate LIKE ? OR brand LIKE ? OR model LIKE ? OR vin LIKE ? LIMIT 5");
            ps2.setString(1, pattern); ps2.setString(2, pattern); ps2.setString(3, pattern); ps2.setString(4, pattern);
            ResultSet rs2 = ps2.executeQuery();
            while (rs2.next()) {
                if (!first) sb.append(","); first = false;
                sb.append("{\"type\":\"Vehicle\",\"id\":").append(rs2.getInt("id"))
                  .append(",\"title\":\"").append(esc(rs2.getString("brand") + " " + rs2.getString("model")))
                  .append("\",\"sub\":\"").append(esc(rs2.getString("license_plate"))).append("\"}");
            }
            rs2.close(); ps2.close();

            // Search bookings
            PreparedStatement ps3 = conn.prepareStatement(
                "SELECT id, booking_uid, status FROM bookings WHERE booking_uid LIKE ? LIMIT 5");
            ps3.setString(1, pattern);
            ResultSet rs3 = ps3.executeQuery();
            while (rs3.next()) {
                if (!first) sb.append(","); first = false;
                sb.append("{\"type\":\"Booking\",\"id\":").append(rs3.getInt("id"))
                  .append(",\"title\":\"").append(esc(rs3.getString("booking_uid")))
                  .append("\",\"sub\":\"").append(esc(rs3.getString("status"))).append("\"}");
            }
            rs3.close(); ps3.close();

            // Search invoices
            PreparedStatement ps4 = conn.prepareStatement(
                "SELECT id, invoice_number, final_amount FROM invoices WHERE invoice_number LIKE ? LIMIT 5");
            ps4.setString(1, pattern);
            ResultSet rs4 = ps4.executeQuery();
            while (rs4.next()) {
                if (!first) sb.append(","); first = false;
                sb.append("{\"type\":\"Invoice\",\"id\":").append(rs4.getInt("id"))
                  .append(",\"title\":\"").append(esc(rs4.getString("invoice_number")))
                  .append("\",\"sub\":\"Rs.").append(rs4.getDouble("final_amount")).append("\"}");
            }
            rs4.close(); ps4.close();

            // Search mechanics
            PreparedStatement ps5 = conn.prepareStatement(
                "SELECT u.id, u.name, m.specialization FROM mechanics m " +
                "JOIN employees e ON m.employee_id=e.id JOIN users u ON e.user_id=u.id " +
                "WHERE u.name LIKE ? OR m.specialization LIKE ? LIMIT 5");
            ps5.setString(1, pattern); ps5.setString(2, pattern);
            ResultSet rs5 = ps5.executeQuery();
            while (rs5.next()) {
                if (!first) sb.append(","); first = false;
                sb.append("{\"type\":\"Mechanic\",\"id\":").append(rs5.getInt("id"))
                  .append(",\"title\":\"").append(esc(rs5.getString("name")))
                  .append("\",\"sub\":\"").append(esc(rs5.getString("specialization"))).append("\"}");
            }
            rs5.close(); ps5.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        sb.append("]}");
        out.print(sb);
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"");
    }
}
