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

@WebServlet("/UpdateInventoryStockServlet")
public class UpdateInventoryStockServlet extends HttpServlet {
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

        int userId = (Integer) session.getAttribute("userId");
        String inventoryIdStr = request.getParameter("inventoryId");
        String type = request.getParameter("type"); // "Stock In" or "Stock Out"
        String quantityStr = request.getParameter("quantity");
        String reason = request.getParameter("reason");

        if (inventoryIdStr == null || type == null || quantityStr == null ||
            inventoryIdStr.trim().isEmpty() || type.trim().isEmpty() || quantityStr.trim().isEmpty()) {
            response.sendRedirect("admin_dashboard.jsp?error=Invalid%20Parameters.#inventory-panel");
            return;
        }

        Connection conn = null;
        try {
            int inventoryId = Integer.parseInt(inventoryIdStr);
            int qtyChange = Integer.parseInt(quantityStr);

            conn = DBUtil.getConnection();
            conn.setAutoCommit(false); // Begin Transaction

            // 1. Update quantity in inventory table
            String updateInvQuery;
            if ("Stock In".equals(type)) {
                updateInvQuery = "UPDATE inventory SET quantity = quantity + ? WHERE id = ?";
            } else {
                updateInvQuery = "UPDATE inventory SET quantity = GREATEST(0, quantity - ?) WHERE id = ?";
            }

            PreparedStatement updatePs = conn.prepareStatement(updateInvQuery);
            updatePs.setInt(1, qtyChange);
            updatePs.setInt(2, inventoryId);
            updatePs.executeUpdate();
            updatePs.close();

            // 2. Log transaction in inventory_logs
            String logQuery = "INSERT INTO inventory_logs (inventory_id, type, quantity, reason, user_id) VALUES (?, ?, ?, ?, ?)";
            PreparedStatement logPs = conn.prepareStatement(logQuery);
            logPs.setInt(1, inventoryId);
            logPs.setString(2, type);
            logPs.setInt(3, qtyChange);
            logPs.setString(4, reason != null ? reason : "");
            logPs.setInt(5, userId);
            logPs.executeUpdate();
            logPs.close();

            // central audit log trace
            com.vehicleservice.util.AuditLogUtil.log(userId, "STOCK_ADJUSTMENT: " + type + " (" + qtyChange + ")", "inventory", inventoryId, request.getRemoteAddr());

            conn.commit(); // Commit Transaction
            response.sendRedirect("admin_dashboard.jsp?success=Stock%20quantity%20updated%20successfully!#inventory-panel");
        } catch (Exception e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignore) {}
            }
            response.sendRedirect("admin_dashboard.jsp?error=Failed%20to%20update%20stock.#inventory-panel");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
