package com.vehicleservice.util;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import java.io.File;
import java.nio.file.Path;

public class QRBarcodeUtil {

    /**
     * Generates a QR Code image.
     */
    public static void generateQRCode(String data, String filePath, int width, int height) throws Exception {
        File file = new File(filePath);
        File parent = file.getParentFile();
        if (parent != null && !parent.exists()) {
            parent.mkdirs();
        }

        BitMatrix matrix = new MultiFormatWriter().encode(data, BarcodeFormat.QR_CODE, width, height);
        Path path = file.toPath();
        MatrixToImageWriter.writeToPath(matrix, "PNG", path);
    }

    /**
     * Generates a 1D CODE_128 Barcode image.
     */
    public static void generateBarcode(String data, String filePath, int width, int height) throws Exception {
        File file = new File(filePath);
        File parent = file.getParentFile();
        if (parent != null && !parent.exists()) {
            parent.mkdirs();
        }

        BitMatrix matrix = new MultiFormatWriter().encode(data, BarcodeFormat.CODE_128, width, height);
        Path path = file.toPath();
        MatrixToImageWriter.writeToPath(matrix, "PNG", path);
    }
}
