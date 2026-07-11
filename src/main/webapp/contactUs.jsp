<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact Us - ServicePilot</title>
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
                    <li class="nav-item"><a class="nav-link" href="service.jsp">Services</a></li>
                    <li class="nav-item"><a class="nav-link" href="aboutus.jsp">About Us</a></li>
                    <li class="nav-item"><a class="nav-link active" href="contactUs.jsp">Contact</a></li>
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

    <!-- Header Section -->
    <section class="py-5 text-white text-center" style="background: linear-gradient(135deg, #1e293b, #0ea5e9); padding: 80px 0;">
        <div class="container">
            <h1 class="display-4 fw-bold mb-3">Connect With Us</h1>
            <p class="lead max-width-600 mx-auto opacity-90">Have general questions? Get in touch with our team today.</p>
        </div>
    </section>

    <!-- Contact Form & Info -->
    <section class="py-5 bg-white">
        <div class="container py-4">
            <div class="row g-5">
                <!-- Info Column -->
                <div class="col-md-5">
                    <h3 class="fw-bold mb-4 text-dark">Get in Touch</h3>
                    <p class="text-muted mb-4">We are here to assist you with any service inquiries, feedback, or booking concerns. Feel free to contact us through any of the channels below.</p>
                    
                    <div class="d-flex mb-4">
                        <div class="text-primary fs-4 me-3"><i class="fas fa-map-marker-alt"></i></div>
                        <div>
                            <h5 class="fw-bold mb-1">Corporate HQ</h5>
                            <p class="text-muted mb-0">123 Service Street, Indore, MP 452001</p>
                        </div>
                    </div>
                    
                    <div class="d-flex mb-4">
                        <div class="text-primary fs-4 me-3"><i class="fas fa-phone"></i></div>
                        <div>
                            <h5 class="fw-bold mb-1">Phone Helpline</h5>
                            <p class="text-muted mb-0">+91 9876543210</p>
                        </div>
                    </div>
                    
                    <div class="d-flex">
                        <div class="text-primary fs-4 me-3"><i class="fas fa-envelope"></i></div>
                        <div>
                            <h5 class="fw-bold mb-1">Email Support</h5>
                            <p class="text-muted mb-0">support@servicepilot.com</p>
                        </div>
                    </div>
                </div>

                <!-- Form Column -->
                <div class="col-md-7">
                    <div class="p-4 bg-light rounded-4 border">
                        <h3 class="fw-bold mb-4 text-dark">Send Us a Message</h3>
                        <form action="${pageContext.request.contextPath}/ContactServlet" method="post">
                            <div class="mb-3">
                                <label for="name" class="form-label">Full Name</label>
                                <input type="text" class="form-control" id="name" name="name" placeholder="John Doe" required>
                            </div>
                            <div class="mb-3">
                                <label for="email" class="form-label">Email Address</label>
                                <input type="email" class="form-control" id="email" name="email" placeholder="john@example.com" required>
                            </div>
                            <div class="mb-3">
                                <label for="subject" class="form-label">Subject</label>
                                <input type="text" class="form-control" id="subject" name="subject" placeholder="What is this about?" required>
                            </div>
                            <div class="mb-3">
                                <label for="message" class="form-label">Message Content</label>
                                <textarea class="form-control" id="message" name="message" rows="4" placeholder="Type your message here..." required></textarea>
                            </div>
                            <button type="submit" class="btn btn-primary w-100 py-2 btn-auth mt-2">Send Message</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Map Section -->
    <section class="py-5" style="background-color: #f8fafc;">
        <div class="container">
            <h3 class="text-center fw-bold mb-4 text-dark">Our Headquarters</h3>
            <div class="rounded-4 overflow-hidden shadow-sm border">
                <iframe src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d117763.49479586715!2d75.78727095!3d22.7237527!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3962fcad1b410ddb%3A0x96ec4da356240f4!2sIndore%2C%20Madhya%20Pradesh!5e0!3m2!1sen!2sin!4v1698765432100!5m2!1sen!2sin" 
                        width="100%" height="380" style="border:0;" allowfullscreen="" loading="lazy"></iframe>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="bg-dark text-white text-center py-4">
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