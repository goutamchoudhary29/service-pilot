package com.vehicleservice.controller;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;

@WebServlet("/DatabaseBackupServlet")
public class DatabaseBackupServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        // Authorize admin or super admin roles only (role 1 or 2)
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.sendRedirect("admin_login.jsp?error=Access%20Denied.");
            return;
        }

        int roleId = (Integer) session.getAttribute("adminRoleId");
        if (roleId != 1 && roleId != 2) {
            response.sendRedirect("admin_dashboard.jsp?error=Access%20Denied.%20Requires%20Admin%20privileges.");
            return;
        }

        // Execute mysqldump command
        String executeCmd = "mysqldump -u root -p9926 servicepilot";
        Process runtimeProcess;
        try {
            runtimeProcess = Runtime.getRuntime().exec(executeCmd);
            
            response.setContentType("application/octet-stream");
            response.setHeader("Content-Disposition", "attachment; filename=servicepilot_backup_" + System.currentTimeMillis() + ".sql");
            
            try (InputStream is = runtimeProcess.getInputStream();
                 OutputStream os = response.getOutputStream()) {
                byte[] buffer = new byte[4096];
                int bytesRead;
                while ((bytesRead = is.read(buffer)) != -1) {
                    os.write(buffer, 0, bytesRead);
                }
            }
            
            int processComplete = runtimeProcess.waitFor();
            if (processComplete != 0) {
                System.err.println("[DatabaseBackupServlet] Warning: mysqldump exited with status " + processComplete);
            }
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?error=Database%20backup%20failed.");
        }
    }
}
