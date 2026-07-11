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
import java.sql.ResultSet;

@WebServlet("/EditVehicleServlet")
public class EditVehicleServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        String email = (session != null) ? (String) session.getAttribute("customerEmail") : null;
        if (email == null) { response.sendRedirect("login.jsp"); return; }

        String action = request.getParameter("action");
        int vehicleId = Integer.parseInt(request.getParameter("vehicleId"));

        try (Connection conn = DBUtil.getConnection()) {
            // Verify ownership
            PreparedStatement vps = conn.prepareStatement(
                "SELECT v.id FROM vehicles v JOIN customers c ON v.customer_id=c.id JOIN users u ON c.user_id=u.id WHERE v.id=? AND u.email=?");
            vps.setInt(1, vehicleId);
            vps.setString(2, email);
            ResultSet vrs = vps.executeQuery();
            if (!vrs.next()) {
                vrs.close(); vps.close();
                response.sendRedirect("customer_dashboard.jsp?tab=vehicles&error=Unauthorized");
                return;
            }
            vrs.close(); vps.close();

            if ("edit".equals(action)) {
                String brand = request.getParameter("brand");
                String model = request.getParameter("model");
                String fuelType = request.getParameter("fuelType");
                String licensePlate = request.getParameter("licensePlate");
                String mileage = request.getParameter("mileage");
                String engineNumber = request.getParameter("engineNumber");
                String transmission = request.getParameter("transmission");
                String insurancePolicyNo = request.getParameter("insurancePolicyNo");
                String insuranceExpiry = request.getParameter("insuranceExpiry");
                String pucExpiry = request.getParameter("pucExpiry");
                String warrantyExpiry = request.getParameter("warrantyExpiry");

                PreparedStatement ups = conn.prepareStatement(
                    "UPDATE vehicles SET brand=?, model=?, fuel_type=?, license_plate=?, mileage=?, " +
                    "engine_number=?, transmission=?, insurance_policy_no=?, insurance_expiry=?, puc_expiry=?, warranty_expiry=? WHERE id=?");
                ups.setString(1, brand);
                ups.setString(2, model);
                ups.setString(3, fuelType);
                ups.setString(4, licensePlate);
                ups.setInt(5, Integer.parseInt(mileage));
                ups.setString(6, engineNumber);
                ups.setString(7, transmission);
                ups.setString(8, insurancePolicyNo);
                ups.setString(9, insuranceExpiry != null && !insuranceExpiry.isEmpty() ? insuranceExpiry : null);
                ups.setString(10, pucExpiry != null && !pucExpiry.isEmpty() ? pucExpiry : null);
                ups.setString(11, warrantyExpiry != null && !warrantyExpiry.isEmpty() ? warrantyExpiry : null);
                ups.setInt(12, vehicleId);
                ups.executeUpdate(); ups.close();
                response.sendRedirect("customer_dashboard.jsp?tab=vehicles&success=Vehicle+updated");

            } else if ("delete".equals(action)) {
                // Check if vehicle has active bookings
                PreparedStatement chk = conn.prepareStatement(
                    "SELECT COUNT(*) FROM bookings WHERE vehicle_id=? AND status NOT IN ('Completed','Delivered','Cancelled')");
                chk.setInt(1, vehicleId);
                ResultSet chr = chk.executeQuery();
                chr.next();
                if (chr.getInt(1) > 0) {
                    chr.close(); chk.close();
                    response.sendRedirect("customer_dashboard.jsp?tab=vehicles&error=Cannot+delete+vehicle+with+active+bookings");
                    return;
                }
                chr.close(); chk.close();

                PreparedStatement dps = conn.prepareStatement("UPDATE vehicles SET status='Archived' WHERE id=?");
                dps.setInt(1, vehicleId);
                dps.executeUpdate(); dps.close();
                response.sendRedirect("customer_dashboard.jsp?tab=vehicles&success=Vehicle+removed");

            } else {
                response.sendRedirect("customer_dashboard.jsp?tab=vehicles&error=Unknown+action");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("customer_dashboard.jsp?tab=vehicles&error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }
}
