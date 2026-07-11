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
import java.sql.Date;
import java.util.Calendar;

@WebServlet("/BookServiceServlet")
public class BookServiceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("customerId") == null) {
            response.sendRedirect("login.jsp?error=Please%20log%20in%20first.");
            return;
        }

        // Validate CSRF
        if (!SecurityUtil.validateCSRFToken(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "CSRF Validation Failed");
            return;
        }

        int customerId = (Integer) session.getAttribute("customerId");

        String vehicleIdStr = request.getParameter("vehicleId");
        String serviceIdStr = request.getParameter("serviceId");
        String branchIdStr = request.getParameter("branchId");
        String mechanicIdStr = request.getParameter("mechanicId");
        String bookingDateStr = request.getParameter("bookingDate");
        String timeSlot = request.getParameter("timeSlot");
        String additionalNotes = request.getParameter("additionalNotes");

        if (vehicleIdStr == null || serviceIdStr == null || branchIdStr == null || mechanicIdStr == null ||
            bookingDateStr == null || timeSlot == null ||
            vehicleIdStr.trim().isEmpty() || serviceIdStr.trim().isEmpty() ||
            branchIdStr.trim().isEmpty() || mechanicIdStr.trim().isEmpty() ||
            bookingDateStr.trim().isEmpty() || timeSlot.trim().isEmpty()) {
            response.sendRedirect("bookservice.jsp?error=All%20fields%20are%20required.");
            return;
        }

        Connection conn = null;
        try {
            int vehicleId = Integer.parseInt(vehicleIdStr);
            int serviceId = Integer.parseInt(serviceIdStr);
            int branchId = Integer.parseInt(branchIdStr);
            int mechanicId = Integer.parseInt(mechanicIdStr);
            Date bookingDate = Date.valueOf(bookingDateStr);

            conn = DBUtil.getConnection();
            conn.setAutoCommit(false); // Begin Transaction

            // 1. Prevent Double Booking: Check if the mechanic is already occupied in that slot
            String doubleBookQuery = "SELECT id FROM bookings WHERE booking_date = ? AND time_slot = ? AND mechanic_id = ? AND status != 'Cancelled'";
            PreparedStatement doubleBookPs = conn.prepareStatement(doubleBookQuery);
            doubleBookPs.setDate(1, bookingDate);
            doubleBookPs.setString(2, timeSlot);
            doubleBookPs.setInt(3, mechanicId);
            ResultSet doubleBookRs = doubleBookPs.executeQuery();
            
            if (doubleBookRs.next()) {
                doubleBookRs.close();
                doubleBookPs.close();
                conn.rollback();
                response.sendRedirect("bookservice.jsp?error=Selected%20mechanic%20is%20already%20booked%20for%20this%20time%20slot.");
                return;
            }
            doubleBookRs.close();
            doubleBookPs.close();

            // 2. Generate Serial Booking ID (SP-2026-000001)
            int currentYear = Calendar.getInstance().get(Calendar.YEAR);
            String countQuery = "SELECT COUNT(*) FROM bookings WHERE YEAR(created_at) = ?";
            PreparedStatement countPs = conn.prepareStatement(countQuery);
            countPs.setInt(1, currentYear);
            ResultSet countRs = countPs.executeQuery();
            int count = 0;
            if (countRs.next()) {
                count = countRs.getInt(1);
            }
            countRs.close();
            countPs.close();
            
            String bookingUid = String.format("SP-%d-%06d", currentYear, count + 1);

            // 3. Insert Booking record
            String insertQuery = "INSERT INTO bookings (booking_uid, customer_id, vehicle_id, service_id, branch_id, mechanic_id, " +
                                 "booking_date, time_slot, status, additional_notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Pending', ?)";
            PreparedStatement insertPs = conn.prepareStatement(insertQuery, java.sql.Statement.RETURN_GENERATED_KEYS);
            insertPs.setString(1, bookingUid);
            insertPs.setInt(2, customerId);
            insertPs.setInt(3, vehicleId);
            insertPs.setInt(4, serviceId);
            insertPs.setInt(5, branchId);
            insertPs.setInt(6, mechanicId);
            insertPs.setDate(7, bookingDate);
            insertPs.setString(8, timeSlot);
            insertPs.setString(9, additionalNotes);

            int result = insertPs.executeUpdate();
            int newBookingId = -1;
            ResultSet gks = insertPs.getGeneratedKeys();
            if (gks.next()) {
                newBookingId = gks.getInt(1);
            }
            gks.close();
            insertPs.close();

            if (result > 0) {
                conn.commit(); // Commit Transaction
                
                // Dispatch Confirmation Email using template
                if (newBookingId > 0) {
                    com.vehicleservice.util.EmailUtil.sendBookingStatusEmail(newBookingId);
                }
                
                response.sendRedirect("customer_dashboard.jsp?success=Booking%20confirmed!%20Your%20Booking%20ID%20is%20" + bookingUid);
            } else {
                conn.rollback();
                response.sendRedirect("bookservice.jsp?error=Failed%20to%20create%20booking.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignore) {}
            }
            response.sendRedirect("bookservice.jsp?error=Database%20error%20occurred.");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
