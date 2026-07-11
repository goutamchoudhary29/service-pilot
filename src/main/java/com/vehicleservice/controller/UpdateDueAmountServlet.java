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

@WebServlet("/UpdateDueAmountServlet")
public class UpdateDueAmountServlet extends HttpServlet {
    // DB credentials removed for DBUtil

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        int id = Integer.parseInt(request.getParameter("id"));
        double amountDue = Double.parseDouble(request.getParameter("amount_due"));

        try {
            Connection conn = DBUtil.getConnection();
            String query = "UPDATE service_bookings SET amount_due = ? WHERE id = ?";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setDouble(1, amountDue);
            ps.setInt(2, id);
            ps.executeUpdate();
            conn.close();

            response.sendRedirect("admin_dashboard.jsp");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
