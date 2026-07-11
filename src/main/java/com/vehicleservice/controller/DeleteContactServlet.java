package com.vehicleservice.controller;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/DeleteContactServlet")
public class DeleteContactServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    private static final String DB_URL = "jdbc:mysql://localhost:3306/servicepilot";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "9926";

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int messageId = Integer.parseInt(request.getParameter("id"));

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            String query = "DELETE FROM contact_messages WHERE id = ?";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setInt(1, messageId);

            ps.executeUpdate();
            conn.close();

            response.sendRedirect("admin_dashboard.jsp"); // Dashboard पर Redirect करें
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
