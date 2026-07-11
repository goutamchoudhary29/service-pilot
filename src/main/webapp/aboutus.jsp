<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String loggedEmail = (String) session.getAttribute("customerEmail");
    boolean isCustomerLoggedIn = (loggedEmail != null);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>About Us - ServicePilot</title>
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
                    <li class="nav-item"><a class="nav-link" href="service.jsp">Services</a></li>
                    <li class="nav-item"><a class="nav-link active" href="aboutus.jsp">About Us</a></li>
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

    <!-- About Us Intro -->
    <section class="py-5 text-white text-center" style="background: linear-gradient(135deg, #1e293b, #4f46e5); padding: 80px 0;">
        <div class="container">
            <h1 class="display-4 fw-bold mb-3">About ServicePilot</h1>
            <p class="lead max-width-600 mx-auto opacity-90">A reliable, secure, and multi-location vehicle service management system built to provide an exceptional care experience.</p>
        </div>
    </section>

    <!-- Details Section -->
    <section class="py-5 bg-white">
        <div class="container py-4">
            <div class="row g-5 align-items-center">
                <div class="col-md-6">
                    <h2 class="fw-bold mb-4 text-dark">Simplifying Vehicle Care</h2>
                    <p class="text-muted">At ServicePilot, we specialize in bridging the gap between vehicle owners and professional garages. Maintaining your vehicle shouldn't be a tedious chore. Our platform enables customers to book appointments, manage multiple garage center locations, and track due amounts seamlessly in real-time.</p>
                    <p class="text-muted">Whether it is an routine oil change, tire balancing, or complex engine diagnostics, our partner garages utilize state-of-the-art tools and certified mechanics to ensure your vehicle leaves in pristine condition.</p>
                </div>
                <div class="col-md-6">
                    <div class="p-4 bg-light rounded-4 border">
                        <h4 class="fw-bold text-primary mb-3"><i class="fas fa-bullseye me-2"></i>Our Mission</h4>
                        <p class="text-muted mb-0">Our mission is to establish a transparent, robust, and highly convenient automotive service ecosystem. We strive to provide a user-friendly platform that helps drivers minimize downtime, extend the life of their vehicles, and service them at reputable facilities near their location.</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Unique Features -->
    <section class="py-5" style="background-color: #f8fafc;">
        <div class="container py-4">
            <h2 class="text-center fw-bold mb-5 text-dark">Core Service Pillars</h2>
            
            <div class="row g-4">
                <div class="col-md-4 text-center">
                    <div class="p-4 bg-white rounded-3 shadow-sm border h-100">
                        <div class="text-primary fs-2 mb-3"><i class="fas fa-lock"></i></div>
                        <h5 class="fw-bold">Hashed Security</h5>
                        <p class="text-muted small">Industrial-grade SHA-256 secure authentication shields customer profiles and booking histories from leaks.</p>
                    </div>
                </div>
                <div class="col-md-4 text-center">
                    <div class="p-4 bg-white rounded-3 shadow-sm border h-100">
                        <div class="text-success fs-2 mb-3"><i class="fas fa-map-marked-alt"></i></div>
                        <h5 class="fw-bold">Multi-Garage Routing</h5>
                        <p class="text-muted small">Easily switch between different workshop locations to book slot timings closest to your current place.</p>
                    </div>
                </div>
                <div class="col-md-4 text-center">
                    <div class="p-4 bg-white rounded-3 shadow-sm border h-100">
                        <div class="text-warning fs-2 mb-3"><i class="fas fa-wallet"></i></div>
                        <h5 class="fw-bold">Cost Transparency</h5>
                        <p class="text-muted small">Clear invoicing, estimate price breakdowns, and live payment status tracking inside your dashboard panel.</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="bg-dark text-white text-center py-4">
        <p class="mb-0 opacity-50">&copy; 2025 ServicePilot. All Rights Reserved.</p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>