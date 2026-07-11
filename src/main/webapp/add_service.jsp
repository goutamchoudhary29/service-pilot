<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    String csrfToken = (String) session.getAttribute("csrfToken");
    if (csrfToken == null) csrfToken = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Add New Service</title>
    <meta name="csrf-token" content="<%= csrfToken %>">
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <h2>Add New Service</h2>
    <form action="AddServiceServlet" method="post" enctype="multipart/form-data">
        <label>Service Name:</label>
        <input type="text" name="service_name" required><br>

        <label>Description:</label>
        <textarea name="description" required></textarea><br>

        <label>Price:</label>
        <input type="number" name="price" step="0.01" required><br>

        <label>Time Required (in minutes):</label>
        <input type="number" name="time" required><br>

        <label>Quality (1-5):</label>
        <select name="quality" required>
            <option value="1">1 - Poor</option>
            <option value="2">2 - Fair</option>
            <option value="3">3 - Good</option>
            <option value="4">4 - Very Good</option>
            <option value="5">5 - Excellent</option>
        </select><br>

        <label>Upload Image:</label>
        <input type="file" name="image" accept="image/*" required><br>

        <input type="submit" value="Add Service">
    </form>

    <h2>Existing Services</h2>
    <table border="1">
        <tr>
            <th>ID</th>
            <th>Service Name</th>
            <th>Description</th>
            <th>Price</th>
            <th>Time</th>
            <th>Quality</th>
            <th>Image</th>
        </tr>
        <%
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection con = DriverManager.getConnection("jdbc:mysql://localhost:3306/servicepilot", "root", "9926");
                Statement stmt = con.createStatement();
                ResultSet rs = stmt.executeQuery("SELECT id, service_name, description, price, time, quality, image_url FROM services");

                while (rs.next()) { 
        %>
        <tr>
            <td><%= rs.getInt("id") %></td>
            <td><%= rs.getString("service_name") %></td>
            <td><%= rs.getString("description") %></td>
            <td>₹<%= rs.getDouble("price") %></td>
            <td><%= rs.getInt("time") %> mins</td>
            <td><%= rs.getInt("quality") %>/5</td>
            <td><img src="<%= rs.getString("image_url") %>" width="100" height="100"></td>
        </tr>
        <%
                } 
                rs.close();
                stmt.close();
                con.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        %>
    </table>
    <script>
    (function() {
        var token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
        if (!token) return;
        document.querySelectorAll('form').forEach(function(form) {
            if ((form.method || '').toLowerCase() === 'post') {
                if (!form.querySelector('input[name="csrfToken"]')) {
                    var inp = document.createElement('input');
                    inp.type = 'hidden';
                    inp.name = 'csrfToken';
                    inp.value = token;
                    form.appendChild(inp);
                }
                var action = form.getAttribute('action') || '';
                if (action && action.indexOf('csrfToken=') === -1) {
                    var separator = action.indexOf('?') !== -1 ? '&' : '?';
                    form.setAttribute('action', action + separator + 'csrfToken=' + encodeURIComponent(token));
                }
            }
        });
    })();
    </script>
</body>
</html>
