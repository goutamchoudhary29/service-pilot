<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Account — ServicePilot</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="css/styles.css" rel="stylesheet">
</head>
<body class="auth-body">
    <div class="auth-card" style="max-width:480px; animation: scaleUp 0.5s ease-out;">
        <!-- Logo -->
        <div class="text-center mb-4">
            <div style="width:56px; height:56px; border-radius:16px; background:linear-gradient(135deg, var(--success), var(--secondary)); display:inline-flex; align-items:center; justify-content:center; margin-bottom:16px;">
                <i class="fas fa-user-plus text-white fa-lg"></i>
            </div>
            <h2 class="auth-title">Create Account</h2>
            <p class="text-muted small mb-0">Join ServicePilot for seamless vehicle management</p>
        </div>

        <% String error = request.getParameter("error");
           if (error != null) { %>
            <div class="alert alert-danger text-center py-2 small mb-3">
                <i class="fas fa-exclamation-circle me-1"></i> <%= error %>
            </div>
        <% } %>

        <form action="CustomerRegisterServlet" method="post">
            <div class="mb-3">
                <label for="name" class="form-label">Full Name</label>
                <div class="position-relative">
                    <span class="position-absolute top-50 translate-middle-y ms-3" style="color:var(--text-muted);"><i class="fas fa-user"></i></span>
                    <input type="text" class="form-control" id="name" name="name" placeholder="John Doe" required style="padding-left:38px;">
                </div>
            </div>

            <div class="mb-3">
                <label for="email" class="form-label">Email Address</label>
                <div class="position-relative">
                    <span class="position-absolute top-50 translate-middle-y ms-3" style="color:var(--text-muted);"><i class="fas fa-envelope"></i></span>
                    <input type="email" class="form-control" id="email" name="email" placeholder="john@example.com" required style="padding-left:38px;">
                </div>
            </div>

            <div class="mb-3">
                <label for="phone" class="form-label">Phone Number</label>
                <div class="position-relative">
                    <span class="position-absolute top-50 translate-middle-y ms-3" style="color:var(--text-muted);"><i class="fas fa-phone"></i></span>
                    <input type="text" class="form-control" id="phone" name="phone" placeholder="9876543210" pattern="[0-9]{10}" maxlength="10" required style="padding-left:38px;">
                </div>
            </div>

            <div class="mb-4">
                <label for="password" class="form-label">Password</label>
                <div class="position-relative">
                    <span class="position-absolute top-50 translate-middle-y ms-3" style="color:var(--text-muted);"><i class="fas fa-lock"></i></span>
                    <input type="password" class="form-control" id="password" name="password" placeholder="Min 6 characters" minlength="6" required style="padding-left:38px;">
                    <span class="position-absolute top-50 translate-middle-y end-0 me-3" style="color:var(--text-muted); cursor:pointer;" onclick="togglePassword()"><i class="fas fa-eye" id="eyeIcon"></i></span>
                </div>
                <div class="mt-2" id="strengthBar" style="height:3px; border-radius:3px; background:var(--border-subtle); overflow:hidden;">
                    <div id="strengthFill" style="height:100%; width:0%; transition:var(--transition); border-radius:3px;"></div>
                </div>
            </div>

            <button type="submit" class="btn btn-auth w-100 py-2 mt-1" style="font-size:1rem;">
                <i class="fas fa-rocket me-2"></i>Create Account
            </button>
        </form>

        <div class="text-center mt-4">
            <span style="color:var(--text-muted); font-size:0.9rem;">Already have an account?</span>
            <a href="login.jsp" class="auth-link fw-bold ms-1" style="font-size:0.9rem;">Login here</a>
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

        // Password strength indicator
        document.getElementById('password').addEventListener('input', function() {
            var val = this.value;
            var fill = document.getElementById('strengthFill');
            var strength = 0;
            if (val.length >= 6) strength += 25;
            if (val.length >= 10) strength += 25;
            if (/[A-Z]/.test(val)) strength += 25;
            if (/[0-9!@#$%^&*]/.test(val)) strength += 25;

            fill.style.width = strength + '%';
            if (strength <= 25) fill.style.background = '#ef4444';
            else if (strength <= 50) fill.style.background = '#f59e0b';
            else if (strength <= 75) fill.style.background = '#06b6d4';
            else fill.style.background = '#10b981';
        });
    </script>
</body>
</html>
