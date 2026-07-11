package com.vehicleservice.controller;

import com.google.gson.Gson;
import com.vehicleservice.util.DBUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Date;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/CheckSlotAvailabilityServlet")
public class CheckSlotAvailabilityServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        String dateStr = request.getParameter("date");
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        PrintWriter out = response.getWriter();
        Gson gson = new Gson();

        if (dateStr == null || dateStr.trim().isEmpty()) {
            Map<String, String> errorMap = new HashMap<>();
            errorMap.put("error", "Missing date parameter");
            out.print(gson.toJson(errorMap));
            return;
        }

        Connection conn = null;
        try {
            Date bookingDate = Date.valueOf(dateStr);
            conn = DBUtil.getConnection();

            // Query booked time slot and mechanic combinations
            String query = "SELECT b.time_slot, b.mechanic_id, u.name AS mechanic_name " +
                           "FROM bookings b " +
                           "JOIN mechanics m ON b.mechanic_id = m.id " +
                           "JOIN employees e ON m.employee_id = e.id " +
                           "JOIN users u ON e.user_id = u.id " +
                           "WHERE b.booking_date = ? AND b.status != 'Cancelled'";
            
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setDate(1, bookingDate);
            ResultSet rs = ps.executeQuery();

            List<Map<String, Object>> bookedSlots = new ArrayList<>();
            while (rs.next()) {
                Map<String, Object> slot = new HashMap<>();
                slot.put("timeSlot", rs.getString("time_slot"));
                slot.put("mechanicId", rs.getInt("mechanic_id"));
                slot.put("mechanicName", rs.getString("mechanic_name"));
                bookedSlots.add(slot);
            }
            rs.close();
            ps.close();

            // Return JSON payload
            out.print(gson.toJson(bookedSlots));

        } catch (IllegalArgumentException e) {
            Map<String, String> errorMap = new HashMap<>();
            errorMap.put("error", "Invalid date format. Use YYYY-MM-DD.");
            out.print(gson.toJson(errorMap));
        } catch (Exception e) {
            e.printStackTrace();
            Map<String, String> errorMap = new HashMap<>();
            errorMap.put("error", "Database error occurred.");
            out.print(gson.toJson(errorMap));
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
