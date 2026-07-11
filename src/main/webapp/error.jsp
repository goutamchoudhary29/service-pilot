<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error - ServicePilot</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="css/styles.css" rel="stylesheet">
</head>
<body class="d-flex align-items-center min-vh-100 justify-content-center" style="background: #0b0f19;">
    <div class="container text-center">
        <div class="p-5 mx-auto" style="max-width: 500px; background: rgba(17, 24, 39, 0.7); border: 1px solid rgba(99, 102, 241, 0.3); border-radius: 16px; box-shadow: 0 0 20px rgba(99, 102, 241, 0.15);">
            <div class="mb-4">
                <i class="fas fa-exclamation-triangle text-warning fa-4x"></i>
            </div>
            <%
                int statusCode = response.getStatus();
                String title = "Unexpected Error";
                String message = "An error occurred while processing your request. Please try again later.";
                if (statusCode == 404) {
                    title = "Page Not Found";
                    message = "The page you are looking for might have been removed, had its name changed, or is temporarily unavailable.";
                } else if (statusCode == 403) {
                    title = "Access Denied";
                    message = "You do not have permission to access this resource.";
                }
            %>
            <h2 class="fw-bold mb-3 text-white"><%= title %></h2>
            <p class="mb-4" style="color: #94a3b8;"><%= message %></p>
            <div class="mb-4 small" style="color: #64748b;">
                Error Code: <strong><%= statusCode %></strong>
            </div>
            <a href="index.jsp" class="btn btn-primary px-4 py-2" style="background: #6366f1; border-color: #6366f1; font-weight: 500;"><i class="fas fa-home me-2"></i>Go back home</a>
        </div>
    </div>
</body>
</html>
