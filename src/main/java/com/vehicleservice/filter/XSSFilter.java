package com.vehicleservice.filter;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletRequestWrapper;
import java.io.IOException;
import java.util.regex.Pattern;

@WebFilter("/*")
public class XSSFilter implements Filter {

    private static final Pattern[] XSS_PATTERNS = {
        Pattern.compile("<script>(.*?)</script>", Pattern.CASE_INSENSITIVE),
        Pattern.compile("src[\r\n]*=[\r\n]*'(.*?)'", Pattern.CASE_INSENSITIVE | Pattern.MULTILINE),
        Pattern.compile("src[\r\n]*=[\r\n]*\"(.*?)\"", Pattern.CASE_INSENSITIVE | Pattern.MULTILINE),
        Pattern.compile("</script>", Pattern.CASE_INSENSITIVE),
        Pattern.compile("<script(.*?)>", Pattern.CASE_INSENSITIVE | Pattern.MULTILINE),
        Pattern.compile("eval\\((.*?)\\)", Pattern.CASE_INSENSITIVE | Pattern.MULTILINE),
        Pattern.compile("expression\\((.*?)\\)", Pattern.CASE_INSENSITIVE | Pattern.MULTILINE),
        Pattern.compile("javascript:", Pattern.CASE_INSENSITIVE),
        Pattern.compile("vbscript:", Pattern.CASE_INSENSITIVE),
        Pattern.compile("onload(.*?)=", Pattern.CASE_INSENSITIVE | Pattern.MULTILINE),
        Pattern.compile("onerror(.*?)=", Pattern.CASE_INSENSITIVE | Pattern.MULTILINE),
        Pattern.compile("onclick(.*?)=", Pattern.CASE_INSENSITIVE | Pattern.MULTILINE),
        Pattern.compile("<iframe(.*?)>", Pattern.CASE_INSENSITIVE | Pattern.MULTILINE)
    };

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        chain.doFilter(new XSSRequestWrapper((HttpServletRequest) request), response);
    }

    @Override
    public void destroy() {}

    private static class XSSRequestWrapper extends HttpServletRequestWrapper {
        public XSSRequestWrapper(HttpServletRequest request) {
            super(request);
        }

        @Override
        public String getParameter(String name) {
            String value = super.getParameter(name);
            return stripXSS(value);
        }

        @Override
        public String[] getParameterValues(String name) {
            String[] values = super.getParameterValues(name);
            if (values == null) return null;
            String[] clean = new String[values.length];
            for (int i = 0; i < values.length; i++) {
                clean[i] = stripXSS(values[i]);
            }
            return clean;
        }

        @Override
        public String getHeader(String name) {
            String value = super.getHeader(name);
            return stripXSS(value);
        }

        private String stripXSS(String value) {
            if (value == null) return null;
            for (Pattern pattern : XSS_PATTERNS) {
                value = pattern.matcher(value).replaceAll("");
            }
            return value;
        }
    }
}
