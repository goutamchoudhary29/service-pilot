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

@WebServlet("/ManageReviewServlet")
public class ManageReviewServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.sendRedirect("admin_login.jsp?error=Access+Denied");
            return;
        }

        String action = request.getParameter("action");
        int reviewId = Integer.parseInt(request.getParameter("reviewId"));

        try (Connection conn = DBUtil.getConnection()) {
            switch (action) {
                case "approve":
                    updateStatus(conn, reviewId, "Approved");
                    response.sendRedirect("admin_dashboard.jsp?tab=reviews&success=Review+approved");
                    break;
                case "reject":
                    updateStatus(conn, reviewId, "Rejected");
                    response.sendRedirect("admin_dashboard.jsp?tab=reviews&success=Review+rejected");
                    break;
                case "reply":
                    String reply = request.getParameter("adminReply");
                    PreparedStatement rps = conn.prepareStatement("UPDATE reviews SET admin_reply=?, status='Approved' WHERE id=?");
                    rps.setString(1, reply);
                    rps.setInt(2, reviewId);
                    rps.executeUpdate(); rps.close();
                    response.sendRedirect("admin_dashboard.jsp?tab=reviews&success=Reply+posted");
                    break;
                case "delete":
                    conn.prepareStatement("DELETE FROM reviews WHERE id=" + reviewId).executeUpdate();
                    response.sendRedirect("admin_dashboard.jsp?tab=reviews&success=Review+deleted");
                    break;
                default:
                    response.sendRedirect("admin_dashboard.jsp?tab=reviews&error=Unknown+action");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?tab=reviews&error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    private void updateStatus(Connection conn, int reviewId, String status) throws Exception {
        PreparedStatement ps = conn.prepareStatement("UPDATE reviews SET status=? WHERE id=?");
        ps.setString(1, status);
        ps.setInt(2, reviewId);
        ps.executeUpdate(); ps.close();
    }
}
