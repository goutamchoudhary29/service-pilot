<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vehicleservice.util.DBUtil, java.sql.*" %>
<%
    String loggedName = (String) session.getAttribute("customerName");
    String loggedEmail = (String) session.getAttribute("customerEmail");
    Integer customerId = (Integer) session.getAttribute("customerId");
    String csrfToken = (String) session.getAttribute("csrfToken");
    if (csrfToken == null) csrfToken = "";

    if (loggedEmail == null || customerId == null) {
        response.sendRedirect("login.jsp?error=Please%20log%20in%20first.");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Book Service - ServicePilot</title>
    <meta name="csrf-token" content="<%= csrfToken %>">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css" rel="stylesheet">
    <link href="css/styles.css" rel="stylesheet">
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
                <ul class="navbar-nav ms-auto align-items-center">
                    <li class="nav-item"><a class="nav-link" href="index.jsp">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="service.jsp">Services</a></li>
                    <li class="nav-item"><a class="nav-link btn btn-primary text-white mx-2" href="customer_dashboard.jsp">Dashboard</a></li>
                    <li class="nav-item">
                        <a href="index.jsp" class="btn btn-outline-danger btn-sm text-white px-3 py-1">Logout</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <!-- Service Booking Section -->
    <section class="container my-5">
        <% 
            String error = request.getParameter("error");
            if (error != null) { 
        %>
            <div class="alert alert-danger text-center py-2 mb-4">
                <i class="fas fa-exclamation-circle me-1"></i> <%= error %>
            </div>
        <% } %>

        <div class="booking-card shadow-lg p-5">
            <h2 class="text-center fw-bold mb-4">Book a Vehicle Service Slot</h2>
            <form action="BookServiceServlet" method="post">
                <!-- CSRF PROTECTION -->
                <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                
                <!-- Vehicle Selection -->
                <h4 class="mb-3 text-primary border-bottom pb-2">1. Select Registered Vehicle</h4>
                <div class="mb-4">
                    <label for="vehicleId" class="form-label">Your Vehicle</label>
                    <select class="form-select" id="vehicleId" name="vehicleId" required>
                        <option value="">Select a Vehicle</option>
                        <%
                            Connection conn = null;
                            PreparedStatement pstmt = null;
                            ResultSet rs = null;
                            boolean hasVehicles = false;
                            try {
                                conn = DBUtil.getConnection();
                                String query = "SELECT id, brand, model, license_plate FROM vehicles WHERE customer_id = ? AND status = 'Active'";
                                pstmt = conn.prepareStatement(query);
                                pstmt.setInt(1, customerId);
                                rs = pstmt.executeQuery();
                                while (rs.next()) {
                                    hasVehicles = true;
                        %>
                                    <option value="<%= rs.getInt("id") %>"><%= rs.getString("brand") %> <%= rs.getString("model") %> (<%= rs.getString("license_plate") %>)</option>
                        <%
                                }
                            } catch (Exception e) {
                                e.printStackTrace();
                            } finally {
                                if (rs != null) rs.close();
                                if (pstmt != null) pstmt.close();
                            }
                        %>
                    </select>
                    <% if (!hasVehicles) { %>
                        <div class="alert alert-warning mt-2 small py-2">
                            <i class="fas fa-exclamation-triangle me-1"></i> No vehicles found. Please <a href="customer_dashboard.jsp" class="fw-bold">Register a Vehicle</a> first in your dashboard.
                        </div>
                    <% } %>
                </div>
                
                <!-- Branch and Service Selection -->
                <h4 class="mb-3 text-primary border-bottom pb-2">2. Garage & Service Selection</h4>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label for="branchId" class="form-label">Garage Branch Location</label>
                        <select class="form-select" id="branchId" name="branchId" required>
                            <option value="">Select a Branch</option>
                            <%
                                try {
                                    String query = "SELECT id, name, address FROM branches WHERE status = 'Active'";
                                    pstmt = conn.prepareStatement(query);
                                    rs = pstmt.executeQuery();
                                    while (rs.next()) {
                            %>
                                        <option value="<%= rs.getInt("id") %>"><%= rs.getString("name") %> - <%= rs.getString("address") %></option>
                            <%
                                    }
                                } catch (Exception e) {
                                    e.printStackTrace();
                                } finally {
                                    if (rs != null) rs.close();
                                    if (pstmt != null) pstmt.close();
                                }
                            %>
                        </select>
                    </div>

                    <div class="col-md-6 mb-3">
                        <label for="serviceId" class="form-label">Service Type</label>
                        <select class="form-select" id="serviceId" name="serviceId" required>
                            <option value="">Select a Service</option>
                            <%
                                try {
                                    String query = "SELECT id, service_name, price FROM services WHERE status = 'Available'";
                                    pstmt = conn.prepareStatement(query);
                                    rs = pstmt.executeQuery();
                                    while (rs.next()) {
                            %>
                                        <option value="<%= rs.getInt("id") %>"><%= rs.getString("service_name") %> (₹<%= rs.getDouble("price") %>)</option>
                            <%
                                    }
                                } catch (Exception e) {
                                    e.printStackTrace();
                                } finally {
                                    if (rs != null) rs.close();
                                    if (pstmt != null) pstmt.close();
                                }
                            %>
                        </select>
                    </div>
                </div>

                <!-- Date, Time and Mechanic -->
                <h4 class="mb-3 text-primary border-bottom pb-2 mt-4">3. Slot Booking & Mechanic Selection</h4>
                <div class="row">
                    <div class="col-md-4 mb-3">
                        <label for="bookingDate" class="form-label">Service Date</label>
                        <input type="date" class="form-control" id="bookingDate" name="bookingDate" required>
                    </div>

                    <div class="col-md-4 mb-3">
                        <label for="timeSlot" class="form-label">Preferred Time Slot</label>
                        <select class="form-select" id="timeSlot" name="timeSlot" required>
                            <option value="">Select Time Slot</option>
                            <option value="09:00-10:00">09:00 AM - 10:00 AM</option>
                            <option value="10:00-11:00">10:00 AM - 11:00 AM</option>
                            <option value="11:00-12:00">11:00 AM - 12:00 PM</option>
                            <option value="12:00-13:00">12:00 PM - 01:00 PM</option>
                            <option value="14:00-15:00">02:00 PM - 03:00 PM</option>
                            <option value="15:00-16:00">03:00 PM - 04:00 PM</option>
                            <option value="16:00-17:00">04:00 PM - 05:00 PM</option>
                        </select>
                    </div>

                    <div class="col-md-4 mb-3">
                        <label for="mechanicId" class="form-label">Select Mechanic</label>
                        <select class="form-select" id="mechanicId" name="mechanicId" required>
                            <option value="">Select Mechanic</option>
                            <%
                                try {
                                    String query = "SELECT m.id, u.name, m.specialization FROM mechanics m " +
                                                   "JOIN employees e ON m.employee_id = e.id " +
                                                   "JOIN users u ON e.user_id = u.id " +
                                                   "WHERE e.status = 'Active'";
                                    pstmt = conn.prepareStatement(query);
                                    rs = pstmt.executeQuery();
                                    while (rs.next()) {
                            %>
                                        <option value="<%= rs.getInt("id") %>"><%= rs.getString("name") %> (<%= rs.getString("specialization") %>)</option>
                            <%
                                    }
                                } catch (Exception e) {
                                    e.printStackTrace();
                                } finally {
                                    if (rs != null) rs.close();
                                    if (pstmt != null) pstmt.close();
                                    if (conn != null) conn.close();
                                }
                            %>
                        </select>
                    </div>
                </div>
                <div id="availabilityAlert" class="alert alert-danger d-none mt-3 py-2 small">
                    <i class="fas fa-exclamation-triangle me-1"></i> This time slot is already booked for the selected mechanic. Please choose a different mechanic or time slot.
                </div>

                <div class="mb-3">
                    <label for="additionalNotes" class="form-label">Additional Repair Notes</label>
                    <textarea class="form-control" id="additionalNotes" name="additionalNotes" rows="3" placeholder="Explain vehicle complaints or requirements here..."></textarea>
                </div>

                <!-- Submit Button -->
                <div class="text-center mt-4">
                    <button type="submit" id="submitBookingBtn" class="btn btn-primary btn-lg w-100 py-3 btn-auth" <%= !hasVehicles ? "disabled" : "" %>>Confirm Booking Slot</button>
                </div>
            </form>
        </div>
    </section>

    <!-- Footer -->
    <footer class="bg-dark text-white text-center py-4 mt-5">
        <p class="mb-0">&copy; 2025 ServicePilot. All Rights Reserved.</p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Restrict calendar dates to future dates only
        var today = new Date().toISOString().split('T')[0];
        var dateInput = document.getElementById("bookingDate");
        dateInput.setAttribute('min', today);

        var timeSlotSelect = document.getElementById("timeSlot");
        var mechanicSelect = document.getElementById("mechanicId");
        var alertDiv = document.getElementById("availabilityAlert");
        var submitBtn = document.getElementById("submitBookingBtn");
        var initialHasVehicles = <%= hasVehicles %>;

        var bookedSlotsList = [];

        async function fetchBookedSlots() {
            var selectedDate = dateInput.value;
            if (!selectedDate) return;

            try {
                var response = await fetch("CheckSlotAvailabilityServlet?date=" + selectedDate);
                if (response.ok) {
                    bookedSlotsList = await response.json();
                } else {
                    bookedSlotsList = [];
                }
            } catch (err) {
                console.error("Error fetching slot allocations", err);
                bookedSlotsList = [];
            }
            checkAvailability();
        }

        function checkAvailability() {
            var selectedSlot = timeSlotSelect.value;
            var selectedMech = mechanicSelect.value;

            if (!selectedSlot || !selectedMech) {
                alertDiv.classList.add("d-none");
                if (initialHasVehicles) submitBtn.removeAttribute("disabled");
                return;
            }

            // Check if combination is in the booked list
            var isBooked = bookedSlotsList.some(function(item) {
                return item.timeSlot === selectedSlot && item.mechanicId == selectedMech;
            });

            if (isBooked) {
                alertDiv.classList.remove("d-none");
                submitBtn.setAttribute("disabled", "true");
            } else {
                alertDiv.classList.add("d-none");
                if (initialHasVehicles) submitBtn.removeAttribute("disabled");
            }
        }

        dateInput.addEventListener("change", fetchBookedSlots);
        timeSlotSelect.addEventListener("change", checkAvailability);
        mechanicSelect.addEventListener("change", checkAvailability);

        (function() {
            var token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
            if (!token) return;
            document.querySelectorAll('form').forEach(function(form) {
                if ((form.method || '').toLowerCase() === 'post') {
                    if (!form.querySelector('input[name="csrfToken"]')) {
                        var inp = document.createElement('input');
                        inp.type = 'hidden';
                        inp.name = 'csrfToken';
                        inp.value = token;
                        form.appendChild(inp);
                    }
                    var action = form.getAttribute('action') || '';
                    if (action && action.indexOf('csrfToken=') === -1) {
                        var separator = action.indexOf('?') !== -1 ? '&' : '?';
                        form.setAttribute('action', action + separator + 'csrfToken=' + encodeURIComponent(token));
                    }
                }
            });
        })();
    </script>
</body>
</html>
