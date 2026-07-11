<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String loggedEmail = (String) session.getAttribute("customerEmail");
    boolean isCustomerLoggedIn = (loggedEmail != null);
    String successMsg = request.getParameter("success");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="ServicePilot — Premium enterprise-grade vehicle service management. Book slots, track repairs, and manage your fleet effortlessly.">
    <title>ServicePilot — Premium Vehicle Service Management</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="css/styles.css" rel="stylesheet">
</head>
<body>
    <!-- Navigation Bar -->
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="fas fa-cogs me-2" style="font-size:1.2rem;"></i>ServicePilot
            </a>
            <button class="navbar-toggler border-0" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto align-items-center gap-1">
                    <li class="nav-item"><a class="nav-link active" href="#">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="service.jsp">Services</a></li>
                    <li class="nav-item"><a class="nav-link" href="aboutus.jsp">About</a></li>
                    <li class="nav-item"><a class="nav-link" href="contactUs.jsp">Contact</a></li>
                    <% if (isCustomerLoggedIn) { %>
                        <li class="nav-item ms-2"><a class="nav-link btn btn-primary text-white px-3" href="customer_dashboard.jsp"><i class="fas fa-tachometer-alt me-1"></i>Dashboard</a></li>
                    <% } else { %>
                        <li class="nav-item ms-2"><a class="nav-link btn btn-primary text-white px-3" href="login.jsp"><i class="fas fa-sign-in-alt me-1"></i>Login</a></li>
                    <% } %>
                    <li class="nav-item"><a class="nav-link btn btn-outline-primary text-white ms-1 px-3" href="admin_login.jsp"><i class="fas fa-shield-alt me-1"></i>Admin</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <!-- Success Toast -->
    <% if (successMsg != null) { %>
    <div class="container mt-3" style="position:relative; z-index:2;">
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="fas fa-check-circle me-2"></i><%= successMsg %>
            <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
    </div>
    <% } %>

    <!-- Hero Section -->
    <header class="hero">
        <div class="container text-center">
            <div style="position:relative;z-index:1;">
                <span class="badge bg-primary bg-opacity-25 text-white mb-3 px-3 py-2" style="font-size:0.8rem; border-radius:20px; border:1px solid rgba(99,102,241,0.3);">
                    <i class="fas fa-bolt me-1"></i> Trusted by 500+ vehicle owners
                </span>
                <h1 class="display-4 fw-bold">
                    Drive Smart with<br>
                    <span class="text-gradient">ServicePilot</span>
                </h1>
                <p class="lead">Enterprise-grade vehicle service management. Book slots, track live repairs, download invoices — all from one platform.</p>
                <div class="d-flex gap-3 justify-content-center flex-wrap">
                    <a href="service.jsp" class="btn btn-lg px-5 py-3 btn-auth">
                        <i class="fas fa-calendar-alt me-2"></i>Book Service Now
                    </a>
                    <a href="aboutus.jsp" class="btn btn-lg btn-outline-primary px-4 py-3">
                        <i class="fas fa-play-circle me-2"></i>Learn More
                    </a>
                </div>
            </div>
        </div>
    </header>

    <!-- Live Stats Counter -->
    <section class="py-4" style="position:relative; z-index:1; margin-top:-60px;">
        <div class="container">
            <div class="row g-3 justify-content-center">
                <div class="col-6 col-md-3">
                    <div class="dashboard-card text-center py-4">
                        <div class="fs-2 mb-2" style="color:var(--primary-light);"><i class="fas fa-car-side"></i></div>
                        <h3 class="fw-bold mb-0" style="color:var(--text-white);" data-count="1250">0</h3>
                        <p class="text-muted small mb-0">Vehicles Serviced</p>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="dashboard-card text-center py-4">
                        <div class="fs-2 mb-2" style="color:var(--secondary);"><i class="fas fa-user-tie"></i></div>
                        <h3 class="fw-bold mb-0" style="color:var(--text-white);" data-count="48">0</h3>
                        <p class="text-muted small mb-0">Expert Mechanics</p>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="dashboard-card text-center py-4">
                        <div class="fs-2 mb-2" style="color:var(--success);"><i class="fas fa-map-marker-alt"></i></div>
                        <h3 class="fw-bold mb-0" style="color:var(--text-white);" data-count="12">0</h3>
                        <p class="text-muted small mb-0">Service Locations</p>
                    </div>
                </div>
                <div class="col-6 col-md-3">
                    <div class="dashboard-card text-center py-4">
                        <div class="fs-2 mb-2" style="color:var(--accent);"><i class="fas fa-star"></i></div>
                        <h3 class="fw-bold mb-0" style="color:var(--text-white);" data-count="4.9">0</h3>
                        <p class="text-muted small mb-0">Customer Rating</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Featured Services -->
    <section class="py-5" style="position:relative; z-index:1;">
        <div class="container text-center py-4">
            <span class="badge bg-primary bg-opacity-25 text-white mb-3 px-3 py-2" style="font-size:0.75rem; border-radius:20px; border:1px solid rgba(99,102,241,0.3);">OUR SERVICES</span>
            <h2 class="fw-bold mb-2" style="color:var(--text-white);">Premium Auto-Care Solutions</h2>
            <p class="mb-5" style="color:var(--text-secondary);">Professional-grade servicing at multiple state-of-the-art locations nationwide.</p>

            <div class="row g-4">
                <div class="col-md-4">
                    <a href="service.jsp" class="text-decoration-none">
                        <div class="card service-card h-100">
                            <img src="oilchange.jpg" class="card-img-top" alt="Oil Change">
                            <div class="card-body">
                                <h5 class="card-title fw-bold">Oil Change & Lubrication</h5>
                                <p class="card-text">High-quality synthetic oil replacement with multi-point inspection included.</p>
                                <span class="btn btn-sm btn-outline-primary mt-2"><i class="fas fa-arrow-right me-1"></i>View Details</span>
                            </div>
                        </div>
                    </a>
                </div>
                <div class="col-md-4">
                    <a href="service.jsp" class="text-decoration-none">
                        <div class="card service-card h-100">
                            <img src="engine.jpg" class="card-img-top" alt="Engine Repair">
                            <div class="card-body">
                                <h5 class="card-title fw-bold">Engine Diagnostic & Repair</h5>
                                <p class="card-text">OBD-II scanning, fault detection and precision engine rebuilds by certified mechanics.</p>
                                <span class="btn btn-sm btn-outline-primary mt-2"><i class="fas fa-arrow-right me-1"></i>View Details</span>
                            </div>
                        </div>
                    </a>
                </div>
                <div class="col-md-4">
                    <a href="service.jsp" class="text-decoration-none">
                        <div class="card service-card h-100">
                            <img src="tire.jpg" class="card-img-top" alt="Tire Replacement">
                            <div class="card-body">
                                <h5 class="card-title fw-bold">Tire Replacement & Balancing</h5>
                                <p class="card-text">Computer-guided wheel alignment and premium brand tire fitments.</p>
                                <span class="btn btn-sm btn-outline-primary mt-2"><i class="fas fa-arrow-right me-1"></i>View Details</span>
                            </div>
                        </div>
                    </a>
                </div>
            </div>
        </div>
    </section>

    <!-- Why Choose Us -->
    <section class="py-5" style="position:relative; z-index:1;">
        <div class="container py-4">
            <div class="row align-items-center g-5">
                <div class="col-md-6">
                    <span class="badge bg-primary bg-opacity-25 text-white mb-3 px-3 py-2" style="font-size:0.75rem; border-radius:20px; border:1px solid rgba(99,102,241,0.3);">WHY US</span>
                    <h2 class="fw-bold mb-3" style="color:var(--text-white);">Why Choose ServicePilot?</h2>
                    <p style="color:var(--text-secondary);">We provide premium-tier servicing with an intelligent booking system that routes requests to the nearest authorized garage center.</p>

                    <div class="mt-4">
                        <div class="d-flex align-items-start mb-3">
                            <div class="flex-shrink-0 me-3" style="width:40px; height:40px; border-radius:10px; background:rgba(16,185,129,0.1); display:flex; align-items:center; justify-content:center;">
                                <i class="fas fa-shield-check text-success"></i>
                            </div>
                            <div>
                                <h6 class="fw-bold mb-1" style="color:var(--text-white);">Certified Mechanics</h6>
                                <p class="small mb-0" style="color:var(--text-secondary);">OEM-trained professionals with 5+ years average experience.</p>
                            </div>
                        </div>
                        <div class="d-flex align-items-start mb-3">
                            <div class="flex-shrink-0 me-3" style="width:40px; height:40px; border-radius:10px; background:rgba(99,102,241,0.1); display:flex; align-items:center; justify-content:center;">
                                <i class="fas fa-map-marked-alt text-primary"></i>
                            </div>
                            <div>
                                <h6 class="fw-bold mb-1" style="color:var(--text-white);">Multi-Location Network</h6>
                                <p class="small mb-0" style="color:var(--text-secondary);">Pick from multiple garages across the city. Switch locations anytime.</p>
                            </div>
                        </div>
                        <div class="d-flex align-items-start mb-3">
                            <div class="flex-shrink-0 me-3" style="width:40px; height:40px; border-radius:10px; background:rgba(6,182,212,0.1); display:flex; align-items:center; justify-content:center;">
                                <i class="fas fa-chart-line" style="color:var(--secondary);"></i>
                            </div>
                            <div>
                                <h6 class="fw-bold mb-1" style="color:var(--text-white);">Real-Time Tracking</h6>
                                <p class="small mb-0" style="color:var(--text-secondary);">Live photo proofs, stage timelines, and transparent cost breakdowns.</p>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-6">
                    <div class="dashboard-card text-center" style="border:1px solid rgba(99,102,241,0.15);">
                        <div class="mb-3">
                            <i class="fas fa-rocket fa-3x" style="color:var(--primary-light); opacity:0.6;"></i>
                        </div>
                        <h4 class="fw-bold mb-3" style="color:var(--text-white);"><i class="fas fa-bolt me-2 text-warning"></i>Express Servicing</h4>
                        <p style="color:var(--text-secondary);">In a rush? Pre-book our express service lane. Most routine jobs like oil changes, brake checks, and AC servicing are completed in under 2 hours.</p>
                        <a href="bookservice.jsp" class="btn btn-auth px-4 py-2 mt-2">
                            <i class="fas fa-calendar-check me-2"></i>Book Express Slot
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Contact CTA -->
    <section class="py-5 text-center" style="position:relative; z-index:1; background:rgba(17,24,39,0.5);">
        <div class="container">
            <h2 class="fw-bold mb-3" style="color:var(--text-white);">Need Assistance?</h2>
            <p class="mb-4" style="color:var(--text-secondary);">
                <i class="fas fa-envelope me-2"></i> support@servicepilot.com
                <span class="mx-3">|</span>
                <i class="fas fa-phone me-2"></i> +91 9876543210
            </p>
            <a href="contactUs.jsp" class="btn btn-auth px-5 py-3"><i class="fas fa-paper-plane me-2"></i>Send Message</a>
        </div>
    </section>

    <!-- Footer -->
    <footer class="text-white text-center py-4">
        <div class="container">
            <div class="row align-items-center">
                <div class="col-md-4 text-md-start mb-2 mb-md-0">
                    <span class="fw-bold" style="background: linear-gradient(135deg, #818cf8, #06b6d4); -webkit-background-clip: text; -webkit-text-fill-color: transparent;">ServicePilot</span>
                </div>
                <div class="col-md-4">
                    <p class="mb-0 small" style="color:var(--text-muted);">&copy; 2025 ServicePilot. All Rights Reserved.</p>
                </div>
                <div class="col-md-4 text-md-end">
                    <a href="#" class="me-3" style="color:var(--text-muted);"><i class="fab fa-twitter"></i></a>
                    <a href="#" class="me-3" style="color:var(--text-muted);"><i class="fab fa-linkedin"></i></a>
                    <a href="#" style="color:var(--text-muted);"><i class="fab fa-instagram"></i></a>
                </div>
            </div>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Animated counter for stats
        const counters = document.querySelectorAll('[data-count]');
        const speed = 60;
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const el = entry.target;
                    const target = parseFloat(el.getAttribute('data-count'));
                    const isDecimal = target % 1 !== 0;
                    let current = 0;
                    const increment = target / speed;
                    const timer = setInterval(() => {
                        current += increment;
                        if (current >= target) {
                            el.textContent = isDecimal ? target.toFixed(1) : Math.ceil(target).toLocaleString();
                            clearInterval(timer);
                        } else {
                            el.textContent = isDecimal ? current.toFixed(1) : Math.ceil(current).toLocaleString();
                        }
                    }, 25);
                    observer.unobserve(el);
                }
            });
        }, { threshold: 0.5 });
        counters.forEach(c => observer.observe(c));
    </script>
</body>
</html>
