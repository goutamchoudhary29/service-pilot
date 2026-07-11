package com.vehicleservice.controller;



import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.util.UUID;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import com.vehicleservice.util.DBUtil;
@WebServlet("/EditServiceServlet")

@MultipartConfig(fileSizeThreshold = 2 * 1024 * 1024, 
                 maxFileSize = 10 * 1024 * 1024, 
                 maxRequestSize = 50 * 1024 * 1024)
public class EditServiceServlet extends HttpServlet {
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            int id = Integer.parseInt(request.getParameter("id"));
            String serviceName = request.getParameter("service_name");
            String description = request.getParameter("description");
            double price = Double.parseDouble(request.getParameter("price"));
            int time = Integer.parseInt(request.getParameter("time"));
            int quality = Integer.parseInt(request.getParameter("quality"));

            Part filePart = request.getPart("image");
            String fileName = filePart.getSubmittedFileName().isEmpty() ? "" : UUID.randomUUID().toString() + "_" + filePart.getSubmittedFileName();
            
            Connection conn = DBUtil.getConnection();

            String query = fileName.isEmpty() ?
                "UPDATE services SET service_name=?, description=?, price=?, time=?, quality=? WHERE id=?" :
                "UPDATE services SET service_name=?, description=?, price=?, time=?, quality=?, image_url=? WHERE id=?";

            PreparedStatement ps = conn.prepareStatement(query);
            ps.setString(1, serviceName);
            ps.setString(2, description);
            ps.setDouble(3, price);
            ps.setInt(4, time);
            ps.setInt(5, quality);
            if (!fileName.isEmpty()) {
                filePart.write("uploads/" + fileName);
                ps.setString(6, "uploads/" + fileName);
                ps.setInt(7, id);
            } else {
                ps.setInt(6, id);
            }

            ps.executeUpdate();
            conn.close();
            response.sendRedirect("admin_dashboard.jsp?msg=Service Updated Successfully");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?msg=Error Updating Service");
        }
    }
}


