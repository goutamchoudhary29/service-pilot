package com.vehicleservice.controller;

import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Image;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import com.vehicleservice.util.DBUtil;
import com.vehicleservice.util.QRBarcodeUtil;
import com.vehicleservice.util.SecurityUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.awt.Color;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

@WebServlet("/GenerateInvoiceServlet")
public class GenerateInvoiceServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("adminRoleId") == null) {
            response.sendRedirect("admin_login.jsp?error=Access%20Denied.");
            return;
        }

        String bookingIdStr = request.getParameter("bookingId");
        if (bookingIdStr == null || bookingIdStr.trim().isEmpty()) {
            response.sendRedirect("admin_dashboard.jsp?error=Invalid%20Booking%20ID.");
            return;
        }

        int bookingId = Integer.parseInt(bookingIdStr);
        Connection conn = null;
        try {
            conn = DBUtil.getConnection();

            // 1. Check if invoice already exists
            String checkInvQuery = "SELECT pdf_path FROM invoices WHERE booking_id = ?";
            PreparedStatement checkInvPs = conn.prepareStatement(checkInvQuery);
            checkInvPs.setInt(1, bookingId);
            ResultSet checkInvRs = checkInvPs.executeQuery();
            if (checkInvRs.next()) {
                String existingPdfPath = checkInvRs.getString("pdf_path");
                checkInvRs.close();
                checkInvPs.close();
                
                // Stream existing PDF to browser
                streamPdf(existingPdfPath, response);
                return;
            }
            checkInvRs.close();
            checkInvPs.close();

            // 2. Fetch booking details to generate a new invoice
            String query = "SELECT b.id, b.booking_uid, b.booking_date, b.customer_id, " +
                           "u.name AS customer_name, u.email AS customer_email, u.phone AS customer_phone, " +
                           "v.brand, v.model, v.license_plate, " +
                           "s.service_name, s.price, s.description AS service_desc " +
                           "FROM bookings b " +
                           "JOIN customers c ON b.customer_id = c.id " +
                           "JOIN users u ON c.user_id = u.id " +
                           "JOIN vehicles v ON b.vehicle_id = v.id " +
                           "JOIN services s ON b.service_id = s.id " +
                           "WHERE b.id = ?";
            PreparedStatement ps = conn.prepareStatement(query);
            ps.setInt(1, bookingId);
            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                rs.close();
                ps.close();
                response.sendRedirect("admin_dashboard.jsp?error=Booking%20details%20not%20found.");
                return;
            }

            int customerId = rs.getInt("customer_id");
            String customerName = rs.getString("customer_name");
            String customerEmail = rs.getString("customer_email");
            String customerPhone = rs.getString("customer_phone");
            String vehicleDetails = rs.getString("brand") + " " + rs.getString("model") + " (" + rs.getString("license_plate") + ")";
            String serviceName = rs.getString("service_name");
            String serviceDesc = rs.getString("service_desc");
            double price = rs.getDouble("price");

            rs.close();
            ps.close();

            // Calculate billing numbers
            double subtotal = price;
            double gst = subtotal * 0.18; // 18% GST
            double discount = 0.0;
            
            // Apply flat loyalty discount of 100 Rs if customer has loyalty points
            String pointsQuery = "SELECT loyalty_points FROM customers WHERE id = ?";
            PreparedStatement pointsPs = conn.prepareStatement(pointsQuery);
            pointsPs.setInt(1, customerId);
            ResultSet pointsRs = pointsPs.executeQuery();
            if (pointsRs.next() && pointsRs.getInt("loyalty_points") >= 100) {
                discount = 100.00;
            }
            pointsRs.close();
            pointsPs.close();

            double grandTotal = subtotal + gst - discount;

            // Generate unique invoice number
            String countQuery = "SELECT COUNT(*) FROM invoices";
            Statement countStmt = conn.createStatement();
            ResultSet countRs = countStmt.executeQuery(countQuery);
            int invCount = 0;
            if (countRs.next()) {
                invCount = countRs.getInt(1);
            }
            countRs.close();
            countStmt.close();
            
            String invoiceNumber = String.format("INV-2026-%06d", invCount + 1);

            // Establish file paths
            String appPath = request.getServletContext().getRealPath("");
            String mediaDir = appPath + File.separator + "images" + File.separator + "invoices";
            File dir = new File(mediaDir);
            if (!dir.exists()) {
                dir.mkdirs();
            }

            String qrPath = mediaDir + File.separator + invoiceNumber + "_qr.png";
            String barPath = mediaDir + File.separator + invoiceNumber + "_bar.png";
            String pdfPath = mediaDir + File.separator + invoiceNumber + ".pdf";

            // Generate UPI payment QR Code and invoice Barcode via ZXing
            String upiUri = "upi://pay?pa=finance@servicepilot&pn=ServicePilot&am=" + grandTotal + "&cu=INR";
            QRBarcodeUtil.generateQRCode(upiUri, qrPath, 150, 150);
            QRBarcodeUtil.generateBarcode(invoiceNumber, barPath, 250, 50);

            // 3. Create PDF Invoice using OpenPDF (LibrePDF)
            Document doc = new Document();
            PdfWriter.getInstance(doc, new FileOutputStream(pdfPath));
            doc.open();

            // Set up fonts
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 22, Color.DARK_GRAY);
            Font sectionFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12, Color.BLACK);
            Font regularFont = FontFactory.getFont(FontFactory.HELVETICA, 10, Color.BLACK);
            Font boldFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, Color.BLACK);
            Font mutedFont = FontFactory.getFont(FontFactory.HELVETICA, 8, Color.GRAY);

            // Header Section
            Paragraph title = new Paragraph("SERVICEPILOT AUTO SERVICES", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(5);
            doc.add(title);

            Paragraph companyInfo = new Paragraph("123 Service Street, Indore, MP 452001\nGSTIN: 27AAAAA1111A1Z1 | Support: support@servicepilot.com", mutedFont);
            companyInfo.setAlignment(Element.ALIGN_CENTER);
            companyInfo.setSpacingAfter(20);
            doc.add(companyInfo);

            // Metadata Table
            PdfPTable metaTable = new PdfPTable(2);
            metaTable.setWidthPercentage(100);
            metaTable.setSpacingAfter(20);
            
            PdfPCell cell1 = new PdfPCell(new Phrase("Bill To:\n" + customerName + "\nPhone: " + customerPhone + "\nEmail: " + customerEmail, regularFont));
            cell1.setBorder(PdfPCell.NO_BORDER);
            metaTable.addCell(cell1);
            
            PdfPCell cell2 = new PdfPCell(new Phrase("Invoice No: " + invoiceNumber + "\nDate: " + new java.util.Date() + "\nVehicle: " + vehicleDetails, regularFont));
            cell2.setBorder(PdfPCell.NO_BORDER);
            cell2.setHorizontalAlignment(Element.ALIGN_RIGHT);
            metaTable.addCell(cell2);
            
            doc.add(metaTable);

            // Billing Items Table
            PdfPTable billTable = new PdfPTable(3);
            billTable.setWidthPercentage(100);
            billTable.setSpacingAfter(15);
            
            // Header Row
            PdfPCell h1 = new PdfPCell(new Phrase("Service Name", sectionFont));
            h1.setBackgroundColor(Color.LIGHT_GRAY);
            billTable.addCell(h1);
            
            PdfPCell h2 = new PdfPCell(new Phrase("Description", sectionFont));
            h2.setBackgroundColor(Color.LIGHT_GRAY);
            billTable.addCell(h2);
            
            PdfPCell h3 = new PdfPCell(new Phrase("Price (INR)", sectionFont));
            h3.setBackgroundColor(Color.LIGHT_GRAY);
            h3.setHorizontalAlignment(Element.ALIGN_RIGHT);
            billTable.addCell(h3);

            // Data Row
            billTable.addCell(new PdfPCell(new Phrase(serviceName, regularFont)));
            billTable.addCell(new PdfPCell(new Phrase(serviceDesc != null ? serviceDesc : "Regular maintenance check", regularFont)));
            
            PdfPCell priceCell = new PdfPCell(new Phrase(String.format("%.2f", price), regularFont));
            priceCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
            billTable.addCell(priceCell);
            
            doc.add(billTable);

            // Calculation Breakdown Block
            PdfPTable summaryTable = new PdfPTable(2);
            summaryTable.setWidthPercentage(40);
            summaryTable.setHorizontalAlignment(Element.ALIGN_RIGHT);
            summaryTable.setSpacingAfter(30);

            summaryTable.addCell(new PdfPCell(new Phrase("Subtotal:", regularFont)));
            PdfPCell val1 = new PdfPCell(new Phrase(String.format("₹%.2f", subtotal), regularFont));
            val1.setHorizontalAlignment(Element.ALIGN_RIGHT);
            summaryTable.addCell(val1);

            summaryTable.addCell(new PdfPCell(new Phrase("GST (18%):", regularFont)));
            PdfPCell val2 = new PdfPCell(new Phrase(String.format("₹%.2f", gst), regularFont));
            val2.setHorizontalAlignment(Element.ALIGN_RIGHT);
            summaryTable.addCell(val2);

            summaryTable.addCell(new PdfPCell(new Phrase("Loyalty Discount:", regularFont)));
            PdfPCell val3 = new PdfPCell(new Phrase(String.format("- ₹%.2f", discount), regularFont));
            val3.setHorizontalAlignment(Element.ALIGN_RIGHT);
            summaryTable.addCell(val3);

            summaryTable.addCell(new PdfPCell(new Phrase("Grand Total:", boldFont)));
            PdfPCell val4 = new PdfPCell(new Phrase(String.format("₹%.2f", grandTotal), boldFont));
            val4.setHorizontalAlignment(Element.ALIGN_RIGHT);
            summaryTable.addCell(val4);

            doc.add(summaryTable);

            // QR & Barcode Footer Section
            PdfPTable codeTable = new PdfPTable(2);
            codeTable.setWidthPercentage(100);
            codeTable.setSpacingAfter(15);
            
            // Left Cell: Barcode
            Image barcodeImg = Image.getInstance(barPath);
            barcodeImg.scalePercent(80);
            PdfPCell barcodeCell = new PdfPCell(barcodeImg);
            barcodeCell.setBorder(PdfPCell.NO_BORDER);
            barcodeCell.setHorizontalAlignment(Element.ALIGN_LEFT);
            barcodeCell.setVerticalAlignment(Element.ALIGN_BOTTOM);
            codeTable.addCell(barcodeCell);

            // Right Cell: UPI QR Code
            Image qrImg = Image.getInstance(qrPath);
            qrImg.scaleAbsolute(100, 100);
            PdfPCell qrCell = new PdfPCell(qrImg);
            qrCell.setBorder(PdfPCell.NO_BORDER);
            qrCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
            codeTable.addCell(qrCell);

            doc.add(codeTable);

            // Footer / Terms
            Paragraph terms = new Paragraph("Thank you for choosing ServicePilot!\nTerms: Goods once repaired will be warrantied for 14 days. Please scan the QR code to process payment directly via UPI.", mutedFont);
            terms.setAlignment(Element.ALIGN_CENTER);
            doc.add(terms);

            doc.close();

            // Save Invoice details to DB
            String insertInvQuery = "INSERT INTO invoices (invoice_number, booking_id, customer_id, subtotal, gst_amount, discount_amount, final_amount, pdf_path, qr_code_path, barcode_path) " +
                                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            PreparedStatement insertInvPs = conn.prepareStatement(insertInvQuery, Statement.RETURN_GENERATED_KEYS);
            insertInvPs.setString(1, invoiceNumber);
            insertInvPs.setInt(2, bookingId);
            insertInvPs.setInt(3, customerId);
            insertInvPs.setDouble(4, subtotal);
            insertInvPs.setDouble(5, gst);
            insertInvPs.setDouble(6, discount);
            insertInvPs.setDouble(7, grandTotal);
            insertInvPs.setString(8, "images/invoices/" + invoiceNumber + ".pdf");
            insertInvPs.setString(9, "images/invoices/" + invoiceNumber + "_qr.png");
            insertInvPs.setString(10, "images/invoices/" + invoiceNumber + "_bar.png");
            insertInvPs.executeUpdate();
            
            int newInvoiceId = -1;
            ResultSet generatedKeys = insertInvPs.getGeneratedKeys();
            if (generatedKeys.next()) {
                newInvoiceId = generatedKeys.getInt(1);
            }
            generatedKeys.close();
            insertInvPs.close();

            if (newInvoiceId != -1) {
                // Record corresponding Payment as 'Paid' by default for invoice checkout
                String paymentQuery = "INSERT INTO payments (invoice_id, payment_method, payment_status, paid_amount, transaction_id) VALUES (?, 'UPI', 'Paid', ?, ?)";
                PreparedStatement paymentPs = conn.prepareStatement(paymentQuery);
                paymentPs.setInt(1, newInvoiceId);
                paymentPs.setDouble(2, grandTotal);
                paymentPs.setString(3, "TXN-" + System.currentTimeMillis());
                paymentPs.executeUpdate();
                paymentPs.close();
            }

            // Deduct loyalty points if discount was applied, or add points for the purchase
            if (discount > 0) {
                String deductPoints = "UPDATE customers SET loyalty_points = loyalty_points - 100 WHERE id = ?";
                PreparedStatement deductPs = conn.prepareStatement(deductPoints);
                deductPs.setInt(1, customerId);
                deductPs.executeUpdate();
                deductPs.close();
            } else {
                String addPoints = "UPDATE customers SET loyalty_points = loyalty_points + 50 WHERE id = ?";
                PreparedStatement addPs = conn.prepareStatement(addPoints);
                addPs.setInt(1, customerId);
                addPs.executeUpdate();
                addPs.close();
            }

            // Stream generated PDF back to request
            streamPdf(pdfPath, response);

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("admin_dashboard.jsp?error=Error%20generating%20invoice.");
        } finally {
            try {
                if (conn != null) conn.close();
            } catch (Exception ignore) {}
        }
    }

    private void streamPdf(String pdfPath, HttpServletResponse response) throws IOException {
        File pdfFile = new File(pdfPath);
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "inline; filename=" + pdfFile.getName());
        response.setContentLength((int) pdfFile.length());

        try (FileInputStream fis = new FileInputStream(pdfFile);
             OutputStream os = response.getOutputStream()) {
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = fis.read(buffer)) != -1) {
                os.write(buffer, 0, bytesRead);
            }
        }
    }
}
