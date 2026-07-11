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

@WebServlet("/AdminLoginServlet")
public class AdminLoginServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        if (email == null || password == null || email.trim().isEmpty() || password.trim().isEmpty()) {
            response.sendRedirect("admin_login.jsp?error=All%20fields%20are%20required");
            return;
        }

        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            // Authenticate any employee / admin role (1=SuperAdmin, 2=Admin, 4=Mechanic, 5=Receptionist, 6=Inventory, 7=Accountant)
            String query = "SELECT * FROM users WHERE email = ? AND role_id IN (1, 2, 4, 5, 6, 7) AND status = 'Active'";
            PreparedStatement pstmt = conn.prepareStatement(query);
            pstmt.setString(1, email);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                String hashedPassword = rs.getString("password_hash");

                // Verify via BCrypt
                if (SecurityUtil.checkPassword(password, hashedPassword)) {
                    HttpSession session = request.getSession();
                    int roleId = rs.getInt("role_id");
                    int userId = rs.getInt("id");

                    session.setAttribute("adminEmail", email);
                    session.setAttribute("adminName", rs.getString("name"));
                    session.setAttribute("adminRoleId", roleId);
                    session.setAttribute("userId", userId);
                    
                    // Generate initial CSRF token for this session
                    SecurityUtil.generateCSRFToken(session);

                    // Redirect mechanics to their workspace
                    if (roleId == 4) {
                        String getMechQuery = "SELECT m.id AS mechanic_id FROM mechanics m " +
                                               "JOIN employees e ON m.employee_id = e.id " +
                                               "WHERE e.user_id = ?";
                        PreparedStatement psMech = conn.prepareStatement(getMechQuery);
                        psMech.setInt(1, userId);
                        ResultSet rsMech = psMech.executeQuery();
                        if (rsMech.next()) {
                            session.setAttribute("mechanicId", rsMech.getInt("mechanic_id"));
                        }
                        rsMech.close();
                        psMech.close();
                        
                        response.sendRedirect("mechanic_dashboard.jsp");
                    } else {
                        response.sendRedirect("admin_dashboard.jsp");
                    }
                    
                    rs.close();
                    pstmt.close();
                    return;
                }
            }
            response.sendRedirect("admin_login.jsp?error=Invalid%20Credentials");
            rs.close();
            pstmt.close();
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_login.jsp?error=Something%20went%20wrong");
        } finally {
            try { if (conn != null) conn.close(); } catch (Exception ignore) {}
        }
    }
}
