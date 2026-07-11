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
import java.sql.ResultSet;

@WebServlet("/SubmitReviewServlet")
public class SubmitReviewServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        String email = (session != null) ? (String) session.getAttribute("customerEmail") : null;
        if (email == null) {
            response.sendRedirect("login.jsp?error=Please+login+first");
            return;
        }

        try (Connection conn = DBUtil.getConnection()) {
            // Get customer ID
            PreparedStatement cps = conn.prepareStatement(
                "SELECT c.id FROM customers c JOIN users u ON c.user_id=u.id WHERE u.email=?");
            cps.setString(1, email);
            ResultSet crs = cps.executeQuery();
            if (!crs.next()) { response.sendRedirect("login.jsp"); return; }
            int customerId = crs.getInt("id");
            crs.close(); cps.close();

            int bookingId = Integer.parseInt(request.getParameter("bookingId"));
            int rating = Integer.parseInt(request.getParameter("rating"));
            String comment = request.getParameter("comment");

            // Get service_id from booking
            PreparedStatement bps = conn.prepareStatement("SELECT service_id FROM bookings WHERE id=?");
            bps.setInt(1, bookingId);
            ResultSet brs = bps.executeQuery();
            if (!brs.next()) {
                response.sendRedirect("customer_dashboard.jsp?error=Booking+not+found");
                return;
            }
            int serviceId = brs.getInt("service_id");
            brs.close(); bps.close();

            // Check if already reviewed
            PreparedStatement chk = conn.prepareStatement(
                "SELECT id FROM reviews WHERE customer_id=? AND booking_id=?");
            chk.setInt(1, customerId);
            chk.setInt(2, bookingId);
            ResultSet chr = chk.executeQuery();
            if (chr.next()) {
                chr.close(); chk.close();
                response.sendRedirect("customer_dashboard.jsp?tab=history&error=You+already+reviewed+this+booking");
                return;
            }
            chr.close(); chk.close();

            PreparedStatement ips = conn.prepareStatement(
                "INSERT INTO reviews (customer_id, service_id, booking_id, rating, comment, status) VALUES (?,?,?,?,?,'Pending')");
            ips.setInt(1, customerId);
            ips.setInt(2, serviceId);
            ips.setInt(3, bookingId);
            ips.setInt(4, rating);
            ips.setString(5, comment);
            ips.executeUpdate(); ips.close();

            response.sendRedirect("customer_dashboard.jsp?tab=history&success=Review+submitted.+Pending+admin+approval.");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("customer_dashboard.jsp?error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }
}
