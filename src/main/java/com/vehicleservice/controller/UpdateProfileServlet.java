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

@WebServlet("/UpdateProfileServlet")
public class UpdateProfileServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        String email = (session != null) ? (String) session.getAttribute("customerEmail") : null;
        if (email == null) {
            response.sendRedirect("login.jsp?error=Please+login+first");
            return;
        }

        String action = request.getParameter("action");

        try (Connection conn = DBUtil.getConnection()) {
            // Get user ID
            PreparedStatement gps = conn.prepareStatement("SELECT id FROM users WHERE email=?");
            gps.setString(1, email);
            ResultSet grs = gps.executeQuery();
            if (!grs.next()) { response.sendRedirect("login.jsp?error=User+not+found"); return; }
            int userId = grs.getInt("id");
            grs.close(); gps.close();

            if ("editProfile".equals(action)) {
                String name = request.getParameter("name");
                String phone = request.getParameter("phone");
                String address = request.getParameter("address");
                String emergencyContact = request.getParameter("emergencyContact");

                PreparedStatement ups = conn.prepareStatement("UPDATE users SET name=?, phone=? WHERE id=?");
                ups.setString(1, name);
                ups.setString(2, phone);
                ups.setInt(3, userId);
                ups.executeUpdate(); ups.close();

                PreparedStatement cps = conn.prepareStatement("UPDATE customers SET address=?, emergency_contact=? WHERE user_id=?");
                cps.setString(1, address);
                cps.setString(2, emergencyContact);
                cps.setInt(3, userId);
                cps.executeUpdate(); cps.close();

                // Update session name
                session.setAttribute("customerName", name);
                response.sendRedirect("customer_dashboard.jsp?tab=profile&success=Profile+updated+successfully");

            } else if ("changePassword".equals(action)) {
                String currentPwd = request.getParameter("currentPassword");
                String newPwd = request.getParameter("newPassword");

                // Verify current password
                PreparedStatement vps = conn.prepareStatement("SELECT password_hash FROM users WHERE id=?");
                vps.setInt(1, userId);
                ResultSet vrs = vps.executeQuery();
                vrs.next();
                String storedHash = vrs.getString("password_hash");
                vrs.close(); vps.close();

                if (!SecurityUtil.checkPassword(currentPwd, storedHash)) {
                    response.sendRedirect("customer_dashboard.jsp?tab=profile&error=Current+password+is+incorrect");
                    return;
                }

                String newHash = SecurityUtil.hashPassword(newPwd);
                PreparedStatement pps = conn.prepareStatement("UPDATE users SET password_hash=? WHERE id=?");
                pps.setString(1, newHash);
                pps.setInt(2, userId);
                pps.executeUpdate(); pps.close();
                response.sendRedirect("customer_dashboard.jsp?tab=profile&success=Password+changed+successfully");

            } else {
                response.sendRedirect("customer_dashboard.jsp?error=Unknown+action");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("customer_dashboard.jsp?tab=profile&error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }
}
