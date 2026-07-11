package com.vehicleservice.controller;

import com.vehicleservice.util.DBUtil;
import com.vehicleservice.util.EmailUtil;
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

@WebServlet("/ManagePaymentServlet")
public class ManagePaymentServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.sendRedirect("admin_login.jsp?error=Access+Denied");
            return;
        }

        String action = request.getParameter("action");
        int paymentId = Integer.parseInt(request.getParameter("paymentId"));

        try (Connection conn = DBUtil.getConnection()) {
            switch (action) {
                case "markPaid":
                    String txnId = "TXN" + System.currentTimeMillis();
                    String method = request.getParameter("paymentMethod");
                    if (method == null || method.isEmpty()) method = "Cash";
                    
                    // Get invoice amount
                    PreparedStatement gps = conn.prepareStatement(
                        "SELECT i.final_amount FROM payments p JOIN invoices i ON p.invoice_id=i.id WHERE p.id=?");
                    gps.setInt(1, paymentId);
                    ResultSet grs = gps.executeQuery();
                    double amt = 0;
                    if (grs.next()) amt = grs.getDouble(1);
                    grs.close(); gps.close();

                    PreparedStatement ups = conn.prepareStatement(
                        "UPDATE payments SET payment_status='Paid', paid_amount=?, transaction_id=?, payment_method=? WHERE id=?");
                    ups.setDouble(1, amt);
                    ups.setString(2, txnId);
                    ups.setString(3, method);
                    ups.setInt(4, paymentId);
                    ups.executeUpdate(); ups.close();
                    
                    sendPaymentEmail(conn, paymentId, amt, txnId, method);
                    response.sendRedirect("admin_dashboard.jsp?tab=payments&success=Payment+marked+as+Paid");
                    break;

                case "partialPayment":
                    double partialAmt = Double.parseDouble(request.getParameter("amount"));
                    String pMethod = request.getParameter("paymentMethod");
                    String pTxn = "TXN" + System.currentTimeMillis();
                    
                    PreparedStatement pps = conn.prepareStatement(
                        "UPDATE payments SET payment_status='Partial', paid_amount=?, transaction_id=?, payment_method=? WHERE id=?");
                    pps.setDouble(1, partialAmt);
                    pps.setString(2, pTxn);
                    pps.setString(3, pMethod);
                    pps.setInt(4, paymentId);
                    pps.executeUpdate(); pps.close();
                    response.sendRedirect("admin_dashboard.jsp?tab=payments&success=Partial+payment+recorded");
                    break;

                case "refund":
                    double refundAmt = Double.parseDouble(request.getParameter("refundAmount"));
                    String reason = request.getParameter("refundReason");
                    PreparedStatement rps = conn.prepareStatement(
                        "UPDATE payments SET payment_status='Refunded', refund_amount=?, refund_reason=? WHERE id=?");
                    rps.setDouble(1, refundAmt);
                    rps.setString(2, reason);
                    rps.setInt(3, paymentId);
                    rps.executeUpdate(); rps.close();
                    response.sendRedirect("admin_dashboard.jsp?tab=payments&success=Refund+processed");
                    break;

                case "delete":
                    conn.prepareStatement("DELETE FROM payments WHERE id=" + paymentId).executeUpdate();
                    response.sendRedirect("admin_dashboard.jsp?tab=payments&success=Payment+deleted");
                    break;

                default:
                    response.sendRedirect("admin_dashboard.jsp?tab=payments&error=Unknown+action");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?tab=payments&error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    private void sendPaymentEmail(Connection conn, int paymentId, double amount, String txnId, String method) {
        try {
            String sql = "SELECT u.name, u.email, b.booking_uid, v.brand, v.model " +
                "FROM payments p " +
                "JOIN invoices i ON p.invoice_id=i.id " +
                "JOIN bookings b ON i.booking_id=b.id " +
                "JOIN customers c ON b.customer_id=c.id " +
                "JOIN users u ON c.user_id=u.id " +
                "JOIN vehicles v ON b.vehicle_id=v.id " +
                "WHERE p.id=?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, paymentId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                PreparedStatement tps = conn.prepareStatement("SELECT subject, body_html FROM email_templates WHERE template_key='payment_received'");
                ResultSet trs = tps.executeQuery();
                if (trs.next()) {
                    String subject = trs.getString("subject").replace("{{booking_uid}}", rs.getString("booking_uid"));
                    String body = trs.getString("body_html")
                        .replace("{{customer_name}}", rs.getString("name"))
                        .replace("{{booking_uid}}", rs.getString("booking_uid"))
                        .replace("{{vehicle_brand}}", rs.getString("brand"))
                        .replace("{{vehicle_model}}", rs.getString("model"))
                        .replace("{{amount}}", String.format("%.2f", amount))
                        .replace("{{transaction_id}}", txnId)
                        .replace("{{payment_method}}", method);
                    EmailUtil.sendEmailAsync(rs.getString("email"), subject, body);
                }
                trs.close(); tps.close();
            }
            rs.close(); ps.close();
        } catch (Exception e) {
            System.err.println("[ManagePaymentServlet] Email error: " + e.getMessage());
        }
    }
}
