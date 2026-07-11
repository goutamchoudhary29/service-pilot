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
import com.vehicleservice.util.DBUtil;

@WebServlet("/UpdateServiceStatusServlet")
public class UpdateServiceStatusServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    // DB credentials removed for DBUtil

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int bookingId = Integer.parseInt(request.getParameter("id"));
        String newStatus = request.getParameter("service_status");

        try {
            Connection conn = DBUtil.getConnection();
            String query = "UPDATE service_bookings SET service_status = ? WHERE id = ?";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, newStatus);
            ps.setInt(2, bookingId);

            ps.executeUpdate();
            conn.close();

            response.sendRedirect("admin_dashboard.jsp");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
