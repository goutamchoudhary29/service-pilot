package com.vehicleservice.dao;

import com.vehicleservice.model.ContactMessage;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import com.vehicleservice.util.DBUtil;

public class ContactDAO {
    // Uses DBUtil to avoid hardcoded credentials

    private static final String INSERT_CONTACT_SQL = "INSERT INTO contact_messages (name, email, subject, message) VALUES (?, ?, ?, ?);";

    protected Connection getConnection() {
        Connection connection = null;
        try {
            connection = DBUtil.getConnection();
            if (connection != null) {
                System.out.println("✅ Database Connected Successfully!");
            } else {
                System.err.println("❌ Connection failed: getConnection() returned null.");
            }
        } catch (SQLException e) {
            System.err.println("SQL Exception: " + e.getMessage());
            e.printStackTrace();
        }
        return connection;
    }




    public void insertMessage(ContactMessage message) {
        System.out.println("Inserting message into database...");
        try (Connection connection = getConnection();
             PreparedStatement preparedStatement = connection.prepareStatement(INSERT_CONTACT_SQL)) {
            preparedStatement.setString(1, message.getName());
            preparedStatement.setString(2, message.getEmail());
            preparedStatement.setString(3, message.getSubject());
            preparedStatement.setString(4, message.getMessage());
            preparedStatement.executeUpdate();
            System.out.println("Message inserted successfully!");
        } catch (SQLException e) {
            System.err.println("SQL Exception during message insertion: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
