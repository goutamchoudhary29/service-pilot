package com.vehicleservice.controller;

import com.vehicleservice.util.EmailUtil;
import com.vehicleservice.util.SecurityUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/SendCustomerEmailServlet")
public class SendCustomerEmailServlet extends HttpServlet {
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

        String recipient = request.getParameter("recipient");
        String subject = request.getParameter("subject");
        String message = request.getParameter("message");

        if (recipient == null || subject == null || message == null ||
            recipient.trim().isEmpty() || subject.trim().isEmpty() || message.trim().isEmpty()) {
            response.sendRedirect("admin_dashboard.jsp?error=All%20fields%20are%20required.");
            return;
        }

        try {
            // Dispatch asynchronously
            EmailUtil.sendEmailAsync(recipient, subject, message);
            response.sendRedirect("admin_dashboard.jsp?success=Email%20dispatched%20successfully!");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?error=Failed%20to%20send%20email.");
        }
    }
}
