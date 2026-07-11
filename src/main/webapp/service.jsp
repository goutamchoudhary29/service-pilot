<%@ page import="com.vehicleservice.util.DBUtil, java.sql.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    String loggedEmail = (String) session.getAttribute("customerEmail");
    boolean isCustomerLoggedIn = (loggedEmail != null);
    String csrfToken = (String) session.getAttribute("csrfToken");
    if (csrfToken == null) csrfToken = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Our Services - ServicePilot</title>
    <meta name="csrf-token" content="<%= csrfToken %>">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css" rel="stylesheet">
    <link href="css/styles.css" rel="stylesheet">
</head>
<body> 

    <!-- Navigation Bar -->
    <nav class="navbar navbar-expand-lg navbar-dark bg-dark shadow-lg">
        <div class="container">
            <a class="navbar-brand fw-bold" href="index.jsp">ServicePilot</a>
            <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto align-items-center">
                    <li class="nav-item"><a class="nav-link" href="index.jsp">Home</a></li>
                    <li class="nav-item"><a class="nav-link active" href="service.jsp">Services</a></li>
                    <li class="nav-item"><a class="nav-link" href="aboutus.jsp">About Us</a></li>
                    <li class="nav-item"><a class="nav-link" href="contactUs.jsp">Contact</a></li>
                    <% if (isCustomerLoggedIn) { %>
                        <li class="nav-item"><a class="nav-link btn btn-primary text-white mx-2" href="customer_dashboard.jsp">Dashboard</a></li>
                    <% } else { %>
                        <li class="nav-item"><a class="nav-link btn btn-primary text-white mx-2" href="login.jsp">Login</a></li>
                    <% } %>
                    <li class="nav-item"><a class="nav-link btn btn-success text-white" href="admin_login.jsp">Admin</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="container my-5">
        <h2 class="text-center fw-bold mb-2">Our Repair Catalog</h2>
        <p class="text-center text-muted mb-5">Select a service below and book your slot in a few easy clicks.</p>
        
        <div class="row g-4">
            <% 
                Connection con = null;
                PreparedStatement pstmt = null;
                ResultSet rs = null;
                try {
                    con = DBUtil.getConnection();
                    String query = "SELECT id, service_name, description, price, time_required, quality, image_url FROM services";
                    pstmt = con.prepareStatement(query);
                    rs = pstmt.executeQuery();
                    boolean hasServices = false;
                    while (rs.next()) { 
                        hasServices = true;
            %>
            <div class="col-md-4">
                <div class="card service-card h-100 shadow-sm">
                    <img src="<%= request.getContextPath() + "/" + (rs.getString("image_url") != null ? rs.getString("image_url") : "default.jpg") %>" 
                         class="card-img-top" 
                         alt="<%= rs.getString("service_name") %>">
                    <div class="card-body d-flex flex-column">
                        <h5 class="card-title fw-bold text-dark"><%= rs.getString("service_name") %></h5>
                        <p class="card-text text-muted flex-grow-1"><%= rs.getString("description") %></p>
                        
                        <div class="border-top pt-3 mt-3">
                            <div class="d-flex justify-content-between mb-2">
                                <span class="text-muted"><i class="far fa-clock me-1"></i> Time:</span>
                                <span class="fw-semibold"><%= rs.getString("time_required") %> hours</span>
                            </div>
                            <div class="d-flex justify-content-between mb-2">
                                <span class="text-muted"><i class="fas fa-shield-alt me-1"></i> Quality:</span>
                                <span class="fw-semibold"><%= rs.getString("quality") %></span>
                            </div>
                            <div class="d-flex justify-content-between align-items-center mb-3">
                                <span class="text-muted"><i class="fas fa-tag me-1"></i> Est. Cost:</span>
                                <span class="fs-5 fw-bold text-success">₹<%= rs.getDouble("price") %></span>
                            </div>
                        </div>

                        <!-- Book Now Button -->
                        <form action="bookservice.jsp" method="post" style="margin: 0;">
                            <input type="hidden" name="service_id" value="<%= rs.getInt("id") %>">
                            <button type="submit" class="btn btn-primary w-100 btn-auth py-2">Book This Service</button>
                        </form>
                    </div>
                </div>
            </div>
            <% } 
               if (!hasServices) { %>
                <div class="col-12 text-center py-5">
                    <p class="alert alert-warning">No services available currently. Please check back later.</p>
                </div>
            <% } 
            } catch (Exception e) { 
                e.printStackTrace();
            %>
                <div class="col-12 text-center py-5">
                    <div class="alert alert-danger">Error loading services. Please try again later.</div>
                </div>
            <%
                } finally {
                    if (rs != null) rs.close();
                    if (pstmt != null) pstmt.close();
                    if (con != null) con.close();
                }
            %>
        </div>
    </div>

    <!-- Footer -->
    <footer class="bg-dark text-white text-center py-4 mt-5">
        <p class="mb-0 opacity-50">&copy; 2025 ServicePilot. All Rights Reserved.</p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
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
