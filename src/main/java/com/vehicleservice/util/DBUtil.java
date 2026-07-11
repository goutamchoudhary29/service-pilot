package com.vehicleservice.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBUtil {
    private static final String URL;
    private static final String USER;
    private static final String PASSWORD;

    static {
        String dbHost = System.getenv("DB_HOST");
        String dbPort = System.getenv("DB_PORT");
        String dbName = System.getenv("DB_NAME");
        String dbUser = System.getenv("DB_USER");
        String dbPassword = System.getenv("DB_PASSWORD");
        String dbUrl = System.getenv("DB_URL");

        if (dbUrl != null && !dbUrl.trim().isEmpty()) {
            URL = dbUrl;
        } else if (dbHost != null && dbPort != null && dbName != null) {
            URL = "jdbc:mysql://" + dbHost + ":" + dbPort + "/" + dbName;
        } else {
            URL = "jdbc:mysql://localhost:3306/servicepilot";
        }

        USER = (dbUser != null) ? dbUser : "root";
        PASSWORD = (dbPassword != null) ? dbPassword : "9926";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASSWORD);
    }
}
