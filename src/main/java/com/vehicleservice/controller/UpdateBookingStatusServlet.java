package com.vehicleservice.controller;

import com.vehicleservice.util.DBUtil;
import com.vehicleservice.util.SecurityUtil;
import com.vehicleservice.util.AuditLogUtil;

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

@WebServlet("/UpdateBookingStatusServlet")
public class UpdateBookingStatusServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.sendRedirect("admin_login.jsp?error=Access%20Denied.");
            return;
        }

        // CSRF Verification
        if (!SecurityUtil.validateCSRFToken(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "CSRF Verification Failed");
            return;
        }

        int adminUserId = (Integer) session.getAttribute("userId");
        String bookingIdStr = request.getParameter("bookingId");
        String status = request.getParameter("status");
        String paymentStatus = request.getParameter("paymentStatus");
        String mechanicIdStr = request.getParameter("mechanicId");
        String finalAmountStr = request.getParameter("finalAmount");

        if (bookingIdStr == null || bookingIdStr.trim().isEmpty()) {
            response.sendRedirect("admin_dashboard.jsp?error=Invalid%20Parameters.");
            return;
        }

        Connection conn = null;
        try {
            int bookingId = Integer.parseInt(bookingIdStr);
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false); // Begin Transaction

            // 1. Update Booking status and Mechanic ID
            String updateBookingQuery = "UPDATE bookings SET status = ?, mechanic_id = ? WHERE id = ?";
            PreparedStatement ps = conn.prepareStatement(updateBookingQuery);
            ps.setString(1, status);
            if (mechanicIdStr != null && !mechanicIdStr.trim().isEmpty() && !"0".equals(mechanicIdStr)) {
                ps.setInt(2, Integer.parseInt(mechanicIdStr));
            } else {
                ps.setNull(2, java.sql.Types.INTEGER);
            }
            ps.setInt(3, bookingId);
            ps.executeUpdate();
            ps.close();

            // 2. Fetch invoice matching this booking
            String checkInv = "SELECT id FROM invoices WHERE booking_id = ?";
            PreparedStatement checkPs = conn.prepareStatement(checkInv);
            checkPs.setInt(1, bookingId);
            ResultSet checkRs = checkPs.executeQuery();
            int invoiceId = -1;
            if (checkRs.next()) {
                invoiceId = checkRs.getInt("id");
            }
            checkRs.close();
            checkPs.close();

            // 3. Update Invoice amount and Payment status if invoice exists
            if (invoiceId != -1) {
                if (finalAmountStr != null && !finalAmountStr.trim().isEmpty()) {
                    double finalAmount = Double.parseDouble(finalAmountStr);
                    String updateInvoiceQuery = "UPDATE invoices SET final_amount = ? WHERE id = ?";
                    PreparedStatement psInv = conn.prepareStatement(updateInvoiceQuery);
                    psInv.setDouble(1, finalAmount);
                    psInv.setInt(2, invoiceId);
                    psInv.executeUpdate();
                    psInv.close();
                }

                if (paymentStatus != null && !paymentStatus.trim().isEmpty()) {
                    String updatePayQuery = "UPDATE payments SET payment_status = ? WHERE invoice_id = ?";
                    PreparedStatement psPay = conn.prepareStatement(updatePayQuery);
                    psPay.setString(1, paymentStatus);
                    psPay.setInt(2, invoiceId);
                    psPay.executeUpdate();
                    psPay.close();
                }
            }

            // Log action in central audit logs
            AuditLogUtil.log(adminUserId, "UPDATE_BOOKING_STATUS: status=" + status + ", payment=" + paymentStatus, "bookings", bookingId, request.getRemoteAddr());

            conn.commit(); // Commit Transaction
            response.sendRedirect("admin_dashboard.jsp?success=Booking%20updated%20successfully!");
        } catch (Exception e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignore) {}
            }
            response.sendRedirect("admin_dashboard.jsp?error=Database%20error%20occurred.");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
