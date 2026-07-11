<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Thank You - ServicePilot</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="styles.css" rel="stylesheet">
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
                <ul class="navbar-nav ms-auto">
                    <li class="nav-item"><a class="nav-link" href="index.jsp">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="services.jsp">Services</a></li>
                    <li class="nav-item"><a class="nav-link" href="aboutus.jsp">About Us</a></li>
                    <li class="nav-item"><a class="nav-link active" href="contactus.jsp">Contact</a></li>
                    <li class="nav-item"><a class="nav-link btn btn-primary text-white mx-2" href="login.jsp">Login</a></li>
                </ul>
            </div>
        </div>
    </nav>

    <!-- Thank You Section -->
    <section class="thank-you-section text-center py-5">
        <div class="container">
            <div class="thank-you-content bg-white p-5 rounded shadow">
                <h1 class="display-4 fw-bold text-primary mb-4">Thank You!</h1>
                <p class="lead text-muted mb-4">We have received your message and will get back to you soon.</p>
                <a href="index.jsp" class="btn btn-primary btn-lg">Return to Home</a>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="bg-dark text-white text-center py-3">
        <p class="mb-0">&copy; 2025 ServicePilot. All Rights Reserved.</p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
<style>
/* Thank You Section */
.thank-you-section {
    background: linear-gradient(rgba(44, 62, 80, 0.8), rgba(44, 62, 80, 0.8)), url('images/thank-you-bg.jpg');
    background-size: cover;
    background-position: center;
    min-height: 70vh;
    display: flex;
    align-items: center;
    justify-content: center;
}

.thank-you-content {
    max-width: 600px;
    margin: 0 auto;
    padding: 40px;
    background: rgba(255, 255, 255, 0.95);
    border-radius: 10px;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
}

.thank-you-content h1 {
    font-size: 3rem;
    color: #2c3e50;
    margin-bottom: 20px;
}

.thank-you-content p {
    font-size: 1.2rem;
    color: #555;
    margin-bottom: 30px;
}

.thank-you-content .btn-primary {
    background-color: #18bc9c;
    border: none;
    padding: 10px 30px;
    font-size: 1.1rem;
    transition: background-color 0.3s ease;
}

.thank-you-content .btn-primary:hover {
    background-color: #128f76;
}

/* Footer */
footer {
    background: #2c3e50;
    padding: 20px 0;
    margin-top: auto;
}

footer p {
    margin: 0;
    font-size: 0.9rem;
    color: #fff;
}
</style>