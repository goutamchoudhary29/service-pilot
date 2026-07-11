package com.vehicleservice.filter;

import com.vehicleservice.util.SecurityUtil;
import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

@WebFilter("/*")
public class SecurityFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        // 1. Prevent Browser Caching on Sensitive Secured Pages (Dashboard, Settings, Catalog actions)
        String path = httpRequest.getRequestURI();
        if (path.contains("dashboard.jsp") || path.contains("settings.jsp") || path.contains("booking") || path.contains("Servlet")) {
            httpResponse.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            httpResponse.setHeader("Pragma", "no-cache");
            httpResponse.setDateHeader("Expires", 0);
        }

        // Add standard security headers
        httpResponse.setHeader("X-Frame-Options", "DENY");
        httpResponse.setHeader("X-Content-Type-Options", "nosniff");
        httpResponse.setHeader("X-XSS-Protection", "1; mode=block");

        // 2. Validate CSRF on all mutation requests (POST)
        // Exceptions are made for the entry point Login/Register actions which establish the initial session
        if ("POST".equalsIgnoreCase(httpRequest.getMethod())) {
            boolean isAuthEndpoint = path.contains("CustomerLoginServlet") || 
                                     path.contains("AdminLoginServlet") || 
                                     path.contains("CustomerRegisterServlet");
            
            if (!isAuthEndpoint) {
                if (!SecurityUtil.validateCSRFToken(httpRequest)) {
                    httpResponse.sendError(HttpServletResponse.SC_FORBIDDEN, "CSRF Validation Failed: Security Violation.");
                    return;
                }
            }
        }

        chain.doFilter(request, response);
    }

    @Override
    public void destroy() {}
}
