<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="javax.servlet.http.*, java.sql.*" %>
<%
    HttpSession sessionObj = request.getSession(false);
    if (sessionObj == null || !"admin".equals(sessionObj.getAttribute("role"))) {
        response.sendRedirect("admin_login.jsp");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            padding: 20px;
            background-color: #f8f9fa;
        }
        h2, h3 {
            color: #2c3e50;
        }
        table {
            width: 100%;
            margin-bottom: 20px;
            border-collapse: collapse;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #18bc9c;
            color: white;
        }
        img {
            max-width: 100px;
            height: auto;
        }
        .btn {
            margin: 5px;
        }
    </style>
</head>
<body>
    <h2>Admin Dashboard</h2>
    <a href="LogoutServlet" class="btn btn-danger">Logout</a>

    <!-- Services Section -->
    <h3>All Services</h3>
    <table class="table table-bordered">
        <thead>
            <tr>
                <th>Image</th>
                <th>Service Name</th>
                <th>Description</th>
                <th>Price</th>
                <th>Actions</th>
            </tr>
        </thead>
        <tbody>
            <%
                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/servicepilot", "root", "9926");

                    String query = "SELECT * FROM services";
                    PreparedStatement pstmt = conn.prepareStatement(query);
                    ResultSet rs = pstmt.executeQuery();
                    while (rs.next()) {
            %>
            <tr>
                <td><img src="<%= rs.getString("image_url") %>" alt="Service Image"></td>
                <td><%= rs.getString("service_name") %></td>
                <td><%= rs.getString("description") %></td>
                <td>₹<%= rs.getString("price") %></td>
                <td>
                    <a href="DeleteServiceServlet?id=<%= rs.getInt("id") %>" class="btn btn-danger btn-sm">Delete</a>
                </td>
            </tr>
            <%
                    }
                    conn.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            %>
        </tbody>
    </table>

    <!-- Contact Messages Section -->
    <h3>Contact Messages</h3>
    <table class="table table-bordered">
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Subject</th>
                <th>Message</th>
                <th>Submission Date</th>
            </tr>
        </thead>
        <tbody>
            <%
                try {
                    Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/servicepilot", "root", "9926");

                    String query = "SELECT * FROM contact_messages";
                    PreparedStatement pstmt = conn.prepareStatement(query);
                    ResultSet rs = pstmt.executeQuery();
                    while (rs.next()) {
            %>
            <tr>
                <td><%= rs.getInt("id") %></td>
                <td><%= rs.getString("name") %></td>
                <td><%= rs.getString("email") %></td>
                <td><%= rs.getString("subject") %></td>
                <td><%= rs.getString("message") %></td>
                <td><%= rs.getTimestamp("submission_date") %></td>
            </tr>
            <%
                    }
                    conn.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            %>
        </tbody>
    </table>

    <!-- Booking Details Section -->
    <h3>Booking Details</h3>
    <table class="table table-bordered">
        <thead>
            <tr>
                <th>ID</th>
                <th>Vehicle Number</th>
                <th>Service Type</th>
                <th>Service Date</th>
                <th>Additional Notes</th>
                <th>Submission Date</th>
            </tr>
        </thead>
        <tbody>
            <%
                try {
                    Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/servicepilot", "root", "9926");

                    String query = "SELECT * FROM service_bookings";
                    PreparedStatement pstmt = conn.prepareStatement(query);
                    ResultSet rs = pstmt.executeQuery();
                    while (rs.next()) {
            %>
            <tr>
                <td><%= rs.getInt("id") %></td>
                <td><%= rs.getString("vehicle_number") %></td>
                <td><%= rs.getString("service_type") %></td>
                <td><%= rs.getString("service_date") %></td>
                <td><%= rs.getString("additional_notes") %></td>
                <td><%= rs.getTimestamp("submission_date") %></td>
            </tr>
            <%
                    }
                    conn.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            %>
        </tbody>
    </table>

    <!-- User Details Section -->
    <h3>User Details</h3>
    <table class="table table-bordered">
        <thead>
            <tr>
                <th>ID</th>
                <th>Username</th>
                <th>Email</th>
                <th>Role</th>
                <th>Registration Date</th>
            </tr>
        </thead>
        <tbody>
            <%
                try {
                    Connection conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/servicepilot", "root", "9926");

                    String query = "SELECT * FROM users";
                    PreparedStatement pstmt = conn.prepareStatement(query);
                    ResultSet rs = pstmt.executeQuery();
                    while (rs.next()) {
            %>
            <tr>
                <td><%= rs.getInt("id") %></td>
                <td><%= rs.getString("username") %></td>
                <td><%= rs.getString("email") %></td>
                <td><%= rs.getString("role") %></td>
                <td><%= rs.getTimestamp("registration_date") %></td>
            </tr>
            <%
                    }
                    conn.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            %>
        </tbody>
    </table>
</body>
</html>