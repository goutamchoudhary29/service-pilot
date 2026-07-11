package com.vehicleservice.controller;

import com.vehicleservice.util.DBUtil;
import com.vehicleservice.util.SecurityUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

@WebServlet("/UpdateJobStageServlet")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2, // 2MB
    maxFileSize = 1024 * 1024 * 10,      // 10MB
    maxRequestSize = 1024 * 1024 * 50     // 50MB
)
public class UpdateJobStageServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("mechanicId") == null) {
            response.sendRedirect("admin_login.jsp?error=Access%20Denied.");
            return;
        }

        // Validate CSRF token
        if (!SecurityUtil.validateCSRFToken(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "CSRF Validation Failed");
            return;
        }

        int mechanicId = (Integer) session.getAttribute("mechanicId");
        String bookingIdStr = request.getParameter("bookingId");
        String stageName = request.getParameter("stageName");
        String description = request.getParameter("description");
        Part filePart = request.getPart("imageFile"); // Multipart file upload

        if (bookingIdStr == null || stageName == null || bookingIdStr.trim().isEmpty() || stageName.trim().isEmpty()) {
            response.sendRedirect("mechanic_dashboard.jsp?error=Invalid%20Parameters.");
            return;
        }

        Connection conn = null;
        try {
            int bookingId = Integer.parseInt(bookingIdStr);
            conn = DBUtil.getConnection();
            conn.setAutoCommit(false); // Begin Transaction

            // 1. Determine booking status based on the selected job stage
            String bookingStatus = "In Progress";
            if ("Ready for Delivery".equals(stageName)) {
                bookingStatus = "Completed";
            }

            // Update booking status
            String updateBookingQuery = "UPDATE bookings SET status = ? WHERE id = ? AND mechanic_id = ?";
            PreparedStatement updateBookingPs = conn.prepareStatement(updateBookingQuery);
            updateBookingPs.setString(1, bookingStatus);
            updateBookingPs.setInt(2, bookingId);
            updateBookingPs.setInt(3, mechanicId);
            updateBookingPs.executeUpdate();
            updateBookingPs.close();

            // 2. Insert into job_stages log
            String insertStageQuery = "INSERT INTO job_stages (booking_id, mechanic_id, stage_name, description) VALUES (?, ?, ?, ?)";
            PreparedStatement insertStagePs = conn.prepareStatement(insertStageQuery, Statement.RETURN_GENERATED_KEYS);
            insertStagePs.setInt(1, bookingId);
            insertStagePs.setInt(2, mechanicId);
            insertStagePs.setString(3, stageName);
            insertStagePs.setString(4, description != null ? description : "");
            insertStagePs.executeUpdate();

            int stageId = -1;
            ResultSet generatedKeys = insertStagePs.getGeneratedKeys();
            if (generatedKeys.next()) {
                stageId = generatedKeys.getInt(1);
            }
            generatedKeys.close();
            insertStagePs.close();

            // 3. Process photo upload if provided
            if (filePart != null && filePart.getSize() > 0 && stageId != -1) {
                String submittedFileName = getFileName(filePart);
                if (submittedFileName != null && !submittedFileName.isEmpty()) {
                    // Set up local folder on Tomcat
                    String appPath = request.getServletContext().getRealPath("");
                    String uploadPath = appPath + File.separator + "images" + File.separator + "jobs";
                    File uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        uploadDir.mkdirs();
                    }

                    String uniqueName = System.currentTimeMillis() + "_" + submittedFileName;
                    filePart.write(uploadPath + File.separator + uniqueName);
                    
                    // Determine image type (BEFORE for check/repair start, AFTER for QC/ready)
                    String type = "BEFORE";
                    if ("Repair Completed".equals(stageName) || "Quality Check".equals(stageName) || "Ready for Delivery".equals(stageName)) {
                        type = "AFTER";
                    }

                    // Save log inside job_images table
                    String insertImageQuery = "INSERT INTO job_images (job_stage_id, image_url, type) VALUES (?, ?, ?)";
                    PreparedStatement insertImagePs = conn.prepareStatement(insertImageQuery);
                    insertImagePs.setInt(1, stageId);
                    insertImagePs.setString(2, "images/jobs/" + uniqueName);
                    insertImagePs.setString(3, type);
                    insertImagePs.executeUpdate();
                    insertImagePs.close();
                }
            }

            conn.commit(); // Commit Transaction
            response.sendRedirect("mechanic_dashboard.jsp?success=Job%20stage%20and%20media%20updated%20successfully!");
        } catch (Exception e) {
            e.printStackTrace();
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignore) {}
            }
            response.sendRedirect("mechanic_dashboard.jsp?error=Failed%20to%20update%20job%20stage.");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }

    private String getFileName(Part part) {
        String contentDisp = part.getHeader("content-disposition");
        String[] tokens = contentDisp.split(";");
        for (String token : tokens) {
            if (token.trim().startsWith("filename")) {
                return token.substring(token.indexOf("=") + 2, token.length() - 1);
            }
        }
        return "";
    }
}
