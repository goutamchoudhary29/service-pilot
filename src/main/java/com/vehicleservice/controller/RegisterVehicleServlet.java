package com.vehicleservice.controller;

import com.vehicleservice.util.DBUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.Date;

@WebServlet("/RegisterVehicleServlet")
public class RegisterVehicleServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("customerId") == null) {
            response.sendRedirect("login.jsp?error=Please%20log%20in%20first.");
            return;
        }

        int customerId = (Integer) session.getAttribute("customerId");

        String licensePlate = request.getParameter("licensePlate");
        String vin = request.getParameter("vin");
        String brand = request.getParameter("brand");
        String model = request.getParameter("model");
        String fuelType = request.getParameter("fuelType");
        String insurancePolicyNo = request.getParameter("insurancePolicyNo");
        String insuranceExpiryStr = request.getParameter("insuranceExpiry");
        String pucExpiryStr = request.getParameter("pucExpiry");
        String warrantyExpiryStr = request.getParameter("warrantyExpiry");
        String mileageStr = request.getParameter("mileage");

        if (licensePlate == null || vin == null || brand == null || model == null || fuelType == null ||
            licensePlate.trim().isEmpty() || vin.trim().isEmpty() || brand.trim().isEmpty() || model.trim().isEmpty()) {
            response.sendRedirect("customer_dashboard.jsp?error=Required%20fields%20cannot%20be%20empty.");
            return;
        }

        int mileage = 0;
        try {
            if (mileageStr != null && !mileageStr.trim().isEmpty()) {
                mileage = Integer.parseInt(mileageStr);
            }
        } catch (NumberFormatException e) {
            e.printStackTrace();
        }

        Date insuranceExpiry = parseDate(insuranceExpiryStr);
        Date pucExpiry = parseDate(pucExpiryStr);
        Date warrantyExpiry = parseDate(warrantyExpiryStr);

        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            String query = "INSERT INTO vehicles (customer_id, vin, license_plate, brand, model, fuel_type, " +
                           "insurance_policy_no, insurance_expiry, puc_expiry, warranty_expiry, mileage, status) " +
                           "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Active')";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setInt(1, customerId);
            ps.setString(2, vin);
            ps.setString(3, licensePlate);
            ps.setString(4, brand);
            ps.setString(5, model);
            ps.setString(6, fuelType);
            ps.setString(7, insurancePolicyNo);
            ps.setDate(8, insuranceExpiry);
            ps.setDate(9, pucExpiry);
            ps.setDate(10, warrantyExpiry);
            ps.setInt(11, mileage);

            int result = ps.executeUpdate();
            ps.close();

            if (result > 0) {
                response.sendRedirect("customer_dashboard.jsp?success=Vehicle%20registered%20successfully!");
            } else {
                response.sendRedirect("customer_dashboard.jsp?error=Failed%20to%20register%20vehicle.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("customer_dashboard.jsp?error=Vehicle%20already%20exists%20or%20database%20error.");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }

    private Date parseDate(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) {
            return null;
        }
        try {
            return Date.valueOf(dateStr);
        } catch (IllegalArgumentException e) {
            e.printStackTrace();
            return null;
        }
    }
}
