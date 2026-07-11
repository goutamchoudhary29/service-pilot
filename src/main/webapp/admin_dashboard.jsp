<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.vehicleservice.util.DBUtil" %>
<%
    // Guard
    HttpSession sess = request.getSession(false);
    if (sess == null || sess.getAttribute("adminRoleId") == null) {
        response.sendRedirect("admin_login.jsp?error=Access+Denied");
        return;
    }
    String adminName = (String) sess.getAttribute("adminName");
    if (adminName == null) adminName = "Admin";
    String activeTab = request.getParameter("tab");
    if (activeTab == null) activeTab = "dashboard";
    String successMsg = request.getParameter("success");
    String errorMsg = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Console — ServicePilot</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <link href="css/styles.css" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        .admin-sidebar{position:fixed;top:0;left:0;width:250px;height:100vh;background:rgba(11,15,25,0.98);border-right:1px solid var(--border-subtle);padding:20px 0;overflow-y:auto;z-index:100;}
        .admin-sidebar .brand{padding:0 20px 20px;border-bottom:1px solid var(--border-subtle);margin-bottom:12px;}
        .admin-sidebar .brand h5{margin:0;background:linear-gradient(135deg,#818cf8,#06b6d4);-webkit-background-clip:text;-webkit-text-fill-color:transparent;font-weight:800;}
        .admin-sidebar .brand small{color:var(--text-muted);font-size:0.7rem;}
        .sidebar-nav{list-style:none;padding:0;margin:0;}
        .sidebar-nav li a{display:flex;align-items:center;gap:12px;padding:10px 20px;color:var(--text-secondary);font-size:0.875rem;font-weight:500;transition:var(--transition);border-left:3px solid transparent;}
        .sidebar-nav li a:hover,.sidebar-nav li a.active{color:var(--text-white);background:rgba(99,102,241,0.08);border-left-color:var(--primary);}
        .sidebar-nav li a i{width:18px;text-align:center;font-size:0.9rem;}
        .sidebar-nav li a .badge{margin-left:auto;font-size:0.65rem;}
        .admin-main{margin-left:250px;padding:24px;min-height:100vh;position:relative;z-index:1;}
        .admin-topbar{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px;gap:16px;}
        .admin-topbar h4{margin:0;font-weight:700;color:var(--text-white);}
        .search-box{position:relative;width:320px;}
        .search-box input{background:rgba(30,41,59,0.5);border:1px solid var(--border-subtle);color:var(--text-white);border-radius:var(--radius-sm);padding:8px 12px 8px 36px;width:100%;font-size:0.85rem;}
        .search-box input:focus{border-color:var(--primary);box-shadow:0 0 0 2px rgba(99,102,241,0.15);outline:none;}
        .search-box i{position:absolute;left:12px;top:50%;transform:translateY(-50%);color:var(--text-muted);}
        .search-results{position:absolute;top:100%;left:0;right:0;background:var(--bg-surface);border:1px solid var(--border-subtle);border-radius:var(--radius-sm);max-height:300px;overflow-y:auto;display:none;z-index:50;}
        .search-results .sr-item{padding:10px 14px;border-bottom:1px solid var(--border-subtle);cursor:pointer;transition:var(--transition);}
        .search-results .sr-item:hover{background:rgba(99,102,241,0.05);}
        .search-results .sr-type{font-size:0.65rem;text-transform:uppercase;color:var(--primary-light);font-weight:700;}
        .search-results .sr-title{color:var(--text-white);font-size:0.85rem;}
        .search-results .sr-sub{color:var(--text-muted);font-size:0.75rem;}
        .metric-card{background:var(--bg-card);border:1px solid var(--border-subtle);border-radius:var(--radius);padding:20px;transition:var(--transition);}
        .metric-card:hover{border-color:rgba(99,102,241,0.25);box-shadow:0 0 20px rgba(99,102,241,0.08);}
        .metric-card .metric-icon{width:44px;height:44px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:1.1rem;}
        .metric-card .metric-value{font-size:1.6rem;font-weight:800;color:var(--text-white);margin:8px 0 2px;}
        .metric-card .metric-label{font-size:0.75rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:0.5px;}
        .tab-content-section{display:none;}
        .tab-content-section.active{display:block;}
        .data-table{width:100%;border-collapse:collapse;}
        .data-table th{background:rgba(30,41,59,0.6);color:var(--text-secondary);font-size:0.72rem;text-transform:uppercase;letter-spacing:0.5px;padding:12px 14px;font-weight:700;border-bottom:1px solid var(--border-subtle);}
        .data-table td{padding:12px 14px;font-size:0.85rem;color:var(--text-primary);border-bottom:1px solid var(--border-subtle);vertical-align:middle;}
        .data-table tr:hover td{background:rgba(99,102,241,0.03);}
        .action-btn{padding:3px 10px;font-size:0.72rem;border-radius:6px;font-weight:600;border:none;cursor:pointer;transition:var(--transition);}
        @media(max-width:992px){.admin-sidebar{width:60px;}.admin-sidebar .brand h5,.admin-sidebar .brand small,.sidebar-nav li a span,.sidebar-nav li a .badge{display:none;}.sidebar-nav li a{justify-content:center;padding:12px 0;}.admin-main{margin-left:60px;}}
    </style>
</head>
<body>
<!-- Sidebar -->
<aside class="admin-sidebar">
    <div class="brand">
        <h5><i class="fas fa-cogs me-2"></i>ServicePilot</h5>
        <small>Admin Console v2.0</small>
    </div>
    <ul class="sidebar-nav">
        <li><a href="?tab=dashboard" class="<%= "dashboard".equals(activeTab)?"active":"" %>"><i class="fas fa-th-large"></i><span>Dashboard</span></a></li>
        <li><a href="?tab=customers" class="<%= "customers".equals(activeTab)?"active":"" %>"><i class="fas fa-users"></i><span>Customers</span></a></li>
        <li><a href="?tab=mechanics" class="<%= "mechanics".equals(activeTab)?"active":"" %>"><i class="fas fa-wrench"></i><span>Mechanics</span></a></li>
        <li><a href="?tab=bookings" class="<%= "bookings".equals(activeTab)?"active":"" %>"><i class="fas fa-calendar-check"></i><span>Bookings</span></a></li>
        <li><a href="?tab=payments" class="<%= "payments".equals(activeTab)?"active":"" %>"><i class="fas fa-credit-card"></i><span>Payments</span></a></li>
        <li><a href="?tab=invoices" class="<%= "invoices".equals(activeTab)?"active":"" %>"><i class="fas fa-file-invoice"></i><span>Invoices</span></a></li>
        <li><a href="?tab=reviews" class="<%= "reviews".equals(activeTab)?"active":"" %>"><i class="fas fa-star"></i><span>Reviews</span></a></li>
        <li><a href="?tab=inventory" class="<%= "inventory".equals(activeTab)?"active":"" %>"><i class="fas fa-boxes-stacked"></i><span>Inventory</span></a></li>
        <li><a href="?tab=services" class="<%= "services".equals(activeTab)?"active":"" %>"><i class="fas fa-tools"></i><span>Services</span></a></li>
        <li><a href="?tab=suppliers" class="<%= "suppliers".equals(activeTab)?"active":"" %>"><i class="fas fa-truck"></i><span>Suppliers</span></a></li>
        <li><a href="?tab=contacts" class="<%= "contacts".equals(activeTab)?"active":"" %>"><i class="fas fa-envelope"></i><span>Messages</span></a></li>
        <li style="margin-top:auto;border-top:1px solid var(--border-subtle);padding-top:8px;">
            <a href="AdminLogoutServlet"><i class="fas fa-sign-out-alt"></i><span>Logout</span></a>
        </li>
    </ul>
</aside>

<!-- Main Content -->
<main class="admin-main">
    <!-- Top Bar -->
    <div class="admin-topbar">
        <h4><i class="fas fa-shield-alt me-2 text-warning"></i><%= adminName %>'s Console</h4>
        <div class="search-box">
            <i class="fas fa-search"></i>
            <input type="text" id="globalSearch" placeholder="Search customers, vehicles, bookings..." autocomplete="off">
            <div class="search-results" id="searchResults"></div>
        </div>
        <div class="d-flex align-items-center gap-3">
            <span class="text-muted small"><i class="fas fa-clock me-1"></i><span id="liveTime"></span></span>
            <a href="AdminLogoutServlet" class="btn btn-sm btn-outline-danger"><i class="fas fa-power-off me-1"></i>Logout</a>
        </div>
    </div>

    <!-- Alerts -->
    <% if (successMsg != null) { %>
    <div class="alert alert-success alert-dismissible fade show py-2 small" role="alert">
        <i class="fas fa-check-circle me-1"></i><%= successMsg %>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="alert"></button>
    </div>
    <% } %>
    <% if (errorMsg != null) { %>
    <div class="alert alert-danger alert-dismissible fade show py-2 small" role="alert">
        <i class="fas fa-exclamation-circle me-1"></i><%= errorMsg %>
        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="alert"></button>
    </div>
    <% } %>

    <!-- ═══════ DASHBOARD TAB ═══════ -->
    <div class="tab-content-section <%= "dashboard".equals(activeTab)?"active":"" %>" id="sec-dashboard">
        <div class="row g-3 mb-4" id="metricsGrid">
            <!-- Metrics injected by JS -->
        </div>
        <div class="row g-4">
            <div class="col-md-8">
                <div class="dashboard-card">
                    <h6 class="fw-bold mb-3" style="color:var(--text-white);">Monthly Revenue</h6>
                    <canvas id="revenueChart" height="100"></canvas>
                </div>
            </div>
            <div class="col-md-4">
                <div class="dashboard-card">
                    <h6 class="fw-bold mb-3" style="color:var(--text-white);">Booking Status</h6>
                    <canvas id="statusChart" height="200"></canvas>
                </div>
            </div>
        </div>
        <div class="dashboard-card mt-4">
            <h6 class="fw-bold mb-3" style="color:var(--text-white);"><i class="fas fa-history me-2"></i>Recent Activity</h6>
            <div id="activityFeed" style="max-height:300px;overflow-y:auto;"></div>
        </div>
    </div>

    <!-- ═══════ CUSTOMERS TAB ═══════ -->
    <div class="tab-content-section <%= "customers".equals(activeTab)?"active":"" %>" id="sec-customers">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h5 class="fw-bold mb-0" style="color:var(--text-white);"><i class="fas fa-users me-2"></i>Customer Management</h5>
            <input type="text" id="custSearch" class="form-control" style="max-width:250px;" placeholder="Search customers...">
        </div>
        <div class="dashboard-card p-0" style="overflow-x:auto;">
            <table class="data-table" id="custTable">
                <thead><tr><th>#</th><th>Name</th><th>Email</th><th>Phone</th><th>Status</th><th>Loyalty</th><th>Vehicles</th><th>Actions</th></tr></thead>
                <tbody>
                <%
                    Connection conn = null;
                    try { conn = DBUtil.getConnection();
                    PreparedStatement cps = conn.prepareStatement(
                        "SELECT u.id, u.name, u.email, u.phone, u.status, c.loyalty_points, c.address, c.emergency_contact, c.notes, " +
                        "(SELECT COUNT(*) FROM vehicles WHERE customer_id=c.id AND status='Active') AS vcount " +
                        "FROM users u JOIN customers c ON c.user_id=u.id ORDER BY u.id DESC");
                    ResultSet crs = cps.executeQuery();
                    int ci = 1;
                    while (crs.next()) {
                        String st = crs.getString("status");
                        String badge = "Active".equals(st) ? "badge-completed" : "badge-due";
                %>
                <tr>
                    <td><%= ci++ %></td>
                    <td><strong style="color:var(--text-white);"><%= crs.getString("name") %></strong></td>
                    <td><%= crs.getString("email") %></td>
                    <td><%= crs.getString("phone") %></td>
                    <td><span class="badge-status <%= badge %>"><%= st %></span></td>
                    <td><span class="text-warning"><i class="fas fa-coins me-1"></i><%= crs.getInt("loyalty_points") %></span></td>
                    <td><%= crs.getInt("vcount") %></td>
                    <td>
                        <button class="action-btn btn btn-sm btn-outline-primary" data-bs-toggle="modal" data-bs-target="#editCustModal"
                            onclick="fillCustEdit(<%= crs.getInt("id") %>,'<%= crs.getString("name").replace("'","\\'") %>','<%= crs.getString("email") %>','<%= crs.getString("phone") %>','<%= crs.getString("address") != null ? crs.getString("address").replace("'","\\'") : "" %>','<%= crs.getString("emergency_contact") != null ? crs.getString("emergency_contact") : "" %>')">
                            <i class="fas fa-edit"></i>
                        </button>
                        <% if ("Active".equals(st)) { %>
                        <form method="post" action="ManageCustomerServlet" style="display:inline;">
                            <input type="hidden" name="action" value="disable"><input type="hidden" name="userId" value="<%= crs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-danger" title="Disable"><i class="fas fa-ban"></i></button>
                        </form>
                        <% } else { %>
                        <form method="post" action="ManageCustomerServlet" style="display:inline;">
                            <input type="hidden" name="action" value="enable"><input type="hidden" name="userId" value="<%= crs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-primary" title="Enable"><i class="fas fa-check"></i></button>
                        </form>
                        <% } %>
                        <form method="post" action="ManageCustomerServlet" style="display:inline;" onsubmit="return confirm('Reset password to 123456?');">
                            <input type="hidden" name="action" value="resetPassword"><input type="hidden" name="userId" value="<%= crs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-primary" title="Reset Password"><i class="fas fa-key"></i></button>
                        </form>
                        <form method="post" action="ManageCustomerServlet" style="display:inline;" onsubmit="return confirm('Delete this customer permanently?');">
                            <input type="hidden" name="action" value="delete"><input type="hidden" name="userId" value="<%= crs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-danger" title="Delete"><i class="fas fa-trash"></i></button>
                        </form>
                    </td>
                </tr>
                <% } crs.close(); cps.close();
                } catch(Exception e) { e.printStackTrace(); }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ═══════ MECHANICS TAB ═══════ -->
    <div class="tab-content-section <%= "mechanics".equals(activeTab)?"active":"" %>" id="sec-mechanics">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h5 class="fw-bold mb-0" style="color:var(--text-white);"><i class="fas fa-wrench me-2"></i>Mechanic Management</h5>
            <button class="btn btn-sm btn-auth" data-bs-toggle="modal" data-bs-target="#addMechModal"><i class="fas fa-plus me-1"></i>Add Mechanic</button>
        </div>
        <div class="dashboard-card p-0" style="overflow-x:auto;">
            <table class="data-table">
                <thead><tr><th>#</th><th>Name</th><th>Email</th><th>Branch</th><th>Specialization</th><th>Rating</th><th>Salary</th><th>Status</th><th>Actions</th></tr></thead>
                <tbody>
                <%
                    try {
                    if (conn == null || conn.isClosed()) conn = DBUtil.getConnection();
                    PreparedStatement mps = conn.prepareStatement(
                        "SELECT e.id AS eid, u.name, u.email, u.phone, b.name AS bname, m.specialization, m.rating, e.salary, e.status, u.id AS uid " +
                        "FROM mechanics m JOIN employees e ON m.employee_id=e.id JOIN users u ON e.user_id=u.id JOIN branches b ON e.branch_id=b.id ORDER BY e.id DESC");
                    ResultSet mrs = mps.executeQuery();
                    int mi = 1;
                    while (mrs.next()) {
                        String mst = mrs.getString("status");
                        String mbadge = "Active".equals(mst) ? "badge-completed" : "badge-due";
                %>
                <tr>
                    <td><%= mi++ %></td>
                    <td><strong style="color:var(--text-white);"><%= mrs.getString("name") %></strong></td>
                    <td class="text-muted"><%= mrs.getString("email") %></td>
                    <td><%= mrs.getString("bname") %></td>
                    <td><span class="badge-status badge-progress"><%= mrs.getString("specialization") != null ? mrs.getString("specialization") : "General" %></span></td>
                    <td><i class="fas fa-star text-warning me-1"></i><%= mrs.getDouble("rating") %></td>
                    <td>&#8377;<%= String.format("%.0f", mrs.getDouble("salary")) %></td>
                    <td><span class="badge-status <%= mbadge %>"><%= mst %></span></td>
                    <td>
                        <% if ("Active".equals(mst)) { %>
                        <form method="post" action="ManageMechanicServlet" style="display:inline;">
                            <input type="hidden" name="action" value="deactivate"><input type="hidden" name="employeeId" value="<%= mrs.getInt("eid") %>">
                            <button class="action-btn btn btn-sm btn-outline-danger" title="Deactivate"><i class="fas fa-ban"></i></button>
                        </form>
                        <% } else { %>
                        <form method="post" action="ManageMechanicServlet" style="display:inline;">
                            <input type="hidden" name="action" value="activate"><input type="hidden" name="employeeId" value="<%= mrs.getInt("eid") %>">
                            <button class="action-btn btn btn-sm btn-outline-primary" title="Activate"><i class="fas fa-check"></i></button>
                        </form>
                        <% } %>
                        <form method="post" action="ManageMechanicServlet" style="display:inline;" onsubmit="return confirm('Delete this mechanic?');">
                            <input type="hidden" name="action" value="delete"><input type="hidden" name="employeeId" value="<%= mrs.getInt("eid") %>">
                            <button class="action-btn btn btn-sm btn-outline-danger" title="Delete"><i class="fas fa-trash"></i></button>
                        </form>
                    </td>
                </tr>
                <% } mrs.close(); mps.close();
                } catch(Exception e) { e.printStackTrace(); }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ═══════ BOOKINGS TAB ═══════ -->
    <div class="tab-content-section <%= "bookings".equals(activeTab)?"active":"" %>" id="sec-bookings">
        <h5 class="fw-bold mb-3" style="color:var(--text-white);"><i class="fas fa-calendar-check me-2"></i>Booking Management</h5>
        <div class="dashboard-card p-0" style="overflow-x:auto;">
            <table class="data-table">
                <thead><tr><th>ID</th><th>Customer</th><th>Vehicle</th><th>Service</th><th>Date</th><th>Mechanic</th><th>Status</th><th>Actions</th></tr></thead>
                <tbody>
                <%
                    try {
                    if (conn == null || conn.isClosed()) conn = DBUtil.getConnection();
                    PreparedStatement bkps = conn.prepareStatement(
                        "SELECT b.id, b.booking_uid, b.booking_date, b.time_slot, b.status, " +
                        "u.name AS cname, CONCAT(v.brand,' ',v.model) AS vname, v.license_plate, s.service_name, " +
                        "COALESCE(mu.name,'Unassigned') AS mname, b.mechanic_id " +
                        "FROM bookings b JOIN customers c ON b.customer_id=c.id JOIN users u ON c.user_id=u.id " +
                        "JOIN vehicles v ON b.vehicle_id=v.id JOIN services s ON b.service_id=s.id " +
                        "LEFT JOIN mechanics m ON b.mechanic_id=m.id LEFT JOIN employees e ON m.employee_id=e.id LEFT JOIN users mu ON e.user_id=mu.id " +
                        "ORDER BY b.id DESC");
                    ResultSet brs = bkps.executeQuery();
                    while (brs.next()) {
                        String bs = brs.getString("status");
                        String bbadge = "Pending".equals(bs) ? "badge-pending" :
                                        "Cancelled".equals(bs) ? "badge-due" :
                                        ("Completed".equals(bs) || "Delivered".equals(bs)) ? "badge-completed" : "badge-progress";
                %>
                <tr>
                    <td><code style="color:var(--primary-light);"><%= brs.getString("booking_uid") %></code></td>
                    <td style="color:var(--text-white);"><%= brs.getString("cname") %></td>
                    <td><%= brs.getString("vname") %><br><small class="text-muted"><%= brs.getString("license_plate") %></small></td>
                    <td><%= brs.getString("service_name") %></td>
                    <td><%= brs.getDate("booking_date") %><br><small class="text-muted"><%= brs.getString("time_slot") %></small></td>
                    <td><%= brs.getString("mname") %></td>
                    <td><span class="badge-status <%= bbadge %>"><%= bs %></span></td>
                    <td style="white-space:nowrap;">
                        <form method="post" action="ManageBookingServlet" style="display:inline;" class="d-inline-flex gap-1 align-items-center">
                            <input type="hidden" name="action" value="updateStatus"><input type="hidden" name="bookingId" value="<%= brs.getInt("id") %>">
                            <select name="status" class="form-select form-select-sm" style="width:130px;font-size:0.72rem;">
                                <% String[] statuses = {"Pending","Accepted","Inspection","Repair Started","In Progress","Repair Completed","Quality Check","Ready for Delivery","Delivered","Completed","Cancelled"};
                                   for (String st : statuses) { %>
                                <option value="<%= st %>" <%= st.equals(bs)?"selected":"" %>><%= st %></option>
                                <% } %>
                            </select>
                            <button class="action-btn btn btn-sm btn-outline-primary" title="Update"><i class="fas fa-save"></i></button>
                        </form>
                        <% if (!("Completed".equals(bs) || "Delivered".equals(bs) || "Cancelled".equals(bs))) { %>
                        <a href="GenerateInvoiceServlet?bookingId=<%= brs.getInt("id") %>" class="action-btn btn btn-sm btn-outline-primary" title="Invoice"><i class="fas fa-file-invoice"></i></a>
                        <% } %>
                        <form method="post" action="ManageBookingServlet" style="display:inline;" onsubmit="return confirm('Delete this booking?');">
                            <input type="hidden" name="action" value="delete"><input type="hidden" name="bookingId" value="<%= brs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-danger" title="Delete"><i class="fas fa-trash"></i></button>
                        </form>
                    </td>
                </tr>
                <% } brs.close(); bkps.close();
                } catch(Exception e) { e.printStackTrace(); }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ═══════ PAYMENTS TAB ═══════ -->
    <div class="tab-content-section <%= "payments".equals(activeTab)?"active":"" %>" id="sec-payments">
        <h5 class="fw-bold mb-3" style="color:var(--text-white);"><i class="fas fa-credit-card me-2"></i>Payment Management</h5>
        <div class="dashboard-card p-0" style="overflow-x:auto;">
            <table class="data-table">
                <thead><tr><th>Payment#</th><th>Booking</th><th>Customer</th><th>Amount</th><th>Paid</th><th>Method</th><th>Status</th><th>TXN ID</th><th>Actions</th></tr></thead>
                <tbody>
                <%
                    try {
                    if (conn == null || conn.isClosed()) conn = DBUtil.getConnection();
                    PreparedStatement pps = conn.prepareStatement(
                        "SELECT p.id, p.payment_method, p.payment_status, p.paid_amount, p.transaction_id, p.refund_amount, " +
                        "i.invoice_number, i.final_amount, b.booking_uid, u.name AS cname " +
                        "FROM payments p JOIN invoices i ON p.invoice_id=i.id JOIN bookings b ON i.booking_id=b.id " +
                        "JOIN customers c ON b.customer_id=c.id JOIN users u ON c.user_id=u.id ORDER BY p.id DESC");
                    ResultSet prs = pps.executeQuery();
                    while (prs.next()) {
                        String pst = prs.getString("payment_status");
                        String pbadge = "Paid".equals(pst)?"badge-completed":"Pending".equals(pst)?"badge-pending":"Refunded".equals(pst)?"badge-due":"badge-progress";
                %>
                <tr>
                    <td><code style="color:var(--primary-light);">#<%= prs.getInt("id") %></code></td>
                    <td><%= prs.getString("booking_uid") %></td>
                    <td style="color:var(--text-white);"><%= prs.getString("cname") %></td>
                    <td>&#8377;<%= String.format("%.2f", prs.getDouble("final_amount")) %></td>
                    <td>&#8377;<%= String.format("%.2f", prs.getDouble("paid_amount")) %></td>
                    <td><%= prs.getString("payment_method") %></td>
                    <td><span class="badge-status <%= pbadge %>"><%= pst %></span></td>
                    <td class="text-muted"><%= prs.getString("transaction_id") != null ? prs.getString("transaction_id") : "—" %></td>
                    <td style="white-space:nowrap;">
                        <% if ("Pending".equals(pst)) { %>
                        <form method="post" action="ManagePaymentServlet" style="display:inline;">
                            <input type="hidden" name="action" value="markPaid"><input type="hidden" name="paymentId" value="<%= prs.getInt("id") %>">
                            <input type="hidden" name="paymentMethod" value="Cash">
                            <button class="action-btn btn btn-sm btn-outline-primary" title="Mark Paid"><i class="fas fa-check"></i> Paid</button>
                        </form>
                        <% } %>
                        <% if ("Paid".equals(pst)) { %>
                        <button class="action-btn btn btn-sm btn-outline-danger" data-bs-toggle="modal" data-bs-target="#refundModal"
                            onclick="document.getElementById('refundPayId').value=<%= prs.getInt("id") %>;" title="Refund"><i class="fas fa-undo"></i></button>
                        <% } %>
                        <form method="post" action="ManagePaymentServlet" style="display:inline;" onsubmit="return confirm('Delete payment record?');">
                            <input type="hidden" name="action" value="delete"><input type="hidden" name="paymentId" value="<%= prs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-danger" title="Delete"><i class="fas fa-trash"></i></button>
                        </form>
                    </td>
                </tr>
                <% } prs.close(); pps.close();
                } catch(Exception e) { e.printStackTrace(); }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ═══════ INVOICES TAB ═══════ -->
    <div class="tab-content-section <%= "invoices".equals(activeTab)?"active":"" %>" id="sec-invoices">
        <h5 class="fw-bold mb-3" style="color:var(--text-white);"><i class="fas fa-file-invoice me-2"></i>Invoices</h5>
        <div class="dashboard-card p-0" style="overflow-x:auto;">
            <table class="data-table">
                <thead><tr><th>Invoice#</th><th>Customer</th><th>Subtotal</th><th>GST</th><th>Discount</th><th>Total</th><th>Date</th><th>Actions</th></tr></thead>
                <tbody>
                <%
                    try {
                    if (conn == null || conn.isClosed()) conn = DBUtil.getConnection();
                    PreparedStatement ips = conn.prepareStatement(
                        "SELECT i.*, u.name AS cname FROM invoices i JOIN customers c ON i.customer_id=c.id JOIN users u ON c.user_id=u.id ORDER BY i.id DESC");
                    ResultSet irs = ips.executeQuery();
                    while (irs.next()) {
                %>
                <tr>
                    <td><code style="color:var(--primary-light);"><%= irs.getString("invoice_number") %></code></td>
                    <td style="color:var(--text-white);"><%= irs.getString("cname") %></td>
                    <td>&#8377;<%= String.format("%.2f", irs.getDouble("subtotal")) %></td>
                    <td>&#8377;<%= String.format("%.2f", irs.getDouble("gst_amount")) %></td>
                    <td>&#8377;<%= String.format("%.2f", irs.getDouble("discount_amount")) %></td>
                    <td><strong>&#8377;<%= String.format("%.2f", irs.getDouble("final_amount")) %></strong></td>
                    <td class="text-muted"><%= irs.getTimestamp("created_at") %></td>
                    <td>
                        <% if (irs.getString("pdf_path") != null) { %>
                        <a href="<%= irs.getString("pdf_path") %>" class="action-btn btn btn-sm btn-outline-primary" target="_blank"><i class="fas fa-download"></i> PDF</a>
                        <% } %>
                    </td>
                </tr>
                <% } irs.close(); ips.close();
                } catch(Exception e) { e.printStackTrace(); }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ═══════ REVIEWS TAB ═══════ -->
    <div class="tab-content-section <%= "reviews".equals(activeTab)?"active":"" %>" id="sec-reviews">
        <h5 class="fw-bold mb-3" style="color:var(--text-white);"><i class="fas fa-star me-2"></i>Review Moderation</h5>
        <div class="dashboard-card p-0" style="overflow-x:auto;">
            <table class="data-table">
                <thead><tr><th>#</th><th>Customer</th><th>Service</th><th>Rating</th><th>Comment</th><th>Status</th><th>Actions</th></tr></thead>
                <tbody>
                <%
                    try {
                    if (conn == null || conn.isClosed()) conn = DBUtil.getConnection();
                    PreparedStatement rvps = conn.prepareStatement(
                        "SELECT r.*, u.name AS cname, s.service_name FROM reviews r " +
                        "JOIN customers c ON r.customer_id=c.id JOIN users u ON c.user_id=u.id " +
                        "JOIN services s ON r.service_id=s.id ORDER BY r.id DESC");
                    ResultSet rvrs = rvps.executeQuery();
                    int ri = 1;
                    while (rvrs.next()) {
                        String rst = rvrs.getString("status");
                        String rbadge = "Approved".equals(rst)?"badge-completed":"Rejected".equals(rst)?"badge-due":"badge-pending";
                %>
                <tr>
                    <td><%= ri++ %></td>
                    <td style="color:var(--text-white);"><%= rvrs.getString("cname") %></td>
                    <td><%= rvrs.getString("service_name") %></td>
                    <td><% for(int s=0;s<rvrs.getInt("rating");s++){%><i class="fas fa-star text-warning"></i><%}%></td>
                    <td style="max-width:250px;"><%= rvrs.getString("comment") != null ? rvrs.getString("comment") : "—" %></td>
                    <td><span class="badge-status <%= rbadge %>"><%= rst %></span></td>
                    <td style="white-space:nowrap;">
                        <% if (!"Approved".equals(rst)) { %>
                        <form method="post" action="ManageReviewServlet" style="display:inline;">
                            <input type="hidden" name="action" value="approve"><input type="hidden" name="reviewId" value="<%= rvrs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-primary"><i class="fas fa-check"></i></button>
                        </form>
                        <% } %>
                        <% if (!"Rejected".equals(rst)) { %>
                        <form method="post" action="ManageReviewServlet" style="display:inline;">
                            <input type="hidden" name="action" value="reject"><input type="hidden" name="reviewId" value="<%= rvrs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-danger"><i class="fas fa-times"></i></button>
                        </form>
                        <% } %>
                        <form method="post" action="ManageReviewServlet" style="display:inline;" onsubmit="return confirm('Delete review?');">
                            <input type="hidden" name="action" value="delete"><input type="hidden" name="reviewId" value="<%= rvrs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-danger"><i class="fas fa-trash"></i></button>
                        </form>
                    </td>
                </tr>
                <% } rvrs.close(); rvps.close();
                } catch(Exception e) { e.printStackTrace(); }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ═══════ INVENTORY TAB ═══════ -->
    <div class="tab-content-section <%= "inventory".equals(activeTab)?"active":"" %>" id="sec-inventory">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h5 class="fw-bold mb-0" style="color:var(--text-white);"><i class="fas fa-boxes-stacked me-2"></i>Inventory</h5>
            <a href="add_service.jsp" class="btn btn-sm btn-auth"><i class="fas fa-plus me-1"></i>Add Item</a>
        </div>
        <div class="dashboard-card p-0" style="overflow-x:auto;">
            <table class="data-table">
                <thead><tr><th>Code</th><th>Name</th><th>Category</th><th>Qty</th><th>Price</th><th>Status</th><th>Actions</th></tr></thead>
                <tbody>
                <%
                    try {
                    if (conn == null || conn.isClosed()) conn = DBUtil.getConnection();
                    PreparedStatement invps = conn.prepareStatement("SELECT * FROM inventory ORDER BY id DESC");
                    ResultSet invrs = invps.executeQuery();
                    while (invrs.next()) {
                        boolean lowStock = invrs.getInt("quantity") <= invrs.getInt("low_stock_threshold");
                %>
                <tr>
                    <td><code style="color:var(--primary-light);"><%= invrs.getString("item_code") %></code></td>
                    <td style="color:var(--text-white);"><%= invrs.getString("name") %></td>
                    <td><%= invrs.getString("category") %></td>
                    <td><span class="<%= lowStock?"text-danger fw-bold":"" %>"><%= invrs.getInt("quantity") %> <%= invrs.getString("unit") %></span>
                        <% if(lowStock){%><i class="fas fa-exclamation-triangle text-danger ms-1" title="Low Stock"></i><%}%></td>
                    <td>&#8377;<%= String.format("%.2f", invrs.getDouble("price")) %></td>
                    <td><span class="badge-status <%= lowStock?"badge-due":"badge-completed" %>"><%= invrs.getString("status") %></span></td>
                    <td>
                        <form method="post" action="UpdateInventoryStockServlet" style="display:inline;" class="d-inline-flex gap-1 align-items-center">
                            <input type="hidden" name="itemId" value="<%= invrs.getInt("id") %>">
                            <input type="number" name="quantity" class="form-control form-control-sm" style="width:60px;" value="<%= invrs.getInt("quantity") %>">
                            <button class="action-btn btn btn-sm btn-outline-primary"><i class="fas fa-save"></i></button>
                        </form>
                    </td>
                </tr>
                <% } invrs.close(); invps.close();
                } catch(Exception e) { e.printStackTrace(); }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ═══════ SERVICES TAB ═══════ -->
    <div class="tab-content-section <%= "services".equals(activeTab)?"active":"" %>" id="sec-services">
        <div class="d-flex justify-content-between align-items-center mb-3">
            <h5 class="fw-bold mb-0" style="color:var(--text-white);"><i class="fas fa-tools me-2"></i>Services</h5>
            <a href="add_service.jsp" class="btn btn-sm btn-auth"><i class="fas fa-plus me-1"></i>Add Service</a>
        </div>
        <div class="dashboard-card p-0" style="overflow-x:auto;">
            <table class="data-table">
                <thead><tr><th>#</th><th>Service</th><th>Price</th><th>Time</th><th>Status</th><th>Actions</th></tr></thead>
                <tbody>
                <%
                    try {
                    if (conn == null || conn.isClosed()) conn = DBUtil.getConnection();
                    PreparedStatement svps = conn.prepareStatement("SELECT * FROM services ORDER BY id DESC");
                    ResultSet svrs = svps.executeQuery();
                    int si = 1;
                    while (svrs.next()) {
                %>
                <tr>
                    <td><%= si++ %></td>
                    <td style="color:var(--text-white);"><%= svrs.getString("service_name") %></td>
                    <td>&#8377;<%= String.format("%.2f", svrs.getDouble("price")) %></td>
                    <td><%= svrs.getDouble("time_required") %> hrs</td>
                    <td><span class="badge-status <%= "Available".equals(svrs.getString("status"))?"badge-completed":"badge-due" %>"><%= svrs.getString("status") %></span></td>
                    <td>
                        <a href="edit_service.jsp?id=<%= svrs.getInt("id") %>" class="action-btn btn btn-sm btn-outline-primary"><i class="fas fa-edit"></i></a>
                        <form method="post" action="DeleteServiceServlet" style="display:inline;" onsubmit="return confirm('Delete?');">
                            <input type="hidden" name="serviceId" value="<%= svrs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-danger"><i class="fas fa-trash"></i></button>
                        </form>
                    </td>
                </tr>
                <% } svrs.close(); svps.close();
                } catch(Exception e) { e.printStackTrace(); }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ═══════ SUPPLIERS TAB ═══════ -->
    <div class="tab-content-section <%= "suppliers".equals(activeTab)?"active":"" %>" id="sec-suppliers">
        <h5 class="fw-bold mb-3" style="color:var(--text-white);"><i class="fas fa-truck me-2"></i>Suppliers</h5>
        <div class="dashboard-card p-0" style="overflow-x:auto;">
            <table class="data-table">
                <thead><tr><th>#</th><th>Name</th><th>Email</th><th>Phone</th><th>Status</th></tr></thead>
                <tbody>
                <%
                    try {
                    if (conn == null || conn.isClosed()) conn = DBUtil.getConnection();
                    PreparedStatement sups = conn.prepareStatement("SELECT * FROM suppliers ORDER BY id DESC");
                    ResultSet surs = sups.executeQuery();
                    int sui = 1;
                    while (surs.next()) {
                %>
                <tr>
                    <td><%= sui++ %></td>
                    <td style="color:var(--text-white);"><%= surs.getString("name") %></td>
                    <td><%= surs.getString("email") %></td>
                    <td><%= surs.getString("phone") %></td>
                    <td><span class="badge-status badge-completed"><%= surs.getString("status") %></span></td>
                </tr>
                <% } surs.close(); sups.close();
                } catch(Exception e) { e.printStackTrace(); }
                %>
                </tbody>
            </table>
        </div>
    </div>

    <!-- ═══════ CONTACTS TAB ═══════ -->
    <div class="tab-content-section <%= "contacts".equals(activeTab)?"active":"" %>" id="sec-contacts">
        <h5 class="fw-bold mb-3" style="color:var(--text-white);"><i class="fas fa-envelope me-2"></i>Contact Messages</h5>
        <div class="dashboard-card p-0" style="overflow-x:auto;">
            <table class="data-table">
                <thead><tr><th>#</th><th>Name</th><th>Email</th><th>Subject</th><th>Message</th><th>Date</th><th>Actions</th></tr></thead>
                <tbody>
                <%
                    try {
                    if (conn == null || conn.isClosed()) conn = DBUtil.getConnection();
                    PreparedStatement ctps = conn.prepareStatement("SELECT * FROM contact_messages ORDER BY id DESC");
                    ResultSet ctrs = ctps.executeQuery();
                    int cti = 1;
                    while (ctrs.next()) {
                %>
                <tr>
                    <td><%= cti++ %></td>
                    <td style="color:var(--text-white);"><%= ctrs.getString("name") %></td>
                    <td><%= ctrs.getString("email") %></td>
                    <td><%= ctrs.getString("subject") %></td>
                    <td style="max-width:300px;"><%= ctrs.getString("message") %></td>
                    <td class="text-muted"><%= ctrs.getTimestamp("created_at") %></td>
                    <td>
                        <form method="post" action="DeleteContactServlet" style="display:inline;" onsubmit="return confirm('Delete?');">
                            <input type="hidden" name="contactId" value="<%= ctrs.getInt("id") %>">
                            <button class="action-btn btn btn-sm btn-outline-danger"><i class="fas fa-trash"></i></button>
                        </form>
                    </td>
                </tr>
                <% } ctrs.close(); ctps.close();
                } catch(Exception e) { e.printStackTrace(); }
                finally { if (conn != null) try { conn.close(); } catch(Exception ig) {} }
                %>
                </tbody>
            </table>
        </div>
    </div>

</main>

<!-- ═══════ MODALS ═══════ -->
<!-- Edit Customer Modal -->
<div class="modal fade" id="editCustModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content">
    <div class="modal-header"><h6 class="modal-title fw-bold"><i class="fas fa-user-edit me-2"></i>Edit Customer</h6><button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button></div>
    <form method="post" action="ManageCustomerServlet">
    <input type="hidden" name="action" value="edit"><input type="hidden" name="userId" id="editCustId">
    <div class="modal-body">
        <div class="mb-3"><label class="form-label">Name</label><input type="text" class="form-control" name="name" id="editCustName" required></div>
        <div class="mb-3"><label class="form-label">Email</label><input type="email" class="form-control" name="email" id="editCustEmail" required></div>
        <div class="mb-3"><label class="form-label">Phone</label><input type="text" class="form-control" name="phone" id="editCustPhone" required></div>
        <div class="mb-3"><label class="form-label">Address</label><textarea class="form-control" name="address" id="editCustAddr" rows="2"></textarea></div>
        <div class="mb-3"><label class="form-label">Emergency Contact</label><input type="text" class="form-control" name="emergencyContact" id="editCustEmerg"></div>
    </div>
    <div class="modal-footer"><button type="submit" class="btn btn-auth"><i class="fas fa-save me-1"></i>Save Changes</button></div>
    </form>
</div></div></div>

<!-- Add Mechanic Modal -->
<div class="modal fade" id="addMechModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content">
    <div class="modal-header"><h6 class="modal-title fw-bold"><i class="fas fa-user-plus me-2"></i>Add Mechanic</h6><button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button></div>
    <form method="post" action="ManageMechanicServlet">
    <input type="hidden" name="action" value="add">
    <div class="modal-body">
        <div class="mb-3"><label class="form-label">Full Name</label><input type="text" class="form-control" name="name" required></div>
        <div class="mb-3"><label class="form-label">Email</label><input type="email" class="form-control" name="email" required></div>
        <div class="mb-3"><label class="form-label">Phone</label><input type="text" class="form-control" name="phone" required></div>
        <div class="mb-3"><label class="form-label">Specialization</label><input type="text" class="form-control" name="specialization" placeholder="Engine, Electrical, Bodywork..." required></div>
        <div class="row">
            <div class="col-md-6 mb-3"><label class="form-label">Branch</label>
                <select class="form-select" name="branchId" required>
                <%
                    Connection bc = null;
                    try { bc = DBUtil.getConnection();
                    PreparedStatement bps = bc.prepareStatement("SELECT id, name FROM branches WHERE status='Active'");
                    ResultSet brs2 = bps.executeQuery();
                    while(brs2.next()) { %>
                    <option value="<%= brs2.getInt("id") %>"><%= brs2.getString("name") %></option>
                <% } brs2.close(); bps.close(); } catch(Exception e){} finally { if(bc!=null) try{bc.close();}catch(Exception ig){} } %>
                </select>
            </div>
            <div class="col-md-6 mb-3"><label class="form-label">Salary</label><input type="number" class="form-control" name="salary" value="25000" required></div>
        </div>
    </div>
    <div class="modal-footer"><button type="submit" class="btn btn-auth"><i class="fas fa-plus me-1"></i>Add Mechanic</button></div>
    </form>
</div></div></div>

<!-- Refund Modal -->
<div class="modal fade" id="refundModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content">
    <div class="modal-header"><h6 class="modal-title fw-bold"><i class="fas fa-undo me-2"></i>Process Refund</h6><button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button></div>
    <form method="post" action="ManagePaymentServlet">
    <input type="hidden" name="action" value="refund"><input type="hidden" name="paymentId" id="refundPayId">
    <div class="modal-body">
        <div class="mb-3"><label class="form-label">Refund Amount (&#8377;)</label><input type="number" step="0.01" class="form-control" name="refundAmount" required></div>
        <div class="mb-3"><label class="form-label">Reason</label><textarea class="form-control" name="refundReason" rows="2" required></textarea></div>
    </div>
    <div class="modal-footer"><button type="submit" class="btn btn-outline-danger"><i class="fas fa-undo me-1"></i>Process Refund</button></div>
    </form>
</div></div></div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script>
// Live clock
function updateTime(){document.getElementById('liveTime').textContent=new Date().toLocaleTimeString();}
setInterval(updateTime,1000);updateTime();

// Global Search
let searchTimer;
document.getElementById('globalSearch').addEventListener('input',function(){
    clearTimeout(searchTimer);
    let q=this.value.trim();
    let box=document.getElementById('searchResults');
    if(q.length<2){box.style.display='none';return;}
    searchTimer=setTimeout(()=>{
        fetch('GlobalSearchServlet?q='+encodeURIComponent(q)).then(r=>r.json()).then(d=>{
            if(d.results.length===0){box.style.display='none';return;}
            let html='';
            d.results.forEach(r=>{
                html+='<div class="sr-item"><div class="sr-type">'+r.type+'</div><div class="sr-title">'+r.title+'</div><div class="sr-sub">'+r.sub+'</div></div>';
            });
            box.innerHTML=html;box.style.display='block';
        });
    },300);
});
document.addEventListener('click',e=>{if(!e.target.closest('.search-box'))document.getElementById('searchResults').style.display='none';});

// Customer search filter
document.getElementById('custSearch')?.addEventListener('input',function(){
    let q=this.value.toLowerCase();
    document.querySelectorAll('#custTable tbody tr').forEach(tr=>{
        tr.style.display=tr.textContent.toLowerCase().includes(q)?'':'none';
    });
});

// Fill edit customer modal
function fillCustEdit(id,name,email,phone,addr,emerg){
    document.getElementById('editCustId').value=id;
    document.getElementById('editCustName').value=name;
    document.getElementById('editCustEmail').value=email;
    document.getElementById('editCustPhone').value=phone;
    document.getElementById('editCustAddr').value=addr;
    document.getElementById('editCustEmerg').value=emerg;
}

// Dashboard metrics & charts
if(document.getElementById('sec-dashboard').classList.contains('active')){
    fetch('AdminDashboardDataServlet').then(r=>r.json()).then(d=>{
        const metrics=[
            {icon:'fa-users',color:'#818cf8',bg:'rgba(99,102,241,0.1)',val:d.totalCustomers,label:'Total Customers'},
            {icon:'fa-wrench',color:'#06b6d4',bg:'rgba(6,182,212,0.1)',val:d.totalMechanics,label:'Total Mechanics'},
            {icon:'fa-calendar-check',color:'#f59e0b',bg:'rgba(245,158,11,0.1)',val:d.totalBookings,label:'Total Bookings'},
            {icon:'fa-indian-rupee-sign',color:'#10b981',bg:'rgba(16,185,129,0.1)',val:'₹'+Number(d.totalRevenue).toLocaleString(),label:'Total Revenue'},
            {icon:'fa-clock',color:'#ef4444',bg:'rgba(239,68,68,0.1)',val:d.pendingPayments,label:'Pending Payments'},
            {icon:'fa-spinner',color:'#f59e0b',bg:'rgba(245,158,11,0.1)',val:d.pendingServices,label:'Pending Services'},
            {icon:'fa-calendar-day',color:'#3b82f6',bg:'rgba(59,130,246,0.1)',val:d.todayAppointments,label:"Today's Appointments"},
            {icon:'fa-check-double',color:'#10b981',bg:'rgba(16,185,129,0.1)',val:d.completedServices,label:'Completed Services'},
            {icon:'fa-box-open',color:'#ef4444',bg:'rgba(239,68,68,0.1)',val:d.inventoryAlerts,label:'Inventory Alerts'},
            {icon:'fa-star',color:'#f59e0b',bg:'rgba(245,158,11,0.1)',val:d.totalReviews+' ('+d.avgRating+'★)',label:'Customer Reviews'},
            {icon:'fa-history',color:'#8b5cf6',bg:'rgba(139,92,246,0.1)',val:d.recentActivity.length,label:'Recent Activities'},
            {icon:'fa-bell',color:'#06b6d4',bg:'rgba(6,182,212,0.1)',val:d.unreadNotifications,label:'Notifications'}
        ];
        let html='';
        metrics.forEach(m=>{
            html+='<div class="col-6 col-lg-3"><div class="metric-card"><div class="d-flex justify-content-between align-items-start"><div><div class="metric-value">'+m.val+'</div><div class="metric-label">'+m.label+'</div></div><div class="metric-icon" style="background:'+m.bg+';color:'+m.color+'"><i class="fas '+m.icon+'"></i></div></div></div></div>';
        });
        document.getElementById('metricsGrid').innerHTML=html;

        // Revenue chart
        if(d.monthLabels.length>0){
            new Chart(document.getElementById('revenueChart'),{type:'bar',data:{labels:d.monthLabels,datasets:[{label:'Revenue (₹)',data:d.monthlyRevenue,backgroundColor:'rgba(99,102,241,0.5)',borderColor:'#6366f1',borderWidth:1,borderRadius:6}]},options:{responsive:true,plugins:{legend:{display:false}},scales:{x:{ticks:{color:'#64748b'},grid:{color:'rgba(148,163,184,0.08)'}},y:{ticks:{color:'#64748b',callback:v=>'₹'+v.toLocaleString()},grid:{color:'rgba(148,163,184,0.08)'}}}}});
        }

        // Status doughnut
        new Chart(document.getElementById('statusChart'),{type:'doughnut',data:{labels:['Pending','Accepted','In Progress','Ready','Delivered','Cancelled'],datasets:[{data:d.statusDist,backgroundColor:['#f59e0b','#3b82f6','#06b6d4','#8b5cf6','#10b981','#ef4444'],borderWidth:0}]},options:{responsive:true,plugins:{legend:{position:'bottom',labels:{color:'#94a3b8',font:{size:11}}}}}});

        // Activity feed
        let ahtml='';
        d.recentActivity.forEach(a=>{
            ahtml+='<div class="d-flex gap-3 py-2 border-bottom" style="border-color:var(--border-subtle)!important;"><i class="fas fa-circle" style="font-size:6px;margin-top:8px;color:var(--primary-light);"></i><div><div style="color:var(--text-primary);font-size:0.85rem;">'+a.desc+'</div><small style="color:var(--text-muted);">'+a.time+'</small></div></div>';
        });
        if(ahtml==='')ahtml='<p class="text-muted small">No recent activity.</p>';
        document.getElementById('activityFeed').innerHTML=ahtml;
    }).catch(e=>console.error('Dashboard data error:',e));
}
</script>
</body>
</html>