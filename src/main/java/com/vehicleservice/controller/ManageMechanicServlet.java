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
import java.sql.ResultSet;

@WebServlet("/ManageMechanicServlet")
public class ManageMechanicServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.sendRedirect("admin_login.jsp?error=Access+Denied");
            return;
        }

        String action = request.getParameter("action");
        try (Connection conn = DBUtil.getConnection()) {
            switch (action) {
                case "add":
                    addMechanic(conn, request);
                    response.sendRedirect("admin_dashboard.jsp?tab=mechanics&success=Mechanic+added+successfully");
                    break;
                case "edit":
                    editMechanic(conn, request);
                    response.sendRedirect("admin_dashboard.jsp?tab=mechanics&success=Mechanic+updated");
                    break;
                case "activate":
                    toggleStatus(conn, request, "Active");
                    response.sendRedirect("admin_dashboard.jsp?tab=mechanics&success=Mechanic+activated");
                    break;
                case "deactivate":
                    toggleStatus(conn, request, "Suspended");
                    response.sendRedirect("admin_dashboard.jsp?tab=mechanics&success=Mechanic+deactivated");
                    break;
                case "delete":
                    deleteMechanic(conn, request);
                    response.sendRedirect("admin_dashboard.jsp?tab=mechanics&success=Mechanic+deleted");
                    break;
                default:
                    response.sendRedirect("admin_dashboard.jsp?tab=mechanics&error=Unknown+action");
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?tab=mechanics&error=" + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
        }
    }

    private void addMechanic(Connection conn, HttpServletRequest req) throws Exception {
        String name = req.getParameter("name");
        String email = req.getParameter("email");
        String phone = req.getParameter("phone");
        String specialization = req.getParameter("specialization");
        String branchIdStr = req.getParameter("branchId");
        String salary = req.getParameter("salary");

        int branchId = Integer.parseInt(branchIdStr);
        String hash = SecurityUtil.hashPassword("mechanic123");

        // 1. Insert into users (role_id=3 for mechanic)
        PreparedStatement ups = conn.prepareStatement(
            "INSERT INTO users (name, email, phone, password_hash, role_id, status) VALUES (?,?,?,?,3,'Active')",
            PreparedStatement.RETURN_GENERATED_KEYS);
        ups.setString(1, name);
        ups.setString(2, email);
        ups.setString(3, phone);
        ups.setString(4, hash);
        ups.executeUpdate();
        ResultSet keys = ups.getGeneratedKeys();
        keys.next();
        int userId = keys.getInt(1);
        keys.close(); ups.close();

        // 2. Insert into employees
        PreparedStatement eps = conn.prepareStatement(
            "INSERT INTO employees (user_id, branch_id, title, salary, status) VALUES (?,?,?,?,'Active')",
            PreparedStatement.RETURN_GENERATED_KEYS);
        eps.setInt(1, userId);
        eps.setInt(2, branchId);
        eps.setString(3, "Mechanic");
        eps.setDouble(4, Double.parseDouble(salary));
        eps.executeUpdate();
        ResultSet ek = eps.getGeneratedKeys();
        ek.next();
        int empId = ek.getInt(1);
        ek.close(); eps.close();

        // 3. Insert into mechanics
        PreparedStatement mps = conn.prepareStatement(
            "INSERT INTO mechanics (employee_id, specialization, rating) VALUES (?,?,5.00)");
        mps.setInt(1, empId);
        mps.setString(2, specialization);
        mps.executeUpdate();
        mps.close();
    }

    private void editMechanic(Connection conn, HttpServletRequest req) throws Exception {
        int empId = Integer.parseInt(req.getParameter("employeeId"));
        String name = req.getParameter("name");
        String phone = req.getParameter("phone");
        String specialization = req.getParameter("specialization");
        String salary = req.getParameter("salary");

        // Get user_id from employee
        PreparedStatement gps = conn.prepareStatement("SELECT user_id FROM employees WHERE id=?");
        gps.setInt(1, empId);
        ResultSet grs = gps.executeQuery();
        if (!grs.next()) throw new Exception("Employee not found");
        int userId = grs.getInt("user_id");
        grs.close(); gps.close();

        PreparedStatement ups = conn.prepareStatement("UPDATE users SET name=?, phone=? WHERE id=?");
        ups.setString(1, name);
        ups.setString(2, phone);
        ups.setInt(3, userId);
        ups.executeUpdate(); ups.close();

        PreparedStatement eps = conn.prepareStatement("UPDATE employees SET salary=? WHERE id=?");
        eps.setDouble(1, Double.parseDouble(salary));
        eps.setInt(2, empId);
        eps.executeUpdate(); eps.close();

        PreparedStatement mps = conn.prepareStatement("UPDATE mechanics SET specialization=? WHERE employee_id=?");
        mps.setString(1, specialization);
        mps.setInt(2, empId);
        mps.executeUpdate(); mps.close();
    }

    private void toggleStatus(Connection conn, HttpServletRequest req, String status) throws Exception {
        int empId = Integer.parseInt(req.getParameter("employeeId"));
        PreparedStatement gps = conn.prepareStatement("SELECT user_id FROM employees WHERE id=?");
        gps.setInt(1, empId);
        ResultSet grs = gps.executeQuery();
        if (!grs.next()) throw new Exception("Employee not found");
        int userId = grs.getInt("user_id");
        grs.close(); gps.close();

        PreparedStatement ups = conn.prepareStatement("UPDATE users SET status=? WHERE id=?");
        ups.setString(1, status);
        ups.setInt(2, userId);
        ups.executeUpdate(); ups.close();

        String empStatus = status.equals("Active") ? "Active" : "Suspended";
        PreparedStatement eps = conn.prepareStatement("UPDATE employees SET status=? WHERE id=?");
        eps.setString(1, empStatus);
        eps.setInt(2, empId);
        eps.executeUpdate(); eps.close();
    }

    private void deleteMechanic(Connection conn, HttpServletRequest req) throws Exception {
        int empId = Integer.parseInt(req.getParameter("employeeId"));
        PreparedStatement gps = conn.prepareStatement("SELECT user_id FROM employees WHERE id=?");
        gps.setInt(1, empId);
        ResultSet grs = gps.executeQuery();
        if (!grs.next()) throw new Exception("Employee not found");
        int userId = grs.getInt("user_id");
        grs.close(); gps.close();

        conn.prepareStatement("UPDATE bookings SET mechanic_id=NULL WHERE mechanic_id=(SELECT id FROM mechanics WHERE employee_id=" + empId + ")").executeUpdate();
        conn.prepareStatement("DELETE FROM mechanics WHERE employee_id=" + empId).executeUpdate();
        conn.prepareStatement("DELETE FROM employees WHERE id=" + empId).executeUpdate();
        conn.prepareStatement("DELETE FROM users WHERE id=" + userId).executeUpdate();
    }
}
