package com.vehicleservice.controller;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.util.UUID;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import com.vehicleservice.util.DBUtil;

@MultipartConfig(fileSizeThreshold = 1024 * 1024 * 2, // 2MB
                 maxFileSize = 1024 * 1024 * 10,      // 10MB
                 maxRequestSize = 1024 * 1024 * 50)   // 50MB
public class AddServiceServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();

        try {
            // Form Data
            String serviceName = request.getParameter("service_name");
            String description = request.getParameter("description");
            double price = Double.parseDouble(request.getParameter("price"));
            int time = Integer.parseInt(request.getParameter("time"));
            int quality = Integer.parseInt(request.getParameter("quality"));

            // Image Upload
            Part filePart = request.getPart("image");
            String fileName = UUID.randomUUID().toString() + "_" + filePart.getSubmittedFileName();
            String uploadPath = getServletContext().getRealPath("") + File.separator + "uploads";

            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) uploadDir.mkdir();

            filePart.write(uploadPath + File.separator + fileName);
            String imageUrl = "uploads/" + fileName;

            // Database Connection
            Connection conn = DBUtil.getConnection();

            String query = "INSERT INTO services (service_name, description, price, time, quality, image_url) VALUES (?, ?, ?, ?, ?, ?)";
            PreparedStatement pstmt = conn.prepareStatement(query);
            pstmt.setString(1, serviceName);
            pstmt.setString(2, description);
            pstmt.setDouble(3, price);
            pstmt.setInt(4, time);
            pstmt.setInt(5, quality);
            pstmt.setString(6, imageUrl);
            pstmt.executeUpdate();

            conn.close();
            response.sendRedirect("admin_dashboard.jsp?msg=Service Added Successfully");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?msg=Error Adding Service");
        }
    }
}
