<%@ page contentType="text/html; charset=UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Customer Login — ServicePilot</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="css/styles.css" rel="stylesheet">
</head>
<body class="auth-body">
    <div class="auth-card" style="animation: scaleUp 0.5s ease-out;">
        <!-- Logo -->
        <div class="text-center mb-4">
            <div style="width:56px; height:56px; border-radius:16px; background:linear-gradient(135deg, var(--primary), var(--secondary)); display:inline-flex; align-items:center; justify-content:center; margin-bottom:16px;">
                <i class="fas fa-cogs text-white fa-lg"></i>
            </div>
            <h2 class="auth-title">Welcome Back</h2>
            <p class="text-muted small mb-0">Sign in to access your service dashboard</p>
        </div>

        <% String error = request.getParameter("error");
           if (error != null) { %>
            <div class="alert alert-danger text-center py-2 small mb-3">
                <i class="fas fa-exclamation-circle me-1"></i> <%= error %>
            </div>
        <% } %>
        <% String success = request.getParameter("success");
           if (success != null) { %>
            <div class="alert alert-success text-center py-2 small mb-3">
                <i class="fas fa-check-circle me-1"></i> <%= success %>
            </div>
        <% } %>

        <form action="CustomerLoginServlet" method="post">
            <div class="mb-3">
                <label for="email" class="form-label">Email Address</label>
                <div class="position-relative">
                    <span class="position-absolute top-50 translate-middle-y ms-3" style="color:var(--text-muted);"><i class="fas fa-envelope"></i></span>
                    <input type="email" class="form-control" id="email" name="email" placeholder="name@example.com" required style="padding-left:38px;">
                </div>
            </div>

            <div class="mb-4">
                <label for="password" class="form-label">Password</label>
                <div class="position-relative">
                    <span class="position-absolute top-50 translate-middle-y ms-3" style="color:var(--text-muted);"><i class="fas fa-lock"></i></span>
                    <input type="password" class="form-control" id="password" name="password" placeholder="••••••••" required style="padding-left:38px;">
                    <span class="position-absolute top-50 translate-middle-y end-0 me-3" style="color:var(--text-muted); cursor:pointer;" onclick="togglePassword()"><i class="fas fa-eye" id="eyeIcon"></i></span>
                </div>
            </div>

            <button type="submit" class="btn btn-auth w-100 py-2 mt-1" style="font-size:1rem;">
                <i class="fas fa-sign-in-alt me-2"></i>Sign In
            </button>
        </form>

        <div class="text-center mt-4">
            <span style="color:var(--text-muted); font-size:0.9rem;">Don't have an account?</span>
            <a href="signup.jsp" class="auth-link fw-bold ms-1" style="font-size:0.9rem;">Register here</a>
        </div>

        <div class="text-center mt-3">
            <a href="index.jsp" class="btn-back-home text-decoration-none"><i class="fas fa-arrow-left me-1"></i>Back to Home</a>
        </div>
    </div>

    <script>
        function togglePassword() {
            var field = document.getElementById('password');
            var icon = document.getElementById('eyeIcon');
            if (field.type === 'password') {
                field.type = 'text';
                icon.classList.replace('fa-eye', 'fa-eye-slash');
            } else {
                field.type = 'password';
                icon.classList.replace('fa-eye-slash', 'fa-eye');
            }
        }
    </script>
</body>
</html>
