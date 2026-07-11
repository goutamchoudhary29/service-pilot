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

@WebServlet("/ManageBookingServlet")
public class ManageBookingServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.sendRedirect("admin_login.jsp?error=Access+Denied");
            return;
        }

        String action = request.getParameter("action");
        int bookingId = Integer.parseInt(request.getParameter("bookingId"));

        try (Connection conn = DBUtil.getConnection()) {
            switch (action) {
                case "updateStatus":
                    String newStatus = request.getParameter("status");
                    PreparedStatement sps = conn.prepareStatement("UPDATE bookings SET status=? WHERE id=?");
                    sps.setString(1, newStatus);
                    sps.setInt(2, bookingId);
                    sps.executeUpdate();
                    sps.close();
                    sendStatusEmail(conn, bookingId, newStatus);
                    response.sendRedirect("admin_dashboard.jsp?tab=bookings&success=Status+updated+to+" + newStatus.replace(" ", "+"));
                    break;

                case "assignMechanic":
                    int mechId = Integer.parseInt(request.getParameter("mechanicId"));
                    PreparedStatement mps = conn.prepareStatement("UPDATE bookings SET mechanic_id=? WHERE id=?");
                    mps.setInt(1, mechId);
                    mps.setInt(2, bookingId);
                    mps.executeUpdate();
                    mps.close();
                    // Update mechanic's current_job_id
                    PreparedStatement mjps = conn.prepareStatement("UPDATE mechanics SET current_job_id=? WHERE id=?");
                    mjps.setInt(1, bookingId);
                    mjps.setInt(2, mechId);
                    mjps.executeUpdate(); mjps.close();
                    response.sendRedirect("admin_dashboard.jsp?tab=bookings&success=Mechanic+assigned");
                    break;

                case "changeDateTime":
                    String newDate = request.getParameter("bookingDate");
                    String newSlot = request.getParameter("timeSlot");
                    PreparedStatement dps = conn.prepareStatement("UPDATE bookings SET booking_date=?, time_slot=? WHERE id=?");
                    dps.setString(1, newDate);
                    dps.setString(2, newSlot);
                    dps.setInt(3, bookingId);
                    dps.executeUpdate();
                    dps.close();
                    response.sendRedirect("admin_dashboard.jsp?tab=bookings&success=Date+and+time+updated");
                    break;

                case "cancel":
                    PreparedStatement cps = conn.prepareStatement("UPDATE bookings SET status='Cancelled' WHERE id=?");
                    cps.setInt(1, bookingId);
                    cps.executeUpdate();
                    cps.close();
                    sendStatusEmail(conn, bookingId, "Cancelled");
                    response.sendRedirect("admin_dashboard.jsp?tab=bookings&success=Booking+cancelled");
                    break;

                case "delete":
                    // Delete cascading: job_images -> job_stages -> payments(via invoices) -> invoices -> booking
                    conn.prepareStatement("DELETE FROM job_images WHERE booking_id=" + bookingId).executeUpdate();
                    conn.prepareStatement("DELETE FROM job_stages WHERE booking_id=" + bookingId).executeUpdate();
                    conn.prepareStatement("DELETE p FROM payments p JOIN invoices i ON p.invoice_id=i.id WHERE i.booking_id=" + bookingId).executeUpdate();
                    conn.prepareStatement("DELETE FROM invoices WHERE booking_id=" + bookingId).executeUpdate();
                    conn.prepareStatement("DELETE FROM bookings WHERE id=" + bookingId).executeUpdate();
                    response.sendRedirect("admin_dashboard.jsp?tab=bookings&success=Booking+deleted");
                    break;

                default:
                    response.sendRedirect("admin_dashboard.jsp?tab=bookings&error=Unknown+action");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?tab=bookings&error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    private void sendStatusEmail(Connection conn, int bookingId, String newStatus) {
        try {
            String sql = "SELECT b.booking_uid, u.name AS cname, u.email AS cemail, " +
                "v.brand, v.model, v.license_plate, s.service_name, " +
                "COALESCE(mu.name,'Unassigned') AS mech_name, " +
                "COALESCE(p.payment_status,'Pending') AS pay_status " +
                "FROM bookings b " +
                "JOIN customers c ON b.customer_id=c.id " +
                "JOIN users u ON c.user_id=u.id " +
                "JOIN vehicles v ON b.vehicle_id=v.id " +
                "JOIN services s ON b.service_id=s.id " +
                "LEFT JOIN mechanics m ON b.mechanic_id=m.id " +
                "LEFT JOIN employees e ON m.employee_id=e.id " +
                "LEFT JOIN users mu ON e.user_id=mu.id " +
                "LEFT JOIN invoices inv ON inv.booking_id=b.id " +
                "LEFT JOIN payments p ON p.invoice_id=inv.id " +
                "WHERE b.id=?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setInt(1, bookingId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                // Load email template
                PreparedStatement tps = conn.prepareStatement("SELECT subject, body_html FROM email_templates WHERE template_key='status_updated'");
                ResultSet trs = tps.executeQuery();
                if (trs.next()) {
                    String subject = trs.getString("subject").replace("{{booking_uid}}", rs.getString("booking_uid"));
                    String body = trs.getString("body_html")
                        .replace("{{customer_name}}", rs.getString("cname"))
                        .replace("{{booking_uid}}", rs.getString("booking_uid"))
                        .replace("{{vehicle_brand}}", rs.getString("brand"))
                        .replace("{{vehicle_model}}", rs.getString("model"))
                        .replace("{{license_plate}}", rs.getString("license_plate"))
                        .replace("{{status}}", newStatus)
                        .replace("{{mechanic_name}}", rs.getString("mech_name"))
                        .replace("{{payment_status}}", rs.getString("pay_status"));
                    EmailUtil.sendEmailAsync(rs.getString("cemail"), subject, body);
                }
                trs.close(); tps.close();
            }
            rs.close(); ps.close();
        } catch (Exception e) {
            System.err.println("[ManageBookingServlet] Email dispatch error: " + e.getMessage());
        }
    }
}
