<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    String customerEmail = (String) session.getAttribute("customer_email");

    if (customerEmail == null) {
        response.sendRedirect("login.jsp"); // लॉगिन पेज पर भेजें
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Service Bookings</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-5">
        <h2 class="text-center mb-4">My Service Bookings</h2>
        <table class="table table-bordered table-striped">
            <thead class="table-dark">
                <tr>
                    <th>ID</th>
                    <th>Vehicle</th>
                    <th>Service Type</th>
                    <th>Service Date</th>
                    <th>Amount Due</th>
                    <th>Payment Status</th>
                    <th>Service Status</th>
                </tr>
            </thead>
            <tbody>
                <%
                    Connection conn = null;
                    PreparedStatement pstmt = null;
                    ResultSet rs = null;
                    try {
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/servicepilot", "root", "9926");

                        // केवल लॉगिन किए गए कस्टमर के लिए बुकिंग डेटा लाना
                        String query = "SELECT * FROM service_bookings WHERE customer_email = ? ORDER BY service_date DESC";
                        pstmt = conn.prepareStatement(query);
                        pstmt.setString(1, customerEmail);
                        rs = pstmt.executeQuery();

                        while (rs.next()) {
                %>
                <tr>
                    <td><%= rs.getInt("id") %></td>
                    <td><strong><%= rs.getString("vehicle_name") %></strong> (<%= rs.getString("vehicle_number") %>)</td>
                    <td><%= rs.getString("service_type") %></td>
                    <td><%= rs.getString("service_date") %></td>
                    <td>₹<%= rs.getDouble("amount_due") %></td>
                    <td><%= rs.getString("payment_status") %></td>
                    <td><%= rs.getString("service_status") %></td>
                </tr>
                <%
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    } finally {
                        if (rs != null) rs.close();
                        if (pstmt != null) pstmt.close();
                        if (conn != null) conn.close();
                    }
                %>
            </tbody>
        </table>
        <a href="logout.jsp" class="btn btn-danger">Logout</a>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
