<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vehicleservice.util.DBUtil, java.sql.*, java.util.Date" %>
<%
    // Session Verification
    HttpSession sess = request.getSession(false);
    String customerEmail = (sess != null) ? (String) sess.getAttribute("customerEmail") : null;
    String customerName = (sess != null) ? (String) sess.getAttribute("customerName") : null;
    Integer customerId = (sess != null) ? (Integer) sess.getAttribute("customerId") : null;
    String csrfToken = (sess != null) ? (String) sess.getAttribute("csrfToken") : null;

    if (customerEmail == null || customerId == null) {
        response.sendRedirect("login.jsp?error=Please+log+in+first");
        return;
    }

    String activeTab = request.getParameter("tab");
    if (activeTab == null) activeTab = "overview";

    String successMsg = request.getParameter("success");
    String errorMsg = request.getParameter("error");

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    String customerPhone = "";
    String customerAddress = "";
    String emergencyContact = "";
    int loyaltyPoints = 0;
    String notes = "";

    try {
        conn = DBUtil.getConnection();
        // Fetch extended customer info
        PreparedStatement infoPs = conn.prepareStatement(
            "SELECT u.phone, c.address, c.emergency_contact, c.loyalty_points, c.notes " +
            "FROM users u JOIN customers c ON c.user_id = u.id WHERE c.id = ?");
        infoPs.setInt(1, customerId);
        ResultSet infoRs = infoPs.executeQuery();
        if (infoRs.next()) {
            customerPhone = infoRs.getString("phone");
            customerAddress = infoRs.getString("address");
            emergencyContact = infoRs.getString("emergency_contact");
            loyaltyPoints = infoRs.getInt("loyalty_points");
            notes = infoRs.getString("notes");
        }
        infoRs.close(); infoPs.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Customer Panel — ServicePilot</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="css/styles.css" rel="stylesheet">
    <style>
        .profile-header-img {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            object-fit: cover;
            border: 3px solid var(--primary);
            box-shadow: var(--glow-primary);
        }
        .nav-tabs {
            border-bottom: 1px solid var(--border-subtle) !important;
        }
        .list-group-item {
            border-bottom: 1px solid var(--border-subtle) !important;
        }
    </style>
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="index.jsp"><i class="fas fa-cogs me-2"></i>ServicePilot</a>
            <button class="navbar-toggler border-0" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto align-items-center gap-2">
                    <li class="nav-item"><a class="nav-link" href="index.jsp">Home</a></li>
                    <li class="nav-item"><a class="nav-link" href="service.jsp">Services</a></li>
                    <li class="nav-item"><a class="nav-link btn btn-primary text-white px-3" href="bookservice.jsp"><i class="fas fa-calendar-plus me-1"></i>Book Service</a></li>
                    <li class="nav-item ms-2">
                        <span class="text-white small opacity-75"><i class="fas fa-user-circle me-1"></i><%= customerName %></span>
                    </li>
                    <li class="nav-item">
                        <a href="LogoutServlet" class="btn btn-sm btn-outline-danger px-3"><i class="fas fa-power-off me-1"></i>Logout</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="dashboard-container">
        <!-- Toast Alerts -->
        <% if (successMsg != null) { %>
            <div class="alert alert-success alert-dismissible fade show py-2 small" role="alert">
                <i class="fas fa-check-circle me-2"></i><%= successMsg %>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        <% if (errorMsg != null) { %>
            <div class="alert alert-danger alert-dismissible fade show py-2 small" role="alert">
                <i class="fas fa-exclamation-circle me-2"></i><%= errorMsg %>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="alert"></button>
            </div>
        <% } %>

        <!-- Welcome Banner -->
        <div class="dashboard-card mb-4 d-flex justify-content-between align-items-center flex-wrap gap-3">
            <div class="d-flex align-items-center gap-3">
                <div style="width:64px; height:64px; border-radius:50%; background:linear-gradient(135deg, var(--primary), var(--secondary)); display:flex; align-items:center; justify-content:center;">
                    <i class="fas fa-user text-white fa-lg"></i>
                </div>
                <div>
                    <h4 class="fw-bold text-white mb-1">Welcome Back, <%= customerName %>!</h4>
                    <p class="text-muted small mb-0"><i class="fas fa-envelope me-1"></i><%= customerEmail %> | <i class="fas fa-phone me-1"></i><%= customerPhone != null ? customerPhone : "No phone listed" %></p>
                </div>
            </div>
            <div class="d-flex gap-2">
                <button class="btn btn-outline-primary btn-sm" data-bs-toggle="modal" data-bs-target="#registerVehicleModal"><i class="fas fa-car me-1"></i>Add Vehicle</button>
                <a href="bookservice.jsp" class="btn btn-primary btn-sm btn-auth"><i class="fas fa-calendar-check me-1"></i>Book Appointment</a>
            </div>
        </div>

        <!-- Navigation Tabs -->
        <ul class="nav nav-tabs border-0 mb-4" id="dashboardTabs" role="tablist">
            <li class="nav-item">
                <a href="?tab=overview" class="nav-link <%= "overview".equals(activeTab)?"active":"" %>"><i class="fas fa-chart-line me-1"></i>Overview</a>
            </li>
            <li class="nav-item">
                <a href="?tab=history" class="nav-link <%= "history".equals(activeTab)?"active":"" %>"><i class="fas fa-history me-1"></i>Service History</a>
            </li>
            <li class="nav-item">
                <a href="?tab=vehicles" class="nav-link <%= "vehicles".equals(activeTab)?"active":"" %>"><i class="fas fa-car-side me-1"></i>My Vehicles</a>
            </li>
            <li class="nav-item">
                <a href="?tab=profile" class="nav-link <%= "profile".equals(activeTab)?"active":"" %>"><i class="fas fa-user-gear me-1"></i>Settings</a>
            </li>
        </ul>

        <div class="tab-content">
            <!-- ═══════ OVERVIEW PANEL ═══════ -->
            <% if ("overview".equals(activeTab)) { %>
            <div class="tab-pane fade show active">
                <div class="row g-3 mb-4">
                    <div class="col-md-3">
                        <div class="dashboard-card text-center py-4">
                            <div class="fs-3 text-warning mb-2"><i class="fas fa-award"></i></div>
                            <h3 class="fw-bold text-white mb-1"><%= loyaltyPoints %></h3>
                            <p class="text-muted small mb-0">Loyalty Rewards Points</p>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="dashboard-card text-center py-4">
                            <div class="fs-3 text-primary mb-2"><i class="fas fa-car"></i></div>
                            <%
                                int vCount = 0;
                                try {
                                    PreparedStatement vps = conn.prepareStatement("SELECT COUNT(*) FROM vehicles WHERE customer_id=? AND status='Active'");
                                    vps.setInt(1, customerId);
                                    ResultSet vrs = vps.executeQuery();
                                    if(vrs.next()) vCount = vrs.getInt(1);
                                    vrs.close(); vps.close();
                                } catch(Exception ignore){}
                            %>
                            <h3 class="fw-bold text-white mb-1"><%= vCount %></h3>
                            <p class="text-muted small mb-0">Registered Vehicles</p>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="dashboard-card text-center py-4">
                            <div class="fs-3 text-success mb-2"><i class="fas fa-calendar-check"></i></div>
                            <%
                                int bCount = 0;
                                try {
                                    PreparedStatement bps = conn.prepareStatement("SELECT COUNT(*) FROM bookings WHERE customer_id=?");
                                    bps.setInt(1, customerId);
                                    ResultSet brs = bps.executeQuery();
                                    if(brs.next()) bCount = brs.getInt(1);
                                    brs.close(); bps.close();
                                } catch(Exception ignore){}
                            %>
                            <h3 class="fw-bold text-white mb-1"><%= bCount %></h3>
                            <p class="text-muted small mb-0">Total Bookings</p>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="dashboard-card text-center py-4">
                            <div class="fs-3 text-danger mb-2"><i class="fas fa-credit-card"></i></div>
                            <%
                                double dueAmt = 0;
                                try {
                                    PreparedStatement dps = conn.prepareStatement(
                                        "SELECT COALESCE(SUM(i.final_amount),0) FROM invoices i " +
                                        "JOIN bookings b ON i.booking_id=b.id " +
                                        "LEFT JOIN payments p ON p.invoice_id=i.id " +
                                        "WHERE b.customer_id=? AND (p.payment_status IS NULL OR p.payment_status='Pending')");
                                    dps.setInt(1, customerId);
                                    ResultSet drs = dps.executeQuery();
                                    if(drs.next()) dueAmt = drs.getDouble(1);
                                    drs.close(); dps.close();
                                } catch(Exception ignore){}
                            %>
                            <h3 class="fw-bold text-white mb-1">₹<%= String.format("%.2f", dueAmt) %></h3>
                            <p class="text-muted small mb-0">Pending Due Amount</p>
                        </div>
                    </div>
                </div>

                <div class="row g-4">
                    <div class="col-md-6">
                        <div class="dashboard-card">
                            <h6 class="fw-bold mb-3 text-white"><i class="fas fa-bell me-2 text-primary"></i>Live Updates & Notifications</h6>
                            <div style="max-height:280px; overflow-y:auto;">
                            <%
                                try {
                                    PreparedStatement nps = conn.prepareStatement(
                                        "SELECT * FROM notifications WHERE user_id=(SELECT user_id FROM customers WHERE id=?) ORDER BY sent_at DESC LIMIT 5");
                                    nps.setInt(1, customerId);
                                    ResultSet nrs = nps.executeQuery();
                                    boolean hasNotif = false;
                                    while (nrs.next()) {
                                        hasNotif = true;
                            %>
                                    <div class="p-2 border-bottom" style="border-color:var(--border-subtle) !important;">
                                        <div class="d-flex justify-content-between">
                                            <span class="fw-bold small text-white"><%= nrs.getString("title") %></span>
                                            <span class="text-muted" style="font-size:0.7rem;"><%= nrs.getTimestamp("sent_at") %></span>
                                        </div>
                                        <p class="text-muted small mb-0"><%= nrs.getString("message") %></p>
                                    </div>
                            <%
                                    }
                                    if (!hasNotif) {
                                        out.print("<p class='text-muted small mb-0'>No new notifications.</p>");
                                    }
                                    nrs.close(); nps.close();
                                } catch(Exception ignore){}
                            %>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="dashboard-card">
                            <h6 class="fw-bold mb-3 text-white"><i class="fas fa-wrench me-2 text-success"></i>Current Active Service</h6>
                            <%
                                try {
                                    PreparedStatement aps = conn.prepareStatement(
                                        "SELECT b.booking_uid, b.status, s.service_name, v.brand, v.model FROM bookings b " +
                                        "JOIN services s ON b.service_id=s.id JOIN vehicles v ON b.vehicle_id=v.id " +
                                        "WHERE b.customer_id=? AND b.status NOT IN ('Completed','Delivered','Cancelled') LIMIT 1");
                                    aps.setInt(1, customerId);
                                    ResultSet ars = aps.executeQuery();
                                    if (ars.next()) {
                            %>
                                    <div class="p-3 bg-light rounded text-center">
                                        <span class="badge-status badge-progress mb-2"><%= ars.getString("status") %></span>
                                        <h5 class="fw-bold text-white mb-1"><%= ars.getString("brand") %> <%= ars.getString("model") %></h5>
                                        <p class="text-muted small mb-2"><%= ars.getString("service_name") %></p>
                                        <a href="?tab=history" class="btn btn-xs btn-outline-primary"><i class="fas fa-search me-1"></i>Track Progress</a>
                                    </div>
                            <%
                                    } else {
                                        out.print("<div class='text-center py-4'><i class='fas fa-car-burst text-muted fa-2x mb-2'></i><p class='text-muted small mb-0'>No active repairs currently in progress.</p></div>");
                                    }
                                    ars.close(); aps.close();
                                } catch(Exception ignore){}
                            %>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>

            <!-- ═══════ SERVICE HISTORY PANEL ═══════ -->
            <% if ("history".equals(activeTab)) { %>
            <div class="tab-pane show active">
                <div class="dashboard-card p-0" style="overflow-x:auto;">
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Booking#</th>
                                <th>Vehicle</th>
                                <th>Service Type</th>
                                <th>Service Date</th>
                                <th>Final Due</th>
                                <th>Payment</th>
                                <th>Job Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            try {
                                String query = "SELECT b.id, b.booking_uid, b.booking_date, b.time_slot, b.status AS service_status, " +
                                               "v.brand, v.model, v.license_plate, s.service_name, " +
                                               "i.id AS invoice_id, i.final_amount, i.pdf_path, COALESCE(p.payment_status, 'Pending') AS payment_status " +
                                               "FROM bookings b " +
                                               "JOIN vehicles v ON b.vehicle_id = v.id " +
                                               "JOIN services s ON b.service_id = s.id " +
                                               "LEFT JOIN invoices i ON b.id = i.booking_id " +
                                               "LEFT JOIN payments p ON i.id = p.invoice_id " +
                                               "WHERE b.customer_id = ? " +
                                               "ORDER BY b.booking_date DESC";
                                pstmt = conn.prepareStatement(query);
                                pstmt.setInt(1, customerId);
                                rs = pstmt.executeQuery();

                                boolean hasHistory = false;
                                while (rs.next()) {
                                    hasHistory = true;
                                    int bookingId = rs.getInt("id");
                                    int invoiceId = rs.getInt("invoice_id");
                                    String pStatus = rs.getString("payment_status");
                                    String sStatus = rs.getString("service_status");
                                    double amount = rs.getDouble("final_amount");
                                    String pdfPath = rs.getString("pdf_path");

                                    String pBadge = "Paid".equalsIgnoreCase(pStatus) ? "badge-completed" : "Pending".equalsIgnoreCase(pStatus) ? "badge-pending" : "badge-progress";
                                    String sBadge = ("Completed".equalsIgnoreCase(sStatus) || "Delivered".equalsIgnoreCase(sStatus)) ? "badge-completed" : "Cancelled".equalsIgnoreCase(sStatus) ? "badge-due" : "badge-progress";
                        %>
                            <tr>
                                <td><code style="color:var(--primary-light);"><%= rs.getString("booking_uid") %></code></td>
                                <td><strong style="color:var(--text-white);"><%= rs.getString("brand") %> <%= rs.getString("model") %></strong><br><small class="text-muted"><%= rs.getString("license_plate") %></small></td>
                                <td><%= rs.getString("service_name") %></td>
                                <td><%= rs.getDate("booking_date") %><br><small class="text-muted"><%= rs.getString("time_slot") %></small></td>
                                <td><strong>₹<%= String.format("%.2f", amount) %></strong></td>
                                <td>
                                    <span class="badge-status <%= pBadge %>"><%= pStatus %></span>
                                    <% if ("Pending".equalsIgnoreCase(pStatus) && amount > 0) { %>
                                        <button class="btn btn-xs btn-outline-success ms-1 py-0 px-1 font-semibold" data-bs-toggle="modal" data-bs-target="#payModal-<%= bookingId %>" style="font-size:0.75rem;">Pay</button>
                                    <% } %>
                                </td>
                                <td><span class="badge-status <%= sBadge %>"><%= sStatus %></span></td>
                                <td>
                                    <div class="d-flex gap-1">
                                        <button class="btn btn-sm btn-outline-info py-1" data-bs-toggle="collapse" data-bs-target="#details-<%= bookingId %>" title="View Work Timelines & Photos"><i class="fas fa-search me-1"></i>Work Details</button>
                                        <% if ("Completed".equalsIgnoreCase(sStatus) || "Delivered".equalsIgnoreCase(sStatus)) { %>
                                            <button class="btn btn-sm btn-outline-warning py-1" data-bs-toggle="modal" data-bs-target="#reviewModal-<%= bookingId %>"><i class="fas fa-star me-1"></i>Review</button>
                                        <% } %>
                                        <% if (pdfPath != null) { %>
                                            <a href="<%= pdfPath %>" target="_blank" class="btn btn-sm btn-outline-success py-1"><i class="fas fa-file-pdf"></i> Invoice</a>
                                        <% } %>
                                    </div>
                                </td>
                            </tr>

                            <!-- Details Timeline Collapse Row -->
                            <tr class="collapse bg-light" id="details-<%= bookingId %>">
                                <td colspan="8" class="p-4 border-bottom">
                                    <div class="row">
                                        <div class="col-md-7 border-end" style="border-color:var(--border-subtle) !important;">
                                            <h6 class="fw-bold text-primary mb-3"><i class="fas fa-stream me-1"></i>Active Job Timeline & Updates</h6>
                                            <div class="timeline">
                                                <%
                                                    Connection conn2 = null;
                                                    PreparedStatement ps2 = null;
                                                    ResultSet rs2 = null;
                                                    try {
                                                        conn2 = DBUtil.getConnection();
                                                        String tQuery = "SELECT js.*, ji.image_url, ji.type AS img_type FROM job_stages js " +
                                                                               "LEFT JOIN job_images ji ON js.id = ji.job_stage_id " +
                                                                               "WHERE js.booking_id = ? ORDER BY js.logged_at DESC";
                                                        ps2 = conn2.prepareStatement(tQuery);
                                                        ps2.setInt(1, bookingId);
                                                        rs2 = ps2.executeQuery();
                                                        boolean hasTimeline = false;
                                                        while (rs2.next()) {
                                                            hasTimeline = true;
                                                %>
                                                            <div class="timeline-item">
                                                                <div class="d-flex justify-content-between align-items-center">
                                                                    <strong class="text-white small"><%= rs2.getString("stage_name") %></strong>
                                                                    <span class="text-muted" style="font-size:0.7rem;"><%= rs2.getTimestamp("logged_at") %></span>
                                                                </div>
                                                                <p class="text-muted small mb-1"><%= rs2.getString("description") %></p>
                                                                <% if (rs2.getString("image_url") != null) { %>
                                                                    <div>
                                                                        <span class="badge bg-secondary mb-1" style="font-size:0.6rem;"><%= rs2.getString("img_type") %> PHOTO</span><br/>
                                                                        <img src="<%= rs2.getString("image_url") %>" class="proof-img" alt="Work proof image">
                                                                    </div>
                                                                <% } %>
                                                            </div>
                                                <%
                                                        }
                                                        if (!hasTimeline) {
                                                            out.print("<p class='text-muted small'>No progress stages logged yet by the technician. Initial check pending.</p>");
                                                        }
                                                    } catch (Exception ignore) {
                                                    } finally {
                                                        if (rs2 != null) rs2.close();
                                                        if (ps2 != null) ps2.close();
                                                        if (conn2 != null) conn2.close();
                                                    }
                                                %>
                                            </div>
                                        </div>
                                        <div class="col-md-5">
                                            <h6 class="fw-bold text-primary mb-3"><i class="fas fa-receipt me-1"></i>Invoice Breakdown</h6>
                                            <ul class="list-group list-group-flush bg-transparent small text-muted">
                                                <li class="list-group-item d-flex justify-content-between bg-transparent"><span>Service cost:</span><span class="text-white">₹<%= String.format("%.2f", amount / 1.18) %></span></li>
                                                <li class="list-group-item d-flex justify-content-between bg-transparent"><span>GST (18%):</span><span class="text-white">₹<%= String.format("%.2f", amount - (amount / 1.18)) %></span></li>
                                                <li class="list-group-item d-flex justify-content-between bg-transparent fw-bold text-white"><span>Grand Total:</span><span class="text-success">₹<%= String.format("%.2f", amount) %></span></li>
                                            </ul>
                                        </div>
                                    </div>
                                </td>
                            </tr>

                            <!-- Review Modal -->
                            <div class="modal fade" id="reviewModal-<%= bookingId %>" tabindex="-1"><div class="modal-dialog"><div class="modal-content">
                                <div class="modal-header"><h6 class="modal-title fw-bold">Leave a Review</h6><button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button></div>
                                <form action="SubmitReviewServlet" method="post">
                                <input type="hidden" name="bookingId" value="<%= bookingId %>">
                                <div class="modal-body">
                                    <div class="mb-3">
                                        <label class="form-label">Rating</label>
                                        <select class="form-select" name="rating" required>
                                            <option value="5">⭐⭐⭐⭐⭐ (5/5)</option>
                                            <option value="4">⭐⭐⭐⭐ (4/5)</option>
                                            <option value="3">⭐⭐⭐ (3/5)</option>
                                            <option value="2">⭐⭐ (2/5)</option>
                                            <option value="1">⭐ (1/5)</option>
                                        </select>
                                    </div>
                                    <div class="mb-3"><label class="form-label">Your Review</label><textarea class="form-control" name="comment" rows="3" required placeholder="Tell us how the service was..."></textarea></div>
                                </div>
                                <div class="modal-footer"><button type="submit" class="btn btn-auth"><i class="fas fa-paper-plane me-1"></i>Submit Review</button></div>
                                </form>
                            </div></div></div>

                            <!-- Pay Simulation Modal -->
                            <% if ("Pending".equalsIgnoreCase(pStatus) && amount > 0) { %>
                            <div class="modal fade" id="payModal-<%= bookingId %>" tabindex="-1"><div class="modal-dialog modal-dialog-centered modal-sm"><div class="modal-content">
                                <div class="modal-header"><h6 class="modal-title fw-bold">Invoice Payment</h6><button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button></div>
                                <div class="modal-body p-3">
                                    <form action="PayInvoiceServlet" method="post">
                                        <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                                        <input type="hidden" name="invoiceId" value="<%= invoiceId %>">
                                        <p class="text-muted small text-center mb-1">Total Amount to Pay:</p>
                                        <h4 class="text-center fw-bold text-success mb-3">₹<%= String.format("%.2f", amount) %></h4>
                                        <div class="mb-3">
                                            <label class="form-label small">Payment Method</label>
                                            <select name="paymentMethod" class="form-select form-select-sm" required>
                                                <option value="UPI">UPI (GPay/PhonePe)</option>
                                                <option value="Card">Credit / Debit Card</option>
                                                <option value="Net Banking">Net Banking</option>
                                            </select>
                                        </div>
                                        <button type="submit" class="btn btn-success btn-sm w-100 py-2 font-semibold">Simulate Pay Now</button>
                                    </form>
                                </div>
                            </div></div></div>
                            <% } %>

                        <%
                                }
                                if (!hasHistory) {
                                    out.print("<tr><td colspan='8' class='text-center py-5'><p class='text-muted mb-0'>No service records found.</p></td></tr>");
                                }
                            } catch(Exception e) { e.printStackTrace(); }
                        %>
                        </tbody>
                    </table>
                </div>
            </div>
            <% } %>

            <!-- ═══════ VEHICLES PANEL ═══════ -->
            <% if ("vehicles".equals(activeTab)) { %>
            <div class="tab-pane show active">
                <div class="row g-4">
                    <%
                        try {
                            String query = "SELECT * FROM vehicles WHERE customer_id = ? AND status = 'Active'";
                            pstmt = conn.prepareStatement(query);
                            pstmt.setInt(1, customerId);
                            rs = pstmt.executeQuery();

                            boolean hasVehicles = false;
                            while (rs.next()) {
                                hasVehicles = true;
                                int vehicleId = rs.getInt("id");
                                String brand = rs.getString("brand");
                                String model = rs.getString("model");
                                String plate = rs.getString("license_plate");
                                String vin = rs.getString("vin");
                                String fuelType = rs.getString("fuel_type");
                                int mileage = rs.getInt("mileage");
                                String engineNo = rs.getString("engine_number");
                                String transmission = rs.getString("transmission");
                                Date insExpiry = rs.getDate("insurance_expiry");
                                Date pucExpiry = rs.getDate("puc_expiry");
                                Date warrantyExpiry = rs.getDate("warranty_expiry");

                                boolean insWarning = insExpiry != null && insExpiry.before(new Date(System.currentTimeMillis() + 14L * 24 * 60 * 60 * 1000));
                                boolean pucWarning = pucExpiry != null && pucExpiry.before(new Date(System.currentTimeMillis() + 7L * 24 * 60 * 60 * 1000));
                    %>
                    <div class="col-md-4">
                        <div class="card service-card h-100 p-4 border shadow-sm" style="background:var(--bg-card); border-color:var(--border-subtle) !important;">
                            <div class="d-flex justify-content-between align-items-center mb-3">
                                <h5 class="fw-bold mb-0 text-white"><%= brand %> <%= model %></h5>
                                <span class="badge bg-secondary"><%= fuelType %></span>
                            </div>
                            <p class="text-muted small mb-2"><i class="fas fa-id-card me-1"></i> Plate: <strong><%= plate %></strong></p>
                            <p class="text-muted small mb-2"><i class="fas fa-barcode me-1"></i> VIN: <span class="text-uppercase"><%= vin != null ? vin : "—" %></span></p>
                            <p class="text-muted small mb-2"><i class="fas fa-microchip me-1"></i> Engine#: <span class="text-uppercase"><%= engineNo != null ? engineNo : "—" %></span></p>
                            <p class="text-muted small mb-2"><i class="fas fa-gears me-1"></i> Transmission: <%= transmission %></p>
                            <p class="text-muted small mb-3"><i class="fas fa-tachometer-alt me-1"></i> Mileage: <%= mileage %> km</p>

                            <div class="border-top pt-3" style="border-color:var(--border-subtle) !important;">
                                <div class="d-flex justify-content-between align-items-center mb-1">
                                    <span class="text-muted small">Insurance Expiry:</span>
                                    <span class="badge <%= insWarning ? "bg-danger" : "bg-success" %>"><%= insExpiry != null ? insExpiry.toString() : "N/A" %></span>
                                </div>
                                <div class="d-flex justify-content-between align-items-center mb-1">
                                    <span class="text-muted small">PUC Expiry:</span>
                                    <span class="badge <%= pucWarning ? "bg-danger" : "bg-success" %>"><%= pucExpiry != null ? pucExpiry.toString() : "N/A" %></span>
                                </div>
                                <div class="d-flex justify-content-between align-items-center mb-3">
                                    <span class="text-muted small">Warranty Expiry:</span>
                                    <span class="badge bg-secondary"><%= warrantyExpiry != null ? warrantyExpiry.toString() : "N/A" %></span>
                                </div>
                            </div>
                            <div class="d-flex gap-2 mt-auto">
                                <button class="btn btn-xs btn-outline-primary w-50" data-bs-toggle="modal" data-bs-target="#editVehicleModal-<%= vehicleId %>"><i class="fas fa-edit me-1"></i>Edit</button>
                                <form action="EditVehicleServlet" method="post" class="w-50" onsubmit="return confirm('Remove this vehicle?');">
                                    <input type="hidden" name="action" value="delete"><input type="hidden" name="vehicleId" value="<%= vehicleId %>">
                                    <button type="submit" class="btn btn-xs btn-outline-danger w-100"><i class="fas fa-trash-can me-1"></i>Remove</button>
                                </form>
                            </div>
                        </div>
                    </div>

                    <!-- Edit Vehicle Modal -->
                    <div class="modal fade" id="editVehicleModal-<%= vehicleId %>" tabindex="-1"><div class="modal-dialog"><div class="modal-content">
                        <div class="modal-header"><h6 class="modal-title fw-bold">Edit Vehicle Details</h6><button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button></div>
                        <form action="EditVehicleServlet" method="post">
                        <input type="hidden" name="action" value="edit"><input type="hidden" name="vehicleId" value="<%= vehicleId %>">
                        <div class="modal-body">
                            <div class="mb-3"><label class="form-label">License Plate</label><input type="text" class="form-control" name="licensePlate" value="<%= plate %>" required></div>
                            <div class="row">
                                <div class="col-md-6 mb-3"><label class="form-label">Brand</label><input type="text" class="form-control" name="brand" value="<%= brand %>" required></div>
                                <div class="col-md-6 mb-3"><label class="form-label">Model</label><input type="text" class="form-control" name="model" value="<%= model %>" required></div>
                            </div>
                            <div class="row">
                                <div class="col-md-6 mb-3"><label class="form-label">Fuel Type</label>
                                    <select class="form-select" name="fuelType">
                                        <option value="Petrol" <%= "Petrol".equals(fuelType)?"selected":"" %>>Petrol</option>
                                        <option value="Diesel" <%= "Diesel".equals(fuelType)?"selected":"" %>>Diesel</option>
                                        <option value="CNG" <%= "CNG".equals(fuelType)?"selected":"" %>>CNG</option>
                                        <option value="Electric" <%= "Electric".equals(fuelType)?"selected":"" %>>Electric</option>
                                        <option value="Hybrid" <%= "Hybrid".equals(fuelType)?"selected":"" %>>Hybrid</option>
                                    </select>
                                </div>
                                <div class="col-md-6 mb-3"><label class="form-label">Odometer (km)</label><input type="number" class="form-control" name="mileage" value="<%= mileage %>" required></div>
                            </div>
                            <div class="row">
                                <div class="col-md-6 mb-3"><label class="form-label">Engine Number</label><input type="text" class="form-control" name="engineNumber" value="<%= engineNo != null ? engineNo : "" %>"></div>
                                <div class="col-md-6 mb-3"><label class="form-label">Transmission</label>
                                    <select class="form-select" name="transmission">
                                        <option value="Manual" <%= "Manual".equals(transmission)?"selected":"" %>>Manual</option>
                                        <option value="Automatic" <%= "Automatic".equals(transmission)?"selected":"" %>>Automatic</option>
                                        <option value="CVT" <%= "CVT".equals(transmission)?"selected":"" %>>CVT</option>
                                    </select>
                                </div>
                            </div>
                            <div class="mb-3"><label class="form-label">Insurance Policy Number</label><input type="text" class="form-control" name="insurancePolicyNo" value="<%= rs.getString("insurance_policy_no") != null ? rs.getString("insurance_policy_no") : "" %>"></div>
                            <div class="row">
                                <div class="col-md-6 mb-3"><label class="form-label">Insurance Expiry</label><input type="date" class="form-control" name="insuranceExpiry" value="<%= insExpiry != null ? insExpiry.toString() : "" %>"></div>
                                <div class="col-md-6 mb-3"><label class="form-label">PUC Expiry</label><input type="date" class="form-control" name="pucExpiry" value="<%= pucExpiry != null ? pucExpiry.toString() : "" %>"></div>
                            </div>
                            <div class="mb-3"><label class="form-label">Warranty Expiry</label><input type="date" class="form-control" name="warrantyExpiry" value="<%= warrantyExpiry != null ? warrantyExpiry.toString() : "" %>"></div>
                        </div>
                        <div class="modal-footer"><button type="submit" class="btn btn-auth"><i class="fas fa-save me-1"></i>Save Changes</button></div>
                        </form>
                    </div></div></div>
                    <%
                            }
                            if (!hasVehicles) {
                                out.print("<div class='col-12 text-center py-5'><p class='text-muted mb-0'>No vehicles registered.</p></div>");
                            }
                        } catch(Exception e) { e.printStackTrace(); }
                    %>
                </div>
            </div>
            <% } %>

            <!-- ═══════ PROFILE / SETTINGS PANEL ═══════ -->
            <% if ("profile".equals(activeTab)) { %>
            <div class="tab-pane show active">
                <div class="row g-4">
                    <div class="col-md-6">
                        <div class="dashboard-card">
                            <h5 class="fw-bold mb-3 text-white"><i class="fas fa-user-edit me-2"></i>Update Profile Details</h5>
                            <form action="UpdateProfileServlet" method="post">
                                <input type="hidden" name="action" value="editProfile">
                                <div class="mb-3"><label class="form-label">Full Name</label><input type="text" class="form-control" name="name" value="<%= customerName %>" required></div>
                                <div class="mb-3"><label class="form-label">Phone Number</label><input type="text" class="form-control" name="phone" value="<%= customerPhone != null ? customerPhone : "" %>" required></div>
                                <div class="mb-3"><label class="form-label">Address</label><textarea class="form-control" name="address" rows="3" required><%= customerAddress != null ? customerAddress : "" %></textarea></div>
                                <div class="mb-3"><label class="form-label">Emergency Contact Phone</label><input type="text" class="form-control" name="emergencyContact" value="<%= emergencyContact != null ? emergencyContact : "" %>"></div>
                                <button type="submit" class="btn btn-auth w-100 py-2"><i class="fas fa-save me-1"></i>Save Profile</button>
                            </form>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="dashboard-card">
                            <h5 class="fw-bold mb-3 text-white"><i class="fas fa-lock me-2"></i>Change Password</h5>
                            <form action="UpdateProfileServlet" method="post">
                                <input type="hidden" name="action" value="changePassword">
                                <div class="mb-3"><label class="form-label">Current Password</label><input type="password" class="form-control" name="currentPassword" required></div>
                                <div class="mb-3"><label class="form-label">New Password</label><input type="password" class="form-control" name="newPassword" minlength="6" required></div>
                                <button type="submit" class="btn btn-outline-primary w-100 py-2"><i class="fas fa-key me-1"></i>Update Password</button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
        </div>
    </div>

    <!-- Register Vehicle Modal -->
    <div class="modal fade" id="registerVehicleModal" tabindex="-1"><div class="modal-dialog modal-dialog-centered"><div class="modal-content">
        <div class="modal-header"><h5 class="modal-title fw-bold"><i class="fas fa-car me-2 text-primary"></i>Register Vehicle</h5><button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button></div>
        <div class="modal-body">
            <form action="RegisterVehicleServlet" method="post">
                <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                <div class="mb-3"><label class="form-label">License Plate Number</label><input type="text" class="form-control" name="licensePlate" placeholder="e.g. MP09AB1234" required></div>
                <div class="mb-3"><label class="form-label">VIN</label><input type="text" class="form-control" name="vin" placeholder="17-digit VIN code" maxlength="17" required></div>
                <div class="row">
                    <div class="col-md-6 mb-3"><label class="form-label">Brand</label><input type="text" class="form-control" name="brand" placeholder="e.g. Toyota" required></div>
                    <div class="col-md-6 mb-3"><label class="form-label">Model</label><input type="text" class="form-control" name="model" placeholder="e.g. Fortuner" required></div>
                </div>
                <div class="row">
                    <div class="col-md-6 mb-3">
                        <label class="form-label">Fuel Type</label>
                        <select class="form-select" name="fuelType" required>
                            <option value="Petrol">Petrol</option>
                            <option value="Diesel">Diesel</option>
                            <option value="CNG">CNG</option>
                            <option value="Electric">Electric</option>
                            <option value="Hybrid">Hybrid</option>
                        </select>
                    </div>
                    <div class="col-md-6 mb-3"><label class="form-label">Odometer (km)</label><input type="number" class="form-control" name="mileage" min="0" required></div>
                </div>
                <button type="submit" class="btn btn-auth w-100 py-2 mt-3"><i class="fas fa-plus me-1"></i>Register Vehicle</button>
            </form>
        </div>
    </div></div></div>

    <!-- Footer -->
    <footer class="text-white text-center py-4 mt-5">
        <p class="mb-0 opacity-50">&copy; 2025 ServicePilot. All Rights Reserved.</p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
<%
    if (rs != null) try { rs.close(); } catch(Exception ig) {}
    if (pstmt != null) try { pstmt.close(); } catch(Exception ig) {}
    if (conn != null) try { conn.close(); } catch(Exception ig) {}
%>
