package com.vehicleservice.controller;

import com.vehicleservice.util.DBUtil;
import com.vehicleservice.util.SecurityUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

@WebServlet("/CustomerRegisterServlet")
public class CustomerRegisterServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String password = request.getParameter("password");

        if (name == null || email == null || phone == null || password == null ||
            name.trim().isEmpty() || email.trim().isEmpty() || phone.trim().isEmpty() || password.trim().isEmpty()) {
            response.sendRedirect("signup.jsp?error=All%20fields%20are%20required");
            return;
        }

        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false); // Begin Transaction
            
            // Check if email already exists
            String checkQuery = "SELECT id FROM users WHERE email = ?";
            PreparedStatement checkStmt = conn.prepareStatement(checkQuery);
            checkStmt.setString(1, email);
            ResultSet checkRs = checkStmt.executeQuery();
            if (checkRs.next()) {
                response.sendRedirect("signup.jsp?error=Email%20already%20registered");
                checkRs.close();
                checkStmt.close();
                conn.rollback();
                return;
            }
            checkRs.close();
            checkStmt.close();

            // Hash the password using BCrypt via SecurityUtil
            String hashedPassword = SecurityUtil.hashPassword(password);

            // Insert new user with Customer role_id = 3
            String insertUserQuery = "INSERT INTO users (name, email, phone, password_hash, role_id, status) VALUES (?, ?, ?, ?, 3, 'Active')";
            PreparedStatement insertUserStmt = conn.prepareStatement(insertUserQuery, Statement.RETURN_GENERATED_KEYS);
            insertUserStmt.setString(1, name);
            insertUserStmt.setString(2, email);
            insertUserStmt.setString(3, phone);
            insertUserStmt.setString(4, hashedPassword);

            int userResult = insertUserStmt.executeUpdate();
            
            int userId = -1;
            ResultSet generatedKeys = insertUserStmt.getGeneratedKeys();
            if (generatedKeys.next()) {
                userId = generatedKeys.getInt(1);
            }
            generatedKeys.close();
            insertUserStmt.close();

            if (userResult > 0 && userId != -1) {
                // Insert corresponding record in customers table
                String insertCustQuery = "INSERT INTO customers (user_id, address, loyalty_points) VALUES (?, '', 100)"; // Start with 100 loyalty points!
                PreparedStatement insertCustStmt = conn.prepareStatement(insertCustQuery);
                insertCustStmt.setInt(1, userId);
                int custResult = insertCustStmt.executeUpdate();
                insertCustStmt.close();

                if (custResult > 0) {
                    conn.commit(); // Commit Transaction
                    response.sendRedirect("login.jsp?success=Registration%20successful!%20Please%20log%20in.");
                    return;
                }
            }
            
            // Rollback if any insert failed
            conn.rollback();
            response.sendRedirect("signup.jsp?error=Registration%20failed.%20Please%20try%20again.");
        } catch (Exception e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignore) {}
            }
            response.sendRedirect("signup.jsp?error=Database%20error%20occurred.");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
