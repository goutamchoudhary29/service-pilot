package com.vehicleservice.util;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;

public class SecurityUtilTest {

    @Test
    public void testHashAndCheckPassword() {
        String password = "securePassword123";
        String hashed = SecurityUtil.hashPassword(password);
        
        assertNotNull(hashed);
        assertNotEquals(password, hashed);
        assertTrue(SecurityUtil.checkPassword(password, hashed));
        assertFalse(SecurityUtil.checkPassword("wrongPassword", hashed));
        assertFalse(SecurityUtil.checkPassword(null, hashed));
        assertFalse(SecurityUtil.checkPassword(password, null));
    }

    @Test
    public void testGenerateAndValidateCSRFToken() {
        // Create mock session using dynamic proxy
        final Map<String, Object> sessionAttributes = new HashMap<>();
        HttpSession mockSession = (HttpSession) Proxy.newProxyInstance(
                HttpSession.class.getClassLoader(),
                new Class<?>[]{HttpSession.class},
                (proxy, method, args) -> {
                    if ("setAttribute".equals(method.getName())) {
                        sessionAttributes.put((String) args[0], args[1]);
                        return null;
                    } else if ("getAttribute".equals(method.getName())) {
                        return sessionAttributes.get((String) args[0]);
                    }
                    return null;
                }
        );

        // Generate token
        String token = SecurityUtil.generateCSRFToken(mockSession);
        assertNotNull(token);
        assertFalse(token.isEmpty());
        assertEquals(token, sessionAttributes.get("csrfToken"));

        // Create mock request using dynamic proxy
        HttpServletRequest mockRequest = (HttpServletRequest) Proxy.newProxyInstance(
                HttpServletRequest.class.getClassLoader(),
                new Class<?>[]{HttpServletRequest.class},
                (proxy, method, args) -> {
                    if ("getSession".equals(method.getName())) {
                        return mockSession;
                    } else if ("getParameter".equals(method.getName())) {
                        if ("csrfToken".equals(args[0])) {
                            return token; // return correct token
                        }
                    }
                    return null;
                }
        );

        assertTrue(SecurityUtil.validateCSRFToken(mockRequest));

        // Create a mock request with incorrect token
        HttpServletRequest mockRequestWrong = (HttpServletRequest) Proxy.newProxyInstance(
                HttpServletRequest.class.getClassLoader(),
                new Class<?>[]{HttpServletRequest.class},
                (proxy, method, args) -> {
                    if ("getSession".equals(method.getName())) {
                        return mockSession;
                    } else if ("getParameter".equals(method.getName())) {
                        if ("csrfToken".equals(args[0])) {
                            return "wrong-token";
                        }
                    }
                    return null;
                }
        );

        assertFalse(SecurityUtil.validateCSRFToken(mockRequestWrong));
    }
}
