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
import java.sql.Date;

@WebServlet("/PurchaseItemServlet")
public class PurchaseItemServlet extends HttpServlet {
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

        String supplierIdStr = request.getParameter("supplierId");
        String itemName = request.getParameter("itemName");
        String quantityStr = request.getParameter("quantity");
        String priceStr = request.getParameter("price");
        String purchaseDateStr = request.getParameter("purchaseDate");
        String invoiceNo = request.getParameter("invoiceNo");

        if (supplierIdStr == null || itemName == null || quantityStr == null || priceStr == null || purchaseDateStr == null ||
            supplierIdStr.trim().isEmpty() || itemName.trim().isEmpty() || quantityStr.trim().isEmpty() || priceStr.trim().isEmpty() || purchaseDateStr.trim().isEmpty()) {
            response.sendRedirect("admin_dashboard.jsp?error=All%20fields%20are%20required.#suppliers-panel");
            return;
        }

        Connection conn = null;
        try {
            int supplierId = Integer.parseInt(supplierIdStr);
            int quantity = Integer.parseInt(quantityStr);
            double price = Double.parseDouble(priceStr);
            Date purchaseDate = Date.valueOf(purchaseDateStr);

            conn = DBUtil.getConnection();
            conn.setAutoCommit(false); // Begin Transaction

            // 1. Insert purchase history record
            String purchaseQuery = "INSERT INTO purchase_history (supplier_id, item_name, quantity, price, purchase_date, invoice_no) " +
                                   "VALUES (?, ?, ?, ?, ?, ?)";
            PreparedStatement ps = conn.prepareStatement(purchaseQuery);
            ps.setInt(1, supplierId);
            ps.setString(2, itemName);
            ps.setInt(3, quantity);
            ps.setDouble(4, price);
            ps.setDate(5, purchaseDate);
            ps.setString(6, invoiceNo);
            ps.executeUpdate();
            ps.close();

            // 2. Automatically increment matching item in inventory if it exists
            String checkInvQuery = "UPDATE inventory SET quantity = quantity + ? WHERE name = ?";
            PreparedStatement checkInvPs = conn.prepareStatement(checkInvQuery);
            checkInvPs.setInt(1, quantity);
            checkInvPs.setString(2, itemName);
            checkInvPs.executeUpdate();
            checkInvPs.close();

            conn.commit(); // Commit Transaction
            response.sendRedirect("admin_dashboard.jsp?success=Purchase%20history%20logged%20successfully!#suppliers-panel");
        } catch (Exception e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignore) {}
            }
            response.sendRedirect("admin_dashboard.jsp?error=Database%20error%20occurred.#suppliers-panel");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }
}
