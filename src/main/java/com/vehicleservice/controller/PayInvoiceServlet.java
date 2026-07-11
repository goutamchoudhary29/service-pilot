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

@WebServlet("/PayInvoiceServlet")
public class PayInvoiceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("customerEmail") == null) {
            response.sendRedirect("login.jsp?error=Please%20log%20in%20first.");
            return;
        }

        // CSRF Verification
        if (!SecurityUtil.validateCSRFToken(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "CSRF Verification Failed");
            return;
        }

        String invoiceIdStr = request.getParameter("invoiceId");
        String paymentMethod = request.getParameter("paymentMethod");

        if (invoiceIdStr == null || paymentMethod == null || invoiceIdStr.trim().isEmpty() || paymentMethod.trim().isEmpty()) {
            response.sendRedirect("customer_dashboard.jsp?error=Invalid%20Parameters.");
            return;
        }

        Connection conn = null;
        try {
            int invoiceId = Integer.parseInt(invoiceIdStr);
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false); // Begin Transaction

            // Check if there is an existing payment record
            String updatePaymentQuery = "UPDATE payments SET payment_status = 'Paid', payment_method = ?, transaction_id = ? WHERE invoice_id = ?";
            PreparedStatement ps = conn.prepareStatement(updatePaymentQuery);
            ps.setString(1, paymentMethod);
            ps.setString(2, "TXN-" + System.currentTimeMillis());
            ps.setInt(3, invoiceId);
            
            int result = ps.executeUpdate();
            ps.close();

            if (result > 0) {
                conn.commit();
                response.sendRedirect("customer_dashboard.jsp?success=Payment%20successful!%20Thank%20you.");
            } else {
                conn.rollback();
                response.sendRedirect("customer_dashboard.jsp?error=Failed%20to%20process%20payment.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignore) {}
            }
            response.sendRedirect("customer_dashboard.jsp?error=Database%20error%20occurred.");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
