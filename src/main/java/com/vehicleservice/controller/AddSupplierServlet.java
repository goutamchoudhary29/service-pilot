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

@WebServlet("/AddSupplierServlet")
public class AddSupplierServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.sendRedirect("admin_login.jsp?error=Access%20Denied.");
            return;
        }

        // Validate CSRF
        if (!SecurityUtil.validateCSRFToken(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "CSRF Validation Failed");
            return;
        }

        String name = request.getParameter("name");
        String contactName = request.getParameter("contactName");
        String phone = request.getParameter("phone");
        String email = request.getParameter("email");
        String address = request.getParameter("address");

        if (name == null || name.trim().isEmpty()) {
            response.sendRedirect("admin_dashboard.jsp?error=Supplier%20name%20is%20required.#suppliers-panel");
            return;
        }

        Connection conn = null;
        try {
            conn = DBUtil.getConnection();
            String query = "INSERT INTO suppliers (name, contact_name, phone, email, address) VALUES (?, ?, ?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, name);
            ps.setString(2, contactName);
            ps.setString(3, phone);
            ps.setString(4, email);
            ps.setString(5, address);

            int result = ps.executeUpdate();
            ps.close();

            if (result > 0) {
                response.sendRedirect("admin_dashboard.jsp?success=Supplier%20registered%20successfully!#suppliers-panel");
            } else {
                response.sendRedirect("admin_dashboard.jsp?error=Failed%20to%20register%20supplier.#suppliers-panel");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?error=Database%20error%20occurred.#suppliers-panel");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
