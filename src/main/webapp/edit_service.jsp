<%@ page import="java.sql.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ page pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Edit Service</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>

<% 
    String id = request.getParameter("id");
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection("jdbc:mysql://localhost:3306/servicepilot", "root", "9926");
        String query = "SELECT * FROM services WHERE id=?";
        ps = con.prepareStatement(query);
        ps.setString(1, id);
        rs = ps.executeQuery();

        if (rs.next()) { 
%>

<div class="container my-5">
    <h2 class="text-center">Edit Service</h2>
    <form action="EditServiceServlet" method="post" enctype="multipart/form-data">
        <input type="hidden" name="id" value="<%= rs.getInt("id") %>">

        <label>Service Name:</label>
        <input type="text" name="service_name" value="<%= rs.getString("service_name") %>" class="form-control" required><br>

        <label>Description:</label>
        <textarea name="description" class="form-control" required><%= rs.getString("description") %></textarea><br>

        <label>Price:</label>
        <input type="number" name="price" value="<%= rs.getDouble("price") %>" class="form-control" required><br>

        <label>Time (mins):</label>
        <input type="number" name="time" value="<%= rs.getInt("time") %>" class="form-control" required><br>

        <label>Quality:</label>
        <input type="number" name="quality" value="<%= rs.getInt("quality") %>" class="form-control" required><br>

        <label>Current Image:</label><br>
        <img src="<%= rs.getString("image_url") %>" width="100"><br><br>

        <label>Upload New Image:</label>
        <input type="file" name="image" class="form-control"><br>

        <input type="submit" value="Update Service" class="btn btn-primary">
    </form>
</div>

<% 
        } else {
            out.println("<h3 class='text-danger text-center'>Service Not Found!</h3>");
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) rs.close();
        if (ps != null) ps.close();
        if (con != null) con.close();
    }
%>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
