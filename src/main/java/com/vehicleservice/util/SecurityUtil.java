package com.vehicleservice.util;

import org.mindrot.jbcrypt.BCrypt;
import java.security.SecureRandom;
import java.util.Base64;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

public class SecurityUtil {

    private static final SecureRandom secureRandom = new SecureRandom();

    /**
     * Hashes a password using BCrypt.
     */
    public static String hashPassword(String password) {
        if (password == null) {
            return null;
        }
        return BCrypt.hashpw(password, BCrypt.gensalt(12));
    }

    /**
     * Verifies a candidate password against its hashed value using BCrypt.
     */
    public static boolean checkPassword(String candidate, String hashed) {
        if (candidate == null || hashed == null) {
            return false;
        }
        try {
            return BCrypt.checkpw(candidate, hashed);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Generates a CSRF token and binds it to the current session.
     */
    public static String generateCSRFToken(HttpSession session) {
        byte[] tokenBytes = new byte[32];
        secureRandom.nextBytes(tokenBytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
        session.setAttribute("csrfToken", token);
        return token;
    }

    /**
     * Validates if the CSRF token in the request matches the session token.
     */
    public static boolean validateCSRFToken(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return false;
        }
        String sessionToken = (String) session.getAttribute("csrfToken");
        String requestToken = request.getParameter("csrfToken");
        if (requestToken == null) {
            requestToken = request.getHeader("X-CSRF-TOKEN");
        }
        return sessionToken != null && sessionToken.equals(requestToken);
    }
}
