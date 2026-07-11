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

@WebServlet("/AddInventoryItemServlet")
public class AddInventoryItemServlet extends HttpServlet {
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

        String itemCode = request.getParameter("itemCode");
        String name = request.getParameter("name");
        String category = request.getParameter("category");
        String quantityStr = request.getParameter("quantity");
        String unit = request.getParameter("unit");
        String priceStr = request.getParameter("price");
        String thresholdStr = request.getParameter("threshold");
        String location = request.getParameter("location");

        if (itemCode == null || name == null || category == null || quantityStr == null || unit == null || priceStr == null ||
            itemCode.trim().isEmpty() || name.trim().isEmpty() || category.trim().isEmpty() || quantityStr.trim().isEmpty() || priceStr.trim().isEmpty()) {
            response.sendRedirect("admin_dashboard.jsp?error=Required%20fields%20cannot%20be%20empty.");
            return;
        }

        Connection conn = null;
        try {
            int quantity = Integer.parseInt(quantityStr);
            double price = Double.parseDouble(priceStr);
            int threshold = (thresholdStr != null && !thresholdStr.trim().isEmpty()) ? Integer.parseInt(thresholdStr) : 5;

            conn = DBUtil.getConnection();
            String query = "INSERT INTO inventory (item_code, name, category, quantity, unit, price, low_stock_threshold, location, status) " +
                           "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'In Stock')";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, itemCode);
            ps.setString(2, name);
            ps.setString(3, category);
            ps.setInt(4, quantity);
            ps.setString(5, unit);
            ps.setDouble(6, price);
            ps.setInt(7, threshold);
            ps.setString(8, location);

            int result = ps.executeUpdate();
            ps.close();

            if (result > 0) {
                response.sendRedirect("admin_dashboard.jsp?success=Inventory%20item%20added%20successfully!#inventory-panel");
            } else {
                response.sendRedirect("admin_dashboard.jsp?error=Failed%20to%20add%20inventory%20item.#inventory-panel");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?error=Duplicate%20item%20code%20or%20database%20error.#inventory-panel");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
