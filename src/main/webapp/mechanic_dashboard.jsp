<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vehicleservice.util.DBUtil, java.sql.*" %>
<%
    String adminEmail = (String) session.getAttribute("adminEmail");
    Integer adminRoleId = (Integer) session.getAttribute("adminRoleId");
    Integer mechanicId = (Integer) session.getAttribute("mechanicId");
    String csrfToken = (String) session.getAttribute("csrfToken");
    if (csrfToken == null) csrfToken = "";

    // Guard: role 4 is mechanic, role 1 is admin
    if (adminEmail == null || adminRoleId == null || adminRoleId != 4 || mechanicId == null) {
        response.sendRedirect("admin_login.jsp?error=Access+Denied.+Please+login+as+technician");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    String specialization = "";
    double rating = 5.0;
    int completedCount = 0;
    int activeCount = 0;

    try {
        conn = DBUtil.getConnection();
        // Fetch mechanic metrics
        PreparedStatement mps = conn.prepareStatement("SELECT specialization, rating FROM mechanics WHERE id = ?");
        mps.setInt(1, mechanicId);
        ResultSet mrs = mps.executeQuery();
        if (mrs.next()) {
            specialization = mrs.getString("specialization");
            rating = mrs.getDouble("rating");
        }
        mrs.close(); mps.close();

        // Active jobs count
        PreparedStatement acPs = conn.prepareStatement("SELECT COUNT(*) FROM bookings WHERE mechanic_id = ? AND status NOT IN ('Completed','Delivered','Cancelled')");
        acPs.setInt(1, mechanicId);
        ResultSet acRs = acPs.executeQuery();
        if (acRs.next()) activeCount = acRs.getInt(1);
        acRs.close(); acPs.close();

        // Completed jobs count
        PreparedStatement ccPs = conn.prepareStatement("SELECT COUNT(*) FROM bookings WHERE mechanic_id = ? AND status IN ('Completed','Delivered')");
        ccPs.setInt(1, mechanicId);
        ResultSet ccRs = ccPs.executeQuery();
        if (ccRs.next()) completedCount = ccRs.getInt(1);
        ccRs.close(); ccPs.close();
    } catch(Exception e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Technician Console — ServicePilot</title>
    <meta name="csrf-token" content="<%= csrfToken %>">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="css/styles.css" rel="stylesheet">
    <style>
        .timeline {
            position: relative;
            padding-left: 24px;
            border-left: 2px solid rgba(99, 102, 241, 0.3);
        }
        .timeline-item {
            position: relative;
            margin-bottom: 20px;
        }
        .timeline-item::before {
            content: '';
            position: absolute;
            left: -31px;
            top: 5px;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background-color: var(--primary);
            border: 2px solid var(--bg-body);
        }
        .timeline-img {
            max-width: 120px;
            height: auto;
            border-radius: var(--radius-sm);
            margin-top: 8px;
            border: 1px solid var(--border-subtle);
            box-shadow: var(--shadow-md);
            transition: var(--transition);
        }
        .timeline-img:hover {
            transform: scale(1.05);
        }
    </style>
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container">
            <a class="navbar-brand" href="#">
                <i class="fas fa-wrench me-2" style="color:var(--primary-light);"></i>ServicePilot <span class="badge bg-warning text-dark ms-1" style="font-size:0.65rem;">TECHNICIAN</span>
            </a>
            <button class="navbar-toggler border-0" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav ms-auto align-items-center gap-2">
                    <li class="nav-item">
                        <span class="text-white small opacity-75"><i class="fas fa-user-cog me-1"></i><%= session.getAttribute("adminName") %></span>
                    </li>
                    <li class="nav-item">
                        <a href="AdminLogoutServlet" class="btn btn-sm btn-outline-danger px-3"><i class="fas fa-power-off me-1"></i>Logout</a>
                    </li>
                </ul>
            </div>
        </div>
    </nav>

    <div class="dashboard-container">
        <!-- Toast Alerts -->
        <% 
            String success = request.getParameter("success");
            String error = request.getParameter("error");
            if (success != null) { 
        %>
            <div class="alert alert-success alert-dismissible fade show py-2 small" role="alert">
                <i class="fas fa-check-circle me-2"></i><%= success %>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="alert"></button>
            </div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-danger alert-dismissible fade show py-2 small" role="alert">
                <i class="fas fa-exclamation-circle me-2"></i><%= error %>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="alert"></button>
            </div>
        <% } %>

        <!-- Overview banner -->
        <div class="dashboard-card mb-4 d-flex justify-content-between align-items-center flex-wrap gap-3">
            <div>
                <h4 class="fw-bold text-white mb-1">Technician Job Console</h4>
                <p class="text-muted small mb-0">Track active bookings, log progress checkpoints, and upload service proof photos.</p>
            </div>
            <div class="d-flex align-items-center gap-4">
                <div class="text-center">
                    <span class="text-muted small">Active Jobs</span>
                    <h5 class="fw-bold text-white mb-0"><%= activeCount %></h5>
                </div>
                <div class="text-center">
                    <span class="text-muted small">Completed</span>
                    <h5 class="fw-bold text-white mb-0"><%= completedCount %></h5>
                </div>
                <div class="text-center">
                    <span class="text-muted small">Rating</span>
                    <h5 class="fw-bold text-warning mb-0"><i class="fas fa-star me-1"></i><%= String.format("%.2f", rating) %></h5>
                </div>
            </div>
        </div>

        <div class="row g-4">
            <!-- Active Jobs Queue -->
            <div class="col-lg-8">
                <div class="dashboard-card">
                    <h5 class="fw-bold mb-4 text-white"><i class="fas fa-tasks text-primary me-2"></i>Assigned Queue</h5>
                    <%
                        try {
                            if (conn == null || conn.isClosed()) conn = DBUtil.getConnection();
                            String query = "SELECT b.id, b.booking_uid, b.booking_date, b.time_slot, b.status, b.additional_notes, " +
                                           "v.brand, v.model, v.license_plate, s.service_name " +
                                           "FROM bookings b " +
                                           "JOIN vehicles v ON b.vehicle_id = v.id " +
                                           "JOIN services s ON b.service_id = s.id " +
                                           "WHERE b.mechanic_id = ? AND b.status != 'Cancelled' " +
                                           "ORDER BY b.booking_date ASC";
                            pstmt = conn.prepareStatement(query);
                            pstmt.setInt(1, mechanicId);
                            rs = pstmt.executeQuery();

                            boolean hasJobs = false;
                            while (rs.next()) {
                                hasJobs = true;
                                int bId = rs.getInt("id");
                                String jobStatus = rs.getString("status");
                                String bbadge = ("Completed".equalsIgnoreCase(jobStatus) || "Delivered".equalsIgnoreCase(jobStatus)) ? "badge-completed" : "badge-pending";
                    %>
                    <div class="card p-3 border mb-4 shadow-sm" style="background:rgba(30,41,59,0.3); border-color:var(--border-subtle) !important;">
                        <div class="d-flex justify-content-between align-items-center mb-2 flex-wrap">
                            <div>
                                <span class="badge bg-secondary mb-1">ID: <%= rs.getString("booking_uid") %></span>
                                <h6 class="fw-bold text-white mb-0"><%= rs.getString("brand") %> <%= rs.getString("model") %> (<%= rs.getString("license_plate") %>)</h6>
                            </div>
                            <span class="badge-status <%= bbadge %>"><%= jobStatus %></span>
                        </div>

                        <div class="row mb-2">
                            <div class="col-sm-6 text-muted small"><i class="fas fa-tools me-1"></i><%= rs.getString("service_name") %></div>
                            <div class="col-sm-6 text-muted small text-sm-end"><i class="far fa-calendar-alt me-1"></i><%= rs.getDate("booking_date") %> (Slot: <%= rs.getString("time_slot") %>)</div>
                        </div>

                        <% if (rs.getString("additional_notes") != null && !rs.getString("additional_notes").trim().isEmpty()) { %>
                            <div class="p-2 mb-2 rounded small text-muted" style="background:var(--bg-elevated);">
                                <strong>Customer Notes:</strong> <%= rs.getString("additional_notes") %>
                            </div>
                        <% } %>

                        <!-- Action Form to log stages -->
                        <% if (!("Completed".equalsIgnoreCase(jobStatus) || "Delivered".equalsIgnoreCase(jobStatus))) { %>
                        <form action="UpdateJobStageServlet" method="post" enctype="multipart/form-data" class="mt-3 p-3 rounded border" style="background:var(--bg-elevated); border-color:var(--border-subtle) !important;">
                            <input type="hidden" name="csrfToken" value="<%= csrfToken %>">
                            <input type="hidden" name="bookingId" value="<%= bId %>">

                            <h6 class="fw-bold text-white mb-3" style="font-size:0.85rem;"><i class="fas fa-circle-plus me-1 text-primary"></i>Log Work Progress Checkpoint</h6>
                            <div class="row g-2 align-items-end">
                                <div class="col-md-3">
                                    <label class="form-label small" style="font-size:0.7rem;">Stage Name</label>
                                    <select name="stageName" class="form-select form-select-sm" required>
                                        <option value="Inspection">Inspection</option>
                                        <option value="Repair Started">Repair Started</option>
                                        <option value="In Progress">In Progress</option>
                                        <option value="Repair Completed">Repair Completed</option>
                                        <option value="Quality Check">Quality Check</option>
                                        <option value="Ready for Delivery">Ready for Delivery</option>
                                    </select>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label small" style="font-size:0.7rem;">Comments</label>
                                    <input type="text" name="description" class="form-control form-control-sm" placeholder="Checklist updates..." required>
                                </div>
                                <div class="col-md-3">
                                    <label class="form-label small" style="font-size:0.7rem;">Attach Proof Image</label>
                                    <input type="file" name="imageFile" class="form-control form-control-sm" accept="image/*">
                                </div>
                                <div class="col-md-2">
                                    <button type="submit" class="btn btn-sm btn-primary w-100 py-1 font-semibold">Update</button>
                                </div>
                            </div>
                        </form>
                        <% } %>

                        <!-- Job Stage Timeline History -->
                        <div class="timeline mt-3">
                            <h6 class="fw-bold text-muted mb-3" style="font-size:0.8rem;">Job Progress History</h6>
                            <%
                                Connection conn2 = null;
                                PreparedStatement pstmt2 = null;
                                ResultSet rs2 = null;
                                try {
                                    conn2 = DBUtil.getConnection();
                                    String timelineQuery = "SELECT * FROM job_stages WHERE booking_id = ? ORDER BY logged_at DESC";
                                    pstmt2 = conn2.prepareStatement(timelineQuery);
                                    pstmt2.setInt(1, bId);
                                    rs2 = pstmt2.executeQuery();
                                    boolean hasTimeline = false;
                                    while (rs2.next()) {
                                        hasTimeline = true;
                                        int stageId = rs2.getInt("id");
                            %>
                                        <div class="timeline-item">
                                            <div class="d-flex justify-content-between align-items-center">
                                                <strong class="text-white small"><%= rs2.getString("stage_name") %></strong>
                                                <span class="text-muted" style="font-size:0.7rem;"><%= rs2.getTimestamp("logged_at") %></span>
                                            </div>
                                            <p class="text-muted small mb-0"><%= rs2.getString("description") %></p>
                                            <%
                                                PreparedStatement pImg = null;
                                                ResultSet rImg = null;
                                                try {
                                                    pImg = conn2.prepareStatement("SELECT image_url, type FROM job_images WHERE job_stage_id=?");
                                                    pImg.setInt(1, stageId);
                                                    rImg = pImg.executeQuery();
                                                    if(rImg.next()){
                                            %>
                                                <div class="mt-1">
                                                    <span class="badge bg-secondary mb-1" style="font-size:0.6rem;"><%= rImg.getString("type") %> PHOTO</span><br/>
                                                    <img src="<%= rImg.getString("image_url") %>" class="timeline-img img-fluid" alt="proof photo">
                                                </div>
                                            <%
                                                    }
                                                } catch(Exception ig){} finally { if(rImg!=null) rImg.close(); if(pImg!=null) pImg.close(); }
                                            %>
                                        </div>
                            <%
                                    }
                                    if (!hasTimeline) {
                                        out.print("<p class='text-muted small mb-0'>No progress stages logged yet. Perform initial inspection to begin.</p>");
                                    }
                                } catch(Exception e) {
                                    e.printStackTrace();
                                } finally {
                                    if (rs2 != null) rs2.close();
                                    if (pstmt2 != null) pstmt2.close();
                                    if (conn2 != null) conn2.close();
                                }
                            %>
                        </div>
                    </div>
                    <%
                            }
                            if (!hasJobs) {
                                out.print("<div class='text-center py-5'><i class='fas fa-smile text-muted fa-3x mb-3'></i><h5 class='text-muted'>No assigned jobs</h5><p class='text-muted small'>Relax! You currently have no pending service bookings assigned to you.</p></div>");
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                        } finally {
                            if (rs != null) rs.close();
                            if (pstmt != null) pstmt.close();
                            if (conn != null) conn.close();
                        }
                    %>
                </div>
            </div>

            <!-- Profile / Specialization sidebar -->
            <div class="col-lg-4">
                <div class="dashboard-card">
                    <h5 class="fw-bold text-white mb-3"><i class="fas fa-id-badge text-warning me-2"></i>Profile Details</h5>
                    <div class="text-center py-4 border-bottom mb-4" style="border-color:var(--border-subtle) !important;">
                        <div style="width:64px; height:64px; border-radius:50%; background:linear-gradient(135deg, var(--accent), var(--primary)); display:inline-flex; align-items:center; justify-content:center; margin-bottom:12px;">
                            <i class="fas fa-user-gear text-white fa-lg"></i>
                        </div>
                        <h5 class="fw-bold text-white mb-1"><%= session.getAttribute("adminName") %></h5>
                        <span class="badge bg-warning text-dark">Senior Technician</span>
                    </div>

                    <p class="small text-muted mb-1">Specialization:</p>
                    <p class="fw-bold text-white mb-3"><%= specialization != null ? specialization : "General Auto Care" %></p>

                    <p class="small text-muted mb-1">Performance Score:</p>
                    <p class="fw-bold text-warning mb-0"><i class="fas fa-star me-1"></i><%= String.format("%.2f", rating) %> / 5.00</p>
                </div>
            </div>
        </div>
    </div>

    <!-- Footer -->
    <footer class="text-white text-center py-4 mt-5">
        <p class="mb-0 opacity-50">&copy; 2025 ServicePilot. All Rights Reserved.</p>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    <script>
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
