package com.vehicleservice.controller;

import com.vehicleservice.util.DBUtil;
import com.vehicleservice.util.SecurityUtil;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/CustomerLoginServlet")
public class CustomerLoginServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || password == null || email.trim().isEmpty() || password.trim().isEmpty()) {
            response.sendRedirect("login.jsp?error=All%20fields%20are%20required");
            return;
        }

        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            // Select user details and customer ID
            String query = "SELECT u.*, c.id AS customer_id FROM users u " +
                           "JOIN customers c ON u.id = c.user_id " +
                           "WHERE u.email=? AND u.role_id = 3 AND u.status = 'Active'";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, email);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) { 
                String hashedPassword = rs.getString("password_hash");
                
                // Validate password using BCrypt via SecurityUtil
                if (SecurityUtil.checkPassword(password, hashedPassword)) {
                    HttpSession session = request.getSession();
                    session.setAttribute("customerEmail", email);
                    session.setAttribute("customerName", rs.getString("name"));
                    session.setAttribute("customerPhone", rs.getString("phone"));
                    session.setAttribute("customerId", rs.getInt("customer_id"));
                    
                    // Generate initial CSRF token for the customer session
                    SecurityUtil.generateCSRFToken(session);
                    
                    response.sendRedirect("customer_dashboard.jsp"); 
                    rs.close();
                    ps.close();
                    return;
                }
            }
            response.sendRedirect("login.jsp?error=Invalid%20Credentials");
            if (rs != null) rs.close();
            if (ps != null) ps.close();
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("login.jsp?error=Database%20Error");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
