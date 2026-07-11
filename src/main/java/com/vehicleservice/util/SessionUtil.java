package com.vehicleservice.util;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

public class SessionUtil {
    
    /**
     * Validates if a session contains a valid admin email.
     */
    public static boolean validateAdminSession(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminEmail") == null) {
            response.sendRedirect(request.getContextPath() + "/admin_login.jsp?error=Session%20expired.%20Please%20login%20again.");
            return false;
        }
        return true;
    }

    /**
     * Validates if a session contains a valid customer email.
     */
    public static boolean validateCustomerSession(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("customerEmail") == null) {
            response.sendRedirect(request.getContextPath() + "/login.jsp?error=Please%20log%20in%20first.");
            return false;
        }
        return true;
    }

    /**
     * Clears session attributes on logout.
     */
    public static void invalidateSession(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
    }
}
