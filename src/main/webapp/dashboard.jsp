<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.*, java.sql.*" %>
<%
    HttpSession sessionObj = request.getSession(false);
    if (sessionObj == null || sessionObj.getAttribute("user") == null) {
        response.sendRedirect("login.jsp");
    }

    String userEmail = (String) sessionObj.getAttribute("user");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>User Dashboard</title>
</head>
<body>
    <h2>Welcome, <%= userEmail %></h2>
    <a href="book_service.jsp">Book a Service</a> | <a href="LogoutServlet">Logout</a>

    <h3>Your Bookings</h3>
    <table border="1">
        <tr>
            <th>Vehicle Model</th>
            <th>Service Type</th>
            <th>Preferred Date</th>
            <th>Status</th>
        </tr>
        <%
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/vehicle_service", "root", "yourpassword");

                String query = "SELECT vehicle_model, service_type, preferred_date, status FROM service_bookings WHERE user_id=(SELECT id FROM users WHERE email=?)";
                PreparedStatement pstmt = conn.prepareStatement(query);
                pstmt.setString(1, userEmail);

                ResultSet rs = pstmt.executeQuery();
                while (rs.next()) {
        %>
        <tr>
            <td><%= rs.getString("vehicle_model") %></td>
            <td><%= rs.getString("service_type") %></td>
            <td><%= rs.getString("preferred_date") %></td>
            <td><%= rs.getString("status") %></td>
        </tr>
        <%
                }
                conn.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        %>
    </table>
</body>
</html>
