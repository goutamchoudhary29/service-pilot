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

@WebServlet("/UpdatePaymentStatusServlet")
public class UpdatePaymentStatusServlet extends HttpServlet {
    private static final String DB_URL = "jdbc:mysql://localhost:3306/servicepilot";
    private static final String DB_USER = "root";
    private static final String DB_PASSWORD = "9926";

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        String paymentStatus = request.getParameter("payment_status");

        try {
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            String query = "UPDATE service_bookings SET payment_status = ? WHERE id = ?";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, paymentStatus);
            ps.setInt(2, id);
            ps.executeUpdate();
            conn.close();

            response.sendRedirect("admin_dashboard.jsp");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
