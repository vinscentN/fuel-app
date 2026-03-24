
package com.example.fuels_app;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.telephony.TelephonyManager;
import android.util.Log;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.math.BigDecimal;
import java.text.DecimalFormat;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.graphics.Color;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import io.flutter.plugin.common.MethodChannel;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.google.zxing.qrcode.decoder.ErrorCorrectionLevel;

import java.util.Hashtable;

import com.vanstone.appsdk.client.ISdkStatue;
import com.vanstone.trans.api.IcApi;
import com.vanstone.trans.api.MagCardApi;
import com.vanstone.trans.api.PedApi;
import com.vanstone.trans.api.PiccApi;
import com.vanstone.trans.api.PrinterApi;
import com.vanstone.trans.api.SystemApi;
import com.vanstone.utils.CommonConvert;

// EMV/CPACE imports (initialized for completeness)
import com.vanstone.l2.CPACE;
import com.vanstone.l2.CPACE_APPLIST;
import com.vanstone.l2.Common;
import com.vanstone.l2.PAYPASS_OUTCOME;
import com.vanstone.l2.PayPass;
import com.vanstone.l2.PayWave;
import com.vanstone.l2.COMMON_PPSE_STATUS;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "aisino_pos_sdk";
    private static final String TAG = "MainActivity";

    // Vanstone SDK state
    private volatile boolean sdkInitialized = false;
    private View launchOverlay;

    // PICC/MIFARE constants
    private static final int KEY_TYPE_A = 66;                 // Key A
    private static final String DEFAULT_KEY_ASC = "ffffffffffff";
    private static final int TAPCARD_PAN_LENGTH = 19;

    // PED master key config (SET THESE to match your device setup)
    private static final int MK_INDEX = 0;        // e.g., your loaded master key index
    private static final int SAVE_MK_MODE = 0;    // device-specific (set to your environment)
    private static final int MK_MODE = 0;         // device-specific (set to your environment)

    // EMV scaffolding
    static COMMON_PPSE_STATUS ppse = new COMMON_PPSE_STATUS();
    static PAYPASS_OUTCOME outcome = new PAYPASS_OUTCOME();
    static int reselect = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Use Flutter's splash only; remove native overlay to avoid delays
        initializeVanstoneSDK();
    }

    // Splash overlay via old Flutter embedding API is not available in this Flutter version.
    // We use a separate native SplashActivity to show immediate text instead.

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "startNfcTransaction":
                            if (!sdkInitialized) {
                                result.error("SDK_NOT_INITIALIZED", "Vanstone SDK not initialized", null);
                                return;
                            }
                            handleNfc(result);
                            break;

                        case "startChipTransaction":
                            if (!sdkInitialized) {
                                result.error("SDK_NOT_INITIALIZED", "Vanstone SDK not initialized", null);
                                return;
                            }
                            handleChip(result);
                            break;

                        case "startMagstripeTransaction":
                            if (!sdkInitialized) {
                                result.error("SDK_NOT_INITIALIZED", "Vanstone SDK not initialized", null);
                                return;
                            }
                            handleMagstripe(result);
                            break;

                        case "requestPin":
                            handlePin(result);
                            break;

                        case "checkNfcAvailability":
                            checkNfcAvailability(result);
                            break;

                        case "testPrint":
                            Map<String, Object> args = (Map<String, Object>) call.arguments;
                            handleTestPrint(args, result);
                            break;

                        case "printReceiptCopy":
                            Map<String, Object> args2 = (Map<String, Object>) call.arguments;
                            handlePrintReceiptCopy(args2, result);
                            break;

                        case "printBalanceEnquiryReceipt":
                            Map<String, Object> args3 = (Map<String, Object>) call.arguments;
                            handlePrintBalanceReceipt(args3, result);
                            break;

                        case "batchCutOffReceipt":
                            Map<String, Object> args4 = (Map<String, Object>) call.arguments;
                            handleBatchCutOffReceipt(args4, result);
                            break;

                        case "printLastSaleReceipt":
                            Map<String, Object> args5 = (Map<String, Object>) call.arguments;
                            handleLastSaleReceipt(args5, result);
                            break;

                        case "batchAuditReceipt":
                            Map<String, Object> args6 = (Map<String, Object>) call.arguments;
                            handleBatchAuditReceipt(args6, result);
                            break;

                        case "printQRCodeReceipt":
                            Map<String, Object> args7 = (Map<String, Object>) call.arguments;
                            handlePrintQRCodeReceipt(args7, result);
                            break;

                        case "printPickupReceipt":
                            Map<String, Object> args8 = (Map<String, Object>) call.arguments;
                            handlePrintPickupReceipt(args8, result);
                            break;

                        case "printDeliveryReceipt":
                            Map<String, Object> args9 = (Map<String, Object>) call.arguments;
                            handlePrintDeliveryReceipt(args9, result);
                            break;

                        case "getSerialNumber":
                            result.success(getSerialNumberSafe());
                            break;

                        case "getImei":
                            result.success(getImeiSafe());
                            break;

                        case "getPosType":
                            result.success(readPosType());
                            break;

                        default:
                            result.notImplemented();
                            break;
                    }
                });
    }

    private void initializeVanstoneSDK() {
        try {
            Log.d(TAG, "Initializing Vanstone SDK...");
            String appDir = getApplicationContext().getFilesDir().getAbsolutePath();

            new Thread(() -> {
                try {
                    SystemApi.SystemInit_Api(
                            0,
                            CommonConvert.StringToBytes(appDir + "/" + "\0"),
                            MainActivity.this,
                            new ISdkStatue() {
                                @Override
                                public void sdkInitSuccessed() {
                                    Log.d(TAG, "Vanstone SDK initialized.");
                                    try {
                                        initializeEMVLibraries();
                                        sdkInitialized = true;
                                        // No native splash overlay to remove
                                    } catch (Exception e) {
                                        Log.e(TAG, "EMV init failed", e);
                                        sdkInitialized = false;
                                        // No native splash overlay to remove
                                    }
                                }
                                @Override
                                public void sdkInitFailed() {
                                    Log.e(TAG, "Vanstone SDK initialization failed.");
                                    sdkInitialized = false;
                                    // No native splash overlay to remove
                                }
                            }
                    );
                } catch (Throwable e) {
                    Log.e(TAG, "Throwable during SDK init", e);
                    sdkInitialized = false;
                    // No native splash overlay to remove
                }
            }).start();
        } catch (Throwable e) {
            Log.e(TAG, "Failed to start SDK initialization (throwable)", e);
            sdkInitialized = false;
            // No native splash overlay to remove
        }
    }

    // Removed native overlay splash; Flutter handles splash screen now.

    private void initializeEMVLibraries() {
        // Minimal CPACE setup; adjust as needed
        CPACE_APPLIST app = new CPACE_APPLIST();
        CPACE.ClearApp_Api();

        System.arraycopy(new byte[]{(byte) 0xA0, 0x00, 0x00, 0x07, 0x79, 0x00, 0x00}, 0, app.AID, 0, 7);
        app.AidLen = 7;
        app.SelFlag = Common.FULL_MATCH;
        System.arraycopy(new byte[]{0x00, 0x10}, 0, app.Version, 0, 2);
        System.arraycopy(new byte[]{0x04, 0x00, 0x00, 0x05, 0x00, 0x0C}, 0, app.TACDenial, 0, 5);
        System.arraycopy(new byte[]{0x04, 0x00, 0x00, 0x05, 0x00, 0x0C}, 0, app.TACOnline, 0, 5);
        System.arraycopy(new byte[]{0x04, 0x00, 0x00, 0x03, 0x00, 0x0C}, 0, app.TACDefault, 0, 5);
        app.CVMCapabilityCVM = 0x60;
        app.CVMCapabilityNoCVM = 0x08;
        app.KernelID = 0x2E;
        app.KernelConfig = 0x30;

        CPACE.AddApp_Api(app);
        Log.d(TAG, "EMV/CPACE libraries initialized.");
    }

    private void checkNfcAvailability(MethodChannel.Result result) {
        Log.d(TAG, "NFC availability: " + sdkInitialized);
        result.success(sdkInitialized);
    }

    private void handleNfc(MethodChannel.Result result) {
        new Thread(() -> {
            try {
                int openRes = PiccApi.PiccOpen_Api();
                if (openRes != 0) {
                    runOnUiThread(() -> result.error("NFC_OPEN_FAIL", "Failed to open NFC: " + openRes, null));
                    return;
                }

                byte[] CardType = new byte[2];
                byte[] SerialNo = new byte[20];

                long startTime = System.currentTimeMillis();
                long timeout = 30000;

                while (System.currentTimeMillis() - startTime < timeout) {
                    // Use mode 3 to broadly detect PICC (matches working implementations)
                    int detectRes = PiccApi.PiccCheck_Api(3, CardType, SerialNo);
                    if (detectRes == 0) {
                        try { SystemApi.Beep_Api(1); } catch (Exception ignored) {}

                        Map<String, Object> map = new HashMap<>();
                        map.put("timestamp", System.currentTimeMillis());
                        map.put("device", "AISINO_A75");
                        map.put("uid_raw", bytesToHex(SerialNo));
                        map.put("cardType_raw", bytesToHex(CardType));

                        // Read 19-digit PAN from sector 0, block 1 (default key or derived)
                        String pan = readPanFromMifareBlock1(SerialNo);
                        if (pan != null) {
                            map.put("pan", pan);
                        } else {
                            map.put("pan_error", "PAN read failed");
                        }

                        try { PiccApi.PiccClose_Api(); } catch (Exception ignored) {}
                        runOnUiThread(() -> result.success(map));
                        return;
                    }
                    Thread.sleep(150);
                }

                try { PiccApi.PiccClose_Api(); } catch (Exception ignored) {}
                runOnUiThread(() -> result.error("NFC_TIMEOUT", "No NFC card detected within timeout", null));

            } catch (Exception e) {
                Log.e(TAG, "NFC error", e);
                try { PiccApi.PiccClose_Api(); } catch (Exception ignored) {}
                runOnUiThread(() -> result.error("NFC_ERROR", e.getMessage(), null));
            }
        }).start();
    }

    // Auth helper: try default Key A; if that fails, derive sector key and auth sector base block
    private boolean authoriseForBlock(int blockNo, byte[] serialNo) {
        try {
            // 1) Try default Key A for this block
            byte[] defaultKey = CommonConvert.ascStringToBCD(DEFAULT_KEY_ASC);
            int auth = PiccApi.M1Authority_Api(KEY_TYPE_A, blockNo, defaultKey);
            if (auth == 0) return true;

            // 2) Fallback: derive sector key (using serial and sector) and auth sector base block
            int sectorNo = blockNo / 4;
            int sectorBaseBlock = sectorNo * 4;
            byte[] sectorKey = deriveSectorKey(serialNo, sectorNo);
            if (sectorKey == null) return false;

            int auth2 = PiccApi.M1Authority_Api(KEY_TYPE_A, sectorBaseBlock, sectorKey);
            return auth2 == 0;

        } catch (Exception e) {
            Log.e(TAG, "authoriseForBlock error", e);
            return false;
        }
    }

    // Derive 16-byte sector key: [serial(4 bytes from index 1)] [sector(1byte)] [B0B1B2(3bytes)] + zeros → DES with PED MK
    private byte[] deriveSectorKey(byte[] serialNo, int sectorNo) {
        try {
            byte[] keyPlain = new byte[16]; // zero-filled
            // Copy 4 bytes of serial starting at offset 1
            System.arraycopy(serialNo, 1, keyPlain, 0, 4);
            // Sector number, low byte
            keyPlain[4] = CommonConvert.longToBytes(sectorNo)[0];
            // Append 'B0B1B2' as BCD
            byte[] tag = CommonConvert.ascStringToBCD("B0B1B2");
            System.arraycopy(tag, 0, keyPlain, 5, 3);

            byte[] keyEncrypted = new byte[16];
            int desRes = PedApi.PEDDes_Api(MK_INDEX, SAVE_MK_MODE, MK_MODE, keyPlain, keyPlain.length, keyEncrypted);
            if (desRes != 0) {
                Log.e(TAG, "PEDDes failed: " + desRes);
                return null;
            }
            return keyEncrypted;
        } catch (Exception e) {
            Log.e(TAG, "deriveSectorKey error", e);
            return null;
        }
    }

    // Read 19-digit PAN from sector 0, block 1 (BCD → ASCII, take 19)
    private String readPanFromMifareBlock1(byte[] serialNo) {
        try {
            int blockNo = 1; // sector 0, block 1
            if (!authoriseForBlock(blockNo, serialNo)) {
                Log.e(TAG, "Auth failed for block 1 (default + derived).");
                return null;
            }
            byte[] blk = new byte[16];
            int res = PiccApi.M1ReadBlock_Api(blockNo, blk);
            if (res != 0) {
                Log.e(TAG, "Read failed for block 1, res=" + res);
                return null;
            }
            String asc = CommonConvert.bcdToASCString(blk);
            if (asc == null || asc.length() < TAPCARD_PAN_LENGTH) {
                Log.e(TAG, "Block content too short for PAN: " + asc);
                return null;
            }
            String pan = asc.substring(0, TAPCARD_PAN_LENGTH);
            Log.d(TAG, "PAN: " + pan);
            return pan;
        } catch (Exception e) {
            Log.e(TAG, "readPanFromMifareBlock1 error", e);
            return null;
        }
    }

    // Optional: generic block read using same auth fallback
    private String readMifareBlock(int sector, int block, byte[] serialNo) {
        try {
            int absoluteBlock = sector * 4 + block;
            if (!authoriseForBlock(absoluteBlock, serialNo)) {
                Log.e(TAG, "Auth failed for sector " + sector + " block " + block);
                return null;
            }
            byte[] data = new byte[16];
            int res = PiccApi.M1ReadBlock_Api(absoluteBlock, data);
            if (res == 0) return bytesToHex(data);
            Log.e(TAG, "Read failed for sector " + sector + " block " + block + " res=" + res);
            return null;
        } catch (Exception e) {
            Log.e(TAG, "readMifareBlock error", e);
            return null;
        }
    }

    private void handleChip(MethodChannel.Result result) {
        new Thread(() -> {
            try {
                int detectRes = IcApi.IccDetect_Api(0);
                if (detectRes == 0) {
                    try { SystemApi.Beep_Api(1); } catch (Exception ignored) {}
                    Map<String, Object> cardData = new HashMap<>();
                    cardData.put("cardType", "CHIP");
                    cardData.put("detected", true);
                    cardData.put("timestamp", System.currentTimeMillis());
                    cardData.put("device", "AISINO_A75");
                    runOnUiThread(() -> result.success(cardData));
                } else {
                    runOnUiThread(() -> result.error("CHIP_NOT_DETECTED", "No chip card detected", null));
                }
            } catch (Exception e) {
                Log.e(TAG, "Chip error", e);
                runOnUiThread(() -> result.error("CHIP_ERROR", "Chip error: " + e.getMessage(), null));
            }
        }).start();
    }

    private void handleMagstripe(MethodChannel.Result result) {
        new Thread(() -> {
            try {
                MagCardApi.MagClose_Api();
                MagCardApi.MagOpen_Api();
                MagCardApi.MagReset_Api();

                byte[] CardData = new byte[1024];
                byte[] usCardLenAddr = new byte[4];

                long startTime = System.currentTimeMillis();
                long timeout = 30000;

                while (System.currentTimeMillis() - startTime < timeout) {
                    int readRes = MagCardApi.MagRead_Api(CardData, usCardLenAddr);
                    if (readRes == 0x31) {
                        try { SystemApi.Beep_Api(1); } catch (Exception ignored) {}
                        String trackData = new String(CardData).trim();

                        Map<String, Object> cardData = new HashMap<>();
                        cardData.put("cardType", "MAGSTRIPE");
                        cardData.put("trackData", trackData.substring(0, Math.min(trackData.length(), 100)));
                        cardData.put("timestamp", System.currentTimeMillis());
                        cardData.put("device", "AISINO_A75");

                        MagCardApi.MagClose_Api();
                        runOnUiThread(() -> result.success(cardData));
                        return;
                    }
                    Thread.sleep(150);
                }

                MagCardApi.MagClose_Api();
                runOnUiThread(() -> result.error("MAG_TIMEOUT", "No magnetic stripe card swiped within timeout", null));

            } catch (Exception e) {
                Log.e(TAG, "Magstripe error", e);
                MagCardApi.MagClose_Api();
                runOnUiThread(() -> result.error("MAG_ERROR", "Magstripe error: " + e.getMessage(), null));
            }
        }).start();
    }

    private void handlePrintBalanceReceipt(Map<String, Object> args, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                String stationName = safeStr(args.get("stationName"));
                String address = safeStr(args.get("address"));
                String phone = safeStr(args.get("phone"));
                String date = safeStr(args.get("date"));
                String time = safeStr(args.get("time"));
                String title = safeStr(args.get("title"));
                String cardNo = safeStr(args.get("cardNo"));

                // items: List<Map<String, String>> with keys: currency, balance
                java.util.List items = (java.util.List) args.get("items");
                java.util.List<Map<String, String>> list = new java.util.ArrayList<>();
                if (items != null) {
                    for (Object o : items) {
                        try {
                            Map m = (Map) o;
                            Map<String, String> row = new HashMap<>();
                            Object c = m.get("currency");
                            Object b = m.get("balance");
                            row.put("currency", c == null ? "" : String.valueOf(c));
                            row.put("balance", b == null ? "" : String.valueOf(b));
                            list.add(row);
                        } catch (Exception ignore) {}
                    }
                }

                printBalanceReceipt(title.isEmpty() ? "CARD BALANCE ENQUIRY" : title,
                        stationName, address, phone, date, time, cardNo, list);
                runOnUiThread(() -> result.success(true));
            } catch (Exception e) {
                Log.e(TAG, "handlePrintBalanceReceipt error", e);
                runOnUiThread(() -> result.error("PRINT_ERROR", e.getMessage(), null));
            }
        }).start();
    }

    private void handlePin(MethodChannel.Result result) {
        Map<String, Object> pinData = new HashMap<>();
        pinData.put("status", "PIN_NOT_IMPLEMENTED");
        pinData.put("message", "PIN entry requires complex callback implementation");
        result.success(pinData);
    }

    private String bytesToHex(byte[] bytes) {
        if (bytes == null) return "";
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) sb.append(String.format("%02X", b));
        return sb.toString();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        try {
            PiccApi.PiccClose_Api();
            MagCardApi.MagClose_Api();
        } catch (Exception e) {
            Log.e(TAG, "Error closing APIs", e);
        }
    }

    private void handleTestPrint(Map<String, Object> args, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                String stationName = (String) args.get("stationName");
                String address = (String) args.get("address");
                String phone = (String) args.get("phone");
                String date = (String) args.get("date");
                String time = (String) args.get("time");
                String pumpNo = (String) args.get("pumpNo");
                String product = (String) args.get("product");
                String unit = (String) args.get("unit");
                String litres = (String) args.get("litres");
                String pricePerLitre = (String) args.get("pricePerLitre");
                String total = (String) args.get("total");
                String payment = (String) args.get("payment");
                String cardNo = (String) args.get("cardNo");
                String authNo = (String) args.get("authNo");
                String rrn = (String) args.get("rrn");
                String operatorName = (String) args.get("operator");

                if (unit == null || unit.trim().isEmpty()) unit = "L";

                printReceipt("MERCHANT COPY", stationName, address, phone, date, time,
                        pumpNo, operatorName, product, unit, litres, pricePerLitre, total, payment,
                        cardNo, authNo, rrn);

                printReceipt("CUSTOMER COPY", stationName, address, phone, date, time,
                        pumpNo, operatorName, product, unit, litres, pricePerLitre, total, payment,
                        cardNo, authNo, rrn);

                runOnUiThread(() -> result.success("Merchant & Customer receipts printed"));
            } catch (Exception e) {
                runOnUiThread(() -> result.error("PRINT_EXCEPTION", e.getMessage(), null));
            }
        }).start();
    }

    private void handlePrintReceiptCopy(Map<String, Object> args, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                String copyType = (String) args.get("copyType");
                String stationName = (String) args.get("stationName");
                String address = (String) args.get("address");
                String phone = (String) args.get("phone");
                String date = (String) args.get("date");
                String time = (String) args.get("time");
                String pumpNo = (String) args.get("pumpNo");
                String product = (String) args.get("product");
                String unit = (String) args.get("unit");
                String litres = (String) args.get("litres");
                String pricePerLitre = (String) args.get("pricePerLitre");
                String total = (String) args.get("total");
                String payment = (String) args.get("payment");
                String cardNo = (String) args.get("cardNo");
                String authNo = (String) args.get("authNo");
                String rrn = (String) args.get("rrn");
                String operatorName = (String) args.get("operator");

                if (unit == null || unit.trim().isEmpty()) unit = "L";

                printReceipt(copyType, stationName, address, phone, date, time,
                        pumpNo, operatorName, product, unit, litres, pricePerLitre, total, payment,
                        cardNo, authNo, rrn);

                runOnUiThread(() -> result.success(copyType + " printed"));
            } catch (Exception e) {
                runOnUiThread(() -> result.error("PRINT_EXCEPTION", e.getMessage(), null));
            }
        }).start();
    }

    private void printReceipt(String copyType, String stationName, String address, String phone,
                              String date, String time, String pumpNo, String operatorName,
                              String product, String unit, String litres, String pricePerLitre, String total,
                              String payment, String cardNo, String authNo, String rrn) {

        PrinterApi.PrnClrBuff_Api();
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnSetGray_Api(15);
        PrinterApi.PrnLineSpaceSet_Api((short) 5, 0);

        // Print logo
        Bitmap logoBitmap = loadScaledLogo();
        printCenteredLogo(logoBitmap);
        PrinterApi.PrnStr_Api("\n");

        PrinterApi.PrnStr_Api(centerText("=== RECEIPT ==="));
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api("Station: " + stationName);
//        PrinterApi.PrnStr_Api("Address: " + address);
        PrinterApi.PrnStr_Api("Tel: " + phone);
        PrinterApi.PrnStr_Api("--------------------------------");
        PrinterApi.PrnStr_Api("DATE: " + date + "   TIME: " + time);
        if (operatorName != null && !operatorName.trim().isEmpty()) {
            PrinterApi.PrnStr_Api("Operator: " + operatorName);
        }
        PrinterApi.PrnStr_Api("Product: " + product);
        PrinterApi.PrnStr_Api("Qty (" + unit + "): " + litres);
        PrinterApi.PrnStr_Api("Price/" + unit + ": " + pricePerLitre);
        PrinterApi.PrnStr_Api("--------------------------------");
        PrinterApi.PrnFontSet_Api(32, 32, 0);
        PrinterApi.PrnStr_Api("TOTAL: " + total);
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnStr_Api("--------------------------------");
        PrinterApi.PrnStr_Api("Payment: " + payment);
        PrinterApi.PrnStr_Api("Card No: " + cardNo);
        PrinterApi.PrnStr_Api("Auth No: " + authNo);
        PrinterApi.PrnStr_Api("RRN: " + rrn);
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api(centerText("*** Thank You ***"));
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api(centerText("---- " + copyType + " ----"));
        PrinterApi.PrnStr_Api("\n\n\n");
        PrinterApi.PrnStart_Api();
    }

    private void printBalanceReceipt(String title, String stationName, String address, String phone,
                                     String date, String time, String cardNo,
                                     java.util.List<Map<String, String>> items) {
        PrinterApi.PrnClrBuff_Api();
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnSetGray_Api(15);
        PrinterApi.PrnLineSpaceSet_Api((short) 5, 0);

        // Print logo
        Bitmap logoBitmap = loadScaledLogo();
        printCenteredLogo(logoBitmap);
        PrinterApi.PrnStr_Api("\n");

        // Header
        PrinterApi.PrnStr_Api(centerText("=== " + title + " ==="));
        PrinterApi.PrnStr_Api("\n");
        if (stationName != null && !stationName.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText(stationName));
        }
        if (address != null && !address.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText(address));
        }
        if (phone != null && !phone.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText("Tel: " + phone));
        }
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api("DATE: " + date + "   TIME: " + time);
        if (cardNo != null && !cardNo.isEmpty()) {
            PrinterApi.PrnStr_Api("Card: " + cardNo);
        }
        PrinterApi.PrnStr_Api("--------------------------------");

        // Body: currency balances
        if (items != null && !items.isEmpty()) {
            for (Map<String, String> row : items) {
                String cur = safeStr(row.get("currency"));
                String bal = safeStr(row.get("balance"));
                if (cur == null) cur = "";
                if (bal == null) bal = "";
                String line = cur + ": " + bal;
                PrinterApi.PrnStr_Api(line);
            }
        } else {
            PrinterApi.PrnStr_Api("No balances available");
        }

        // Footer
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api(centerText("--- END OF ENQUIRY ---"));
        PrinterApi.PrnStr_Api("\n\n\n");
        PrinterApi.PrnStart_Api();
    }

    private void handleBatchCutOffReceipt(Map<String, Object> args, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                String title = safeStr(args.get("title")); // BATCH CUT OFF
                Map<String, Object> attendant = (Map<String, Object>) args.get("attendant");
                Map<String, Object> device = (Map<String, Object>) args.get("device");
                Map<String, Object> summary = (Map<String, Object>) args.get("summary");
                String operatorCode = safeStr(args.get("operatorCode"));
                java.util.List<Map<String, String>> items = (java.util.List<Map<String, String>>) args.get("items");

                // Fallbacks if attendant/device missing
                String stationName = attendant != null ? safeStr(attendant.get("service_station_name")) : safeStr(args.get("stationName"));
                String operatorName = "";
                String attendantId = "";
                if (attendant != null) {
                    operatorName = (safeStr(attendant.get("first_name")) + " " + safeStr(attendant.get("last_name"))).trim();
                    attendantId = safeStr(attendant.get("id"));
                }
                String serialNumber = device != null ? safeStr(device.get("serial_number")) : "";
                String terminalId = device != null ? safeStr(device.get("terminal_id")) : "";

                printBatchCutoff(title, stationName, operatorName, attendantId, operatorCode, serialNumber, terminalId, items, summary);
                runOnUiThread(() -> result.success("batch cutoff printed"));
            } catch (Exception e) {
                Log.e(TAG, "BatchCutOff print error", e);
                runOnUiThread(() -> result.error("PRINT_EXCEPTION", e.getMessage(), null));
            }
        }).start();
    }

    private void printBatchCutoff(String title,
                                  String stationName,
                                  String operatorName,
                                  String attendantId,
                                  String operatorCode,
                                  String serialNumber,
                                  String terminalId,
                                  java.util.List<Map<String, String>> items,
                                  Map<String, Object> summary) {
        PrinterApi.PrnClrBuff_Api();
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnSetGray_Api(15);
        PrinterApi.PrnLineSpaceSet_Api((short) 5, 0);

        // Print logo
        Bitmap logoBitmap = loadScaledLogo();
        printCenteredLogo(logoBitmap);
        PrinterApi.PrnStr_Api("\n");

        // Header
        PrinterApi.PrnStr_Api(centerText("=== " + (title == null || title.isEmpty() ? "BATCH CUT OFF" : title) + " ==="));
        PrinterApi.PrnStr_Api("\n");
        if (stationName != null && !stationName.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText(stationName));
        }
        if (operatorName != null && !operatorName.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText("Operator: " + operatorName));
        }
        if (attendantId != null && !attendantId.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText("Attendant ID: " + attendantId));
        }
        if ((serialNumber != null && !serialNumber.isEmpty()) || (terminalId != null && !terminalId.isEmpty())) {
            PrinterApi.PrnStr_Api(centerText("SN: " + safeStr(serialNumber) + "   TID: " + safeStr(terminalId)));
        }
        PrinterApi.PrnStr_Api("\n");

        // Batch summary
        String totalQty = summary != null ? safeStr(summary.get("total_quantity_kgs")) : "";
        String txnCount = summary != null ? safeStr(summary.get("transaction_count")) : "";
        if (totalQty != null && !totalQty.isEmpty()) {
            PrinterApi.PrnStr_Api("Total Qty: " + totalQty + " Kgs");
        }
        if (txnCount != null && !txnCount.isEmpty()) {
            PrinterApi.PrnStr_Api("Transaction Count: " + txnCount);
        }
        if ((totalQty != null && !totalQty.isEmpty()) || (txnCount != null && !txnCount.isEmpty())) {
            PrinterApi.PrnStr_Api("--------------------------------");
        }

        // Transactions
        PrinterApi.PrnStr_Api("--------------------------------");
        LinkedHashMap<String, BigDecimal> totals = new LinkedHashMap<>();
        if (items != null && !items.isEmpty()) {
            for (Map<String, String> row : items) {
                String txn = firstNonEmpty(row.get("transaction_number"), row.get("txn"));
                String dt  = firstNonEmpty(row.get("transaction_date"), row.get("date"));
                String amt = safeStr(row.get("amount"));
                String cur = firstNonEmpty(row.get("currency_name"), row.get("currency"));
                String product = safeStr(row.get("product_type_name"));
                String desc = safeStr(row.get("description"));
                String status = safeStr(row.get("status"));
                String qtyKgs = safeStr(row.get("quantity_kgs"));

                if (txn != null && !txn.isEmpty()) PrinterApi.PrnStr_Api("TXN: " + txn);
                if (dt != null && !dt.isEmpty())   PrinterApi.PrnStr_Api("Date: " + dt);
                if (product != null && !product.isEmpty()) PrinterApi.PrnStr_Api("Product: " + product);
                if (qtyKgs != null && !qtyKgs.isEmpty()) PrinterApi.PrnStr_Api("Qty: " + qtyKgs + " Kgs");
                if (desc != null && !desc.isEmpty()) PrinterApi.PrnStr_Api("Description: " + desc);
                BigDecimal val = parseAmount(amt);
                PrinterApi.PrnStr_Api("Amount: " + formatAmountWithUnit(cur, val));
                if (status != null && !status.isEmpty()) PrinterApi.PrnStr_Api("Status: " + status);
                PrinterApi.PrnStr_Api("--------------------------------");

                // Accumulate totals per currency
                if (cur != null && !cur.isEmpty()) {
                    try {
                        BigDecimal value = parseAmount(amt);
                        totals.put(cur, totals.getOrDefault(cur, BigDecimal.ZERO).add(value));
                    } catch (Exception ignored) { /* skip unparsable amount */ }
                }
            }
        } else {
            PrinterApi.PrnStr_Api("No transactions");
            PrinterApi.PrnStr_Api("--------------------------------");
        }

        // Totals section
        if (!totals.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText("Totals by Currency"));
            for (Map.Entry<String, BigDecimal> e : totals.entrySet()) {
                String line = e.getKey() + ": " + formatAmountWithUnit(e.getKey(), e.getValue());
                PrinterApi.PrnStr_Api(line);
            }
            PrinterApi.PrnStr_Api("--------------------------------");
        }

        // Footer
        PrinterApi.PrnStr_Api(centerText("--- END OF BATCH ---"));
        PrinterApi.PrnStr_Api("\n\n\n");
        PrinterApi.PrnStart_Api();
    }

    private String firstNonEmpty(String a, String b) {
        if (a != null && !a.isEmpty()) return a; 
        if (b != null && !b.isEmpty()) return b; 
        return "";
    }

    private BigDecimal parseAmount(String amt) {
        try {
            if (amt == null || amt.trim().isEmpty()) return BigDecimal.ZERO;
            return new BigDecimal(amt.trim());
        } catch (Exception e) {
            return BigDecimal.ZERO;
        }
    }

    private String formatAmountWithUnit(String currency, BigDecimal value) {
        if (value == null) value = BigDecimal.ZERO;
        DecimalFormat df = new DecimalFormat("0.00");
        String amount = df.format(value);
        String cur = currency == null ? "" : currency.trim();
        boolean isPTL = cur.equalsIgnoreCase("PTL");
        boolean isDSL = cur.equalsIgnoreCase("DSL");
        boolean isLPG = cur.equalsIgnoreCase("LPG");

        if (isPTL || isDSL) {
            return amount + " L";
        }
        if (isLPG) {
            // LPG amounts are shown in kilograms
            return amount + " KG";
        }
        // Default: prefix with dollar sign
        return "$" + amount;
    }

    private String safeStr(Object o) { return o == null ? "" : String.valueOf(o); }

    private String centerText(String text) {
        int lineWidth = 32;
        if (text.length() >= lineWidth) return text;
        int padding = (lineWidth - text.length()) / 2;
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < padding; i++) sb.append(" ");
        sb.append(text);
        return sb.toString();
    }

    private void handleLastSaleReceipt(Map<String, Object> args, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                String title = safeStr(args.get("title"));
                String stationName = safeStr(args.get("stationName"));
                String address = safeStr(args.get("address"));
                String phone = safeStr(args.get("phone"));
                String date = safeStr(args.get("date"));
                String time = safeStr(args.get("time"));
                String pumpNo = safeStr(args.get("pumpNo"));
                String product = safeStr(args.get("product"));
                String unit = safeStr(args.get("unit"));
                String litres = safeStr(args.get("litres"));
                String pricePerLitre = safeStr(args.get("pricePerLitre"));
                String total = safeStr(args.get("total"));
                String payment = safeStr(args.get("payment"));
                String cardNo = safeStr(args.get("cardNo"));
                String authNo = safeStr(args.get("authNo"));
                String rrn = safeStr(args.get("rrn"));

                printSingleReceipt(title, stationName, address, phone, date, time,
                        pumpNo, product, unit, litres, pricePerLitre, total, payment, cardNo, authNo, rrn);
                runOnUiThread(() -> result.success("last sale printed"));
            } catch (Exception e) {
                Log.e(TAG, "LastSale print error", e);
                runOnUiThread(() -> result.error("PRINT_EXCEPTION", e.getMessage(), null));
            }
        }).start();
    }

    private void printSingleReceipt(String title, String stationName, String address, String phone,
                                    String date, String time, String pumpNo,
                                    String product, String unit, String litres, String pricePerLitre, String total,
                                    String payment, String cardNo, String authNo, String rrn) {
        PrinterApi.PrnClrBuff_Api();
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnSetGray_Api(15);
        PrinterApi.PrnLineSpaceSet_Api((short) 5, 0);

        // Print logo
        Bitmap logoBitmap = loadScaledLogo();
        printCenteredLogo(logoBitmap);
        PrinterApi.PrnStr_Api("\n");

        // Header with custom title
        if (title == null || title.trim().isEmpty()) title = "LAST SALE TRANSACTION";
        PrinterApi.PrnStr_Api(centerText("=== " + title + " ==="));
        PrinterApi.PrnStr_Api("\n");
        if (stationName != null && !stationName.isEmpty()) PrinterApi.PrnStr_Api("Station: " + stationName);
        PrinterApi.PrnStr_Api("--------------------------------");
        PrinterApi.PrnStr_Api("DATE: " + date + "   TIME: " + time);
        if (pumpNo != null && !pumpNo.trim().isEmpty()) PrinterApi.PrnStr_Api("Pump: " + pumpNo);
        if (product != null && !product.trim().isEmpty()) PrinterApi.PrnStr_Api("Product: " + product);
        if (unit == null || unit.trim().isEmpty()) unit = "L";
        PrinterApi.PrnStr_Api("Qty (" + unit + "): " + litres);
        PrinterApi.PrnStr_Api("Price/" + unit + ": " + pricePerLitre);
        PrinterApi.PrnStr_Api("--------------------------------");
        PrinterApi.PrnFontSet_Api(32, 32, 0);
        PrinterApi.PrnStr_Api("TOTAL: " + total);
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnStr_Api("--------------------------------");
        PrinterApi.PrnStr_Api("Payment: " + payment);
        if (cardNo != null && !cardNo.isEmpty()) PrinterApi.PrnStr_Api("Card No: " + cardNo);
        if (authNo != null && !authNo.isEmpty()) PrinterApi.PrnStr_Api("Auth No: " + authNo);
        if (rrn != null && !rrn.isEmpty()) PrinterApi.PrnStr_Api("RRN: " + rrn);
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api(centerText("--- END OF RECEIPT ---"));
        PrinterApi.PrnStr_Api("\n\n\n");
        PrinterApi.PrnStart_Api();
    }

    private void handleBatchAuditReceipt(Map<String, Object> args, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                String title = safeStr(args.get("title")); // BATCH AUDIT
                Map<String, Object> attendant = (Map<String, Object>) args.get("attendant");
                Map<String, Object> device = (Map<String, Object>) args.get("device");
                Map<String, Object> summary = (Map<String, Object>) args.get("summary");
                String time = safeStr(args.get("time"));
                java.util.List<Map<String, String>> items = (java.util.List<Map<String, String>>) args.get("items");

                String stationName = attendant != null ? safeStr(attendant.get("service_station_name")) : "";
                String operatorName = "";
                String attendantId = "";
                if (attendant != null) {
                    operatorName = (safeStr(attendant.get("first_name")) + " " + safeStr(attendant.get("last_name"))).trim();
                    attendantId = safeStr(attendant.get("id"));
                }
                String serialNumber = device != null ? safeStr(device.get("serial_number")) : "";
                String terminalId = device != null ? safeStr(device.get("terminal_id")) : "";

                printBatchAudit(title, stationName, operatorName, attendantId, serialNumber, terminalId, time, items, summary);
                runOnUiThread(() -> result.success("batch audit printed"));
            } catch (Exception e) {
                Log.e(TAG, "BatchAudit print error", e);
                runOnUiThread(() -> result.error("PRINT_EXCEPTION", e.getMessage(), null));
            }
        }).start();
    }

    private void printBatchAudit(String title,
                                 String stationName,
                                 String operatorName,
                                 String attendantId,
                                 String serialNumber,
                                 String terminalId,
                                 String time,
                                 java.util.List<Map<String, String>> items,
                                 Map<String, Object> summary) {
        PrinterApi.PrnClrBuff_Api();
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnSetGray_Api(15);
        PrinterApi.PrnLineSpaceSet_Api((short) 5, 0);

        // Print logo
        Bitmap logoBitmap = loadScaledLogo();
        printCenteredLogo(logoBitmap);
        PrinterApi.PrnStr_Api("\n");

        // Header
        if (title == null || title.isEmpty()) title = "BATCH AUDIT";
        PrinterApi.PrnStr_Api(centerText("=== " + title + " ==="));
        PrinterApi.PrnStr_Api("\n");
        if (stationName != null && !stationName.isEmpty()) PrinterApi.PrnStr_Api(centerText(stationName));
        if (operatorName != null && !operatorName.isEmpty()) PrinterApi.PrnStr_Api(centerText("Operator: " + operatorName));
        if (attendantId != null && !attendantId.isEmpty()) PrinterApi.PrnStr_Api(centerText("Attendant ID: " + attendantId));
        if ((serialNumber != null && !serialNumber.isEmpty()) || (terminalId != null && !terminalId.isEmpty())) {
            PrinterApi.PrnStr_Api(centerText("SN: " + safeStr(serialNumber) + "   TID: " + safeStr(terminalId)));
        }
        if (time != null && !time.isEmpty()) PrinterApi.PrnStr_Api(centerText(time));
        if (summary != null) {
            String totalQty = safeStr(summary.get("total_quantity_kgs"));
            String recordCount = safeStr(summary.get("record_count"));
            if (totalQty != null && !totalQty.isEmpty()) PrinterApi.PrnStr_Api("Total Qty: " + totalQty + " Kgs");
            if (recordCount != null && !recordCount.isEmpty()) PrinterApi.PrnStr_Api("Record Count: " + recordCount);
        }
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api("--------------------------------");

        // Body rows and totals
        LinkedHashMap<String, BigDecimal> totalsValue = new LinkedHashMap<>();
        LinkedHashMap<String, BigDecimal> totalsKgs = new LinkedHashMap<>();

        if (items != null && !items.isEmpty()) {
            for (Map<String, String> row : items) {
                String type = safeStr(row.get("transaction_type_name"));
                String curName = safeStr(row.get("currency_name"));
                String curSymbol = safeStr(row.get("currency_symbol"));
                BigDecimal kgs = parseAmount(safeStr(row.get("total_quantity_kgs")));
                BigDecimal value = parseAmount(safeStr(row.get("total_value")));

                // Line group for each summary row
                String header = (type.isEmpty() ? "" : type) + (curName.isEmpty() ? "" : (headerNeedsSpace(type) ? " " : "") + "(" + curName + ")");
                if (!header.trim().isEmpty()) PrinterApi.PrnStr_Api(header.trim());
                PrinterApi.PrnStr_Api("Kgs: " + new java.text.DecimalFormat("0.00").format(kgs) + " Kgs");
                String valStr = (curSymbol.isEmpty() ? "$" : curSymbol) + new java.text.DecimalFormat("0.00").format(value);
                PrinterApi.PrnStr_Api("Value: " + valStr);
                PrinterApi.PrnStr_Api("--------------------------------");

                // Accumulate totals
                String key = curName.isEmpty() ? "UNKNOWN" : curName;
                totalsValue.put(key, totalsValue.getOrDefault(key, BigDecimal.ZERO).add(value));
                totalsKgs.put(key, totalsKgs.getOrDefault(key, BigDecimal.ZERO).add(kgs));
            }
        } else {
            PrinterApi.PrnStr_Api("No data");
            PrinterApi.PrnStr_Api("--------------------------------");
        }

        // Totals section
        if (!totalsValue.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText("Totals"));
            for (Map.Entry<String, BigDecimal> e : totalsValue.entrySet()) {
                BigDecimal v = e.getValue();
                BigDecimal k = totalsKgs.getOrDefault(e.getKey(), BigDecimal.ZERO);
                String line = e.getKey() + ": " + new java.text.DecimalFormat("0.00").format(k) + " Kgs, " + "$" + new java.text.DecimalFormat("0.00").format(v);
                PrinterApi.PrnStr_Api(line);
            }
            PrinterApi.PrnStr_Api("--------------------------------");
        }

        // Footer
        PrinterApi.PrnStr_Api(centerText("--- END OF AUDIT ---"));
        PrinterApi.PrnStr_Api("\n\n\n");
        PrinterApi.PrnStart_Api();
    }

    private boolean headerNeedsSpace(String type) {
        return type != null && !type.isEmpty();
    }

    // IMEI best-effort (Android 10+ restrictions apply)
    private String getImeiSafe() {
        try {
            Context ctx = getApplicationContext();
            TelephonyManager tm = (TelephonyManager) ctx.getSystemService(Context.TELEPHONY_SERVICE);
            if (tm == null) return null;

            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
                Log.w(TAG, "READ_PHONE_STATE not granted; cannot read IMEI");
                return null;
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                return null;
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    return tm.getImei();
                } catch (SecurityException se) {
                    Log.w(TAG, "SecurityException reading IMEI on O+", se);
                    return null;
                }
            } else {
                try {
                    return tm.getDeviceId();
                } catch (SecurityException se) {
                    Log.w(TAG, "SecurityException reading deviceId pre-O", se);
                    return null;
                }
            }
        } catch (Throwable t) {
            Log.e(TAG, "Error reading IMEI", t);
            return null;
        }
    }

    private String readPosType() {
        return "A75";
    }

    private String getSerialNumberSafe() {
        try {
            String[] keys = new String[] {"ro.serialno", "ro.boot.serialno", "sys.serialnumber", "ril.serialnumber"};
            Class<?> c = Class.forName("android.os.SystemProperties");
            Method get = c.getMethod("get", String.class, String.class);
            for (String key : keys) {
                String v = (String) get.invoke(c, key, "");
                if (v != null && !v.trim().isEmpty() && !"unknown".equalsIgnoreCase(v)) {
                    return v;
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                try {
                    return Build.getSerial();
                } catch (SecurityException se) {
                    Log.w(TAG, "Build.getSerial requires privileged permission", se);
                    return null;
                }
            } else {
                String s = Build.SERIAL;
                if (s != null && !s.trim().isEmpty() && !"unknown".equalsIgnoreCase(s)) {
                    return s;
                }
            }
        } catch (Throwable t) {
            Log.e(TAG, "Error reading serial number", t);
        }
        return null;
    }

    private void handlePrintQRCodeReceipt(Map<String, Object> args, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                String title = safeStr(args.get("title"));
                String qrData = safeStr(args.get("qrData"));
                String requestCode = safeStr(args.get("requestCode"));
                String stationName = safeStr(args.get("stationName"));
                String address = safeStr(args.get("address"));
                String phone = safeStr(args.get("phone"));
                String date = safeStr(args.get("date"));
                String time = safeStr(args.get("time"));
                String status = safeStr(args.get("status"));
                String description = safeStr(args.get("description"));
                String cylinderCount = safeStr(args.get("cylinderCount"));
                String cylinderDetails = safeStr(args.get("cylinderDetails"));
                String createdBy = safeStr(args.get("createdBy"));

                printQRCodeReceipt(title, qrData, requestCode, stationName, address, phone,
                                  date, time, status, description, cylinderCount,
                                  cylinderDetails, createdBy);
                runOnUiThread(() -> result.success("QR code receipt printed"));
            } catch (Exception e) {
                Log.e(TAG, "QR code print error", e);
                runOnUiThread(() -> result.error("PRINT_EXCEPTION", e.getMessage(), null));
            }
        }).start();
    }

    private void printQRCodeReceipt(String title, String qrData, String requestCode,
                                   String stationName, String address, String phone,
                                   String date, String time, String status, String description,
                                   String cylinderCount, String cylinderDetails, String createdBy) {
        PrinterApi.PrnClrBuff_Api();
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnSetGray_Api(15);
        PrinterApi.PrnLineSpaceSet_Api((short) 5, 0);

        // Print logo
        Bitmap logoBitmap = loadScaledLogo();
        printCenteredLogo(logoBitmap);

        // Generate and print QR code as image
        try {
            Bitmap qrBitmap = generateQrCode(qrData);
            PrinterApi.PrnLogo_Api(qrBitmap);
        } catch (WriterException e) {
            Log.e(TAG, "Failed to generate QR code", e);
            // Fallback to text if QR generation fails
            PrinterApi.PrnStr_Api(centerText("QR CODE:"));
            PrinterApi.PrnStr_Api(centerText(qrData));
        }
        PrinterApi.PrnFontSet_Api(28, 28, 0);
        PrinterApi.PrnStr_Api(requestCode);
        PrinterApi.PrnStr_Api("\n\n\n\n");
        PrinterApi.PrnStart_Api();
    }

    private void handlePrintPickupReceipt(Map<String, Object> args, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                String requestCode = safeStr(args.get("requestCode"));
                String stationName = safeStr(args.get("stationName"));
                String address = safeStr(args.get("address"));
                String phone = safeStr(args.get("phone"));
                String date = safeStr(args.get("date"));
                String time = safeStr(args.get("time"));
                String driverName = safeStr(args.get("driverName"));
                String cylinderCount = safeStr(args.get("cylinderCount"));
                String cylinderDetails = safeStr(args.get("cylinderDetails"));
                String description = safeStr(args.get("description"));
                String siteName = safeStr(args.get("siteName"));
                String siteCode = safeStr(args.get("siteCode"));

                // Print driver copy
                printPickupReceipt("DRIVER COPY", requestCode, stationName, address, phone,
                                  date, time, driverName, cylinderCount, cylinderDetails,
                                  description, siteName, siteCode);

                // Print attendant copy
                printPickupReceipt("ATTENDANT COPY", requestCode, stationName, address, phone,
                                  date, time, driverName, cylinderCount, cylinderDetails,
                                  description, siteName, siteCode);

                runOnUiThread(() -> result.success("Pickup receipts printed"));
            } catch (Exception e) {
                Log.e(TAG, "Pickup receipt print error", e);
                runOnUiThread(() -> result.error("PRINT_EXCEPTION", e.getMessage(), null));
            }
        }).start();
    }

    private void printPickupReceipt(String copyType, String requestCode, String stationName,
                                   String address, String phone, String date, String time,
                                   String driverName, String cylinderCount, String cylinderDetails,
                                   String description, String siteName, String siteCode) {
        final String detailsLabel = "CYLINDER DETAILS";
        PrinterApi.PrnClrBuff_Api();
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnSetGray_Api(15);
        PrinterApi.PrnLineSpaceSet_Api((short) 5, 0);

        // Print logo
        Bitmap logoBitmap = loadScaledLogo();
        printCenteredLogo(logoBitmap);
        PrinterApi.PrnStr_Api("\n");

        // Header
        PrinterApi.PrnFontSet_Api(28, 28, 0);
        PrinterApi.PrnStr_Api(centerText("PICKUP CONFIRMATION"));
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api(centerText(copyType));
        PrinterApi.PrnStr_Api("\n");

        // Station details
        if (stationName != null && !stationName.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText(stationName));
        }
        if (address != null && !address.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText(address));
        }
        if (phone != null && !phone.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText("Tel: " + phone));
        }
        PrinterApi.PrnStr_Api("--------------------------------");

        // Date and Time
        PrinterApi.PrnStr_Api("DATE: " + date + "   TIME: " + time);
        PrinterApi.PrnStr_Api("--------------------------------");

        // Pickup details
        PrinterApi.PrnStr_Api("Request Code: " + requestCode);
        PrinterApi.PrnStr_Api("Site: " + siteName);
        PrinterApi.PrnStr_Api("Site Code: " + siteCode);
        PrinterApi.PrnStr_Api("Driver: " + driverName);
        PrinterApi.PrnStr_Api("Cylinders: " + cylinderCount);
        PrinterApi.PrnStr_Api("--------------------------------");

        // Cylinder details
        if (cylinderDetails != null && !cylinderDetails.isEmpty()) {
            PrinterApi.PrnStr_Api(detailsLabel + ":");
            PrinterApi.PrnStr_Api("\n");
            String[] lines = cylinderDetails.split("\n");
            for (String line : lines) {
                if (line != null && !line.trim().isEmpty()) {
                    PrinterApi.PrnStr_Api(line.trim());
                }
            }
            PrinterApi.PrnStr_Api("--------------------------------");
        }

        // Footer
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api(centerText("Cylinders picked up"));
        PrinterApi.PrnStr_Api(centerText("for refilling"));
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api(centerText("*** Thank You ***"));
        PrinterApi.PrnStr_Api("\n\n\n");
        PrinterApi.PrnStart_Api();
    }

    private void handlePrintDeliveryReceipt(Map<String, Object> args, MethodChannel.Result result) {
        new Thread(() -> {
            try {
                String requestCode = safeStr(args.get("requestCode"));
                String deliveryCode = safeStr(args.get("deliveryCode"));
                String invoiceNumber = safeStr(args.get("invoiceNumber"));
                String stationName = safeStr(args.get("stationName"));
                String address = safeStr(args.get("address"));
                String phone = safeStr(args.get("phone"));
                String date = safeStr(args.get("date"));
                String time = safeStr(args.get("time"));
                String driverName = safeStr(args.get("driverName"));
                String cylinderCount = safeStr(args.get("cylinderCount"));
                String cylinderDetails = safeStr(args.get("cylinderDetails"));
                String description = safeStr(args.get("description"));
                String siteName = safeStr(args.get("siteName"));
                String siteCode = safeStr(args.get("siteCode"));
                String copyType = safeStr(args.get("copyType"));
                String detailsLabel = safeStr(args.get("detailsLabel"));
                if (detailsLabel == null || detailsLabel.isEmpty()) {
                    detailsLabel = "CYLINDER DETAILS";
                }
                String recipientLabel = safeStr(args.get("recipientLabel"));
                if (recipientLabel == null || recipientLabel.isEmpty()) {
                    recipientLabel = "Customer";
                }

                if (copyType != null && !copyType.isEmpty()) {
                    printDeliveryReceipt(copyType, requestCode, deliveryCode, invoiceNumber,
                                      stationName, address, phone, date, time, driverName,
                                      cylinderCount, cylinderDetails, description, siteName, siteCode, detailsLabel, recipientLabel);
                } else {
                    // Print driver copy
                    printDeliveryReceipt("DRIVER COPY", requestCode, deliveryCode, invoiceNumber,
                                      stationName, address, phone, date, time, driverName,
                                      cylinderCount, cylinderDetails, description, siteName, siteCode, detailsLabel, recipientLabel);

                    // Print attendant copy
                    printDeliveryReceipt("ATTENDANT COPY", requestCode, deliveryCode, invoiceNumber,
                                      stationName, address, phone, date, time, driverName,
                                      cylinderCount, cylinderDetails, description, siteName, siteCode, detailsLabel, recipientLabel);
                }

                runOnUiThread(() -> result.success("Delivery receipts printed"));
            } catch (Exception e) {
                Log.e(TAG, "Delivery receipt print error", e);
                runOnUiThread(() -> result.error("PRINT_EXCEPTION", e.getMessage(), null));
            }
        }).start();
    }

    private void printDeliveryReceipt(String copyType, String requestCode, String deliveryCode,
                                     String invoiceNumber, String stationName, String address,
                                     String phone, String date, String time, String driverName,
                                     String cylinderCount, String cylinderDetails, String description,
                                     String siteName, String siteCode, String detailsLabel, String recipientLabel) {
        PrinterApi.PrnClrBuff_Api();
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnSetGray_Api(15);
        PrinterApi.PrnLineSpaceSet_Api((short) 5, 0);

        // Print logo
        Bitmap logoBitmap = loadScaledLogo();
        printCenteredLogo(logoBitmap);
        PrinterApi.PrnStr_Api("\n");

        // Header
        PrinterApi.PrnFontSet_Api(28, 28, 0);
        PrinterApi.PrnStr_Api(centerText("DELIVERY NOTE"));
        PrinterApi.PrnFontSet_Api(24, 24, 0);
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api(centerText(copyType));
        PrinterApi.PrnStr_Api("\n");

        // Station details
        if (stationName != null && !stationName.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText(stationName));
        }
        if (address != null && !address.isEmpty() && !sameReceiptValue(address, stationName)) {
            PrinterApi.PrnStr_Api(centerText(address));
        }
        if (phone != null && !phone.isEmpty()) {
            PrinterApi.PrnStr_Api(centerText("Tel: " + phone));
        }
        PrinterApi.PrnStr_Api("--------------------------------");

        // Date and Time
        PrinterApi.PrnStr_Api("DATE: " + date + "   TIME: " + time);
        PrinterApi.PrnStr_Api("--------------------------------");

        // Delivery details
        PrinterApi.PrnStr_Api("Order Number: " + requestCode);
        if (invoiceNumber != null && !invoiceNumber.isEmpty() && !invoiceNumber.equals("N/A")) {
            PrinterApi.PrnStr_Api("Invoice No: " + invoiceNumber);
        }
        if (siteName != null && !siteName.isEmpty()) {
            PrinterApi.PrnStr_Api(recipientLabel + ": " + siteName);
        }
        if (siteCode != null && !siteCode.isEmpty()) {
            PrinterApi.PrnStr_Api("Site Code: " + siteCode);
        }
        PrinterApi.PrnStr_Api("Driver: " + driverName);
        PrinterApi.PrnStr_Api("--------------------------------");

        // Cylinder details in table format
        if (cylinderDetails != null && !cylinderDetails.isEmpty()) {
            PrinterApi.PrnStr_Api(detailsLabel + ":");
            PrinterApi.PrnStr_Api(cylinderDetails);
            PrinterApi.PrnStr_Api("--------------------------------");
        }

        // Signature section
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api("Driver Signature: _______________");
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api("Received By: ____________________");
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api("Signature: ______________________");
        PrinterApi.PrnStr_Api("\n");

        // Footer
        PrinterApi.PrnStr_Api("\n");
        PrinterApi.PrnStr_Api(centerText("*** Thank You ***"));
        PrinterApi.PrnStr_Api("\n\n\n");
        PrinterApi.PrnStart_Api();
    }

    private boolean sameReceiptValue(String first, String second) {
        if (first == null || second == null) {
            return false;
        }

        String normalizedFirst = first.trim().replaceAll("\\s+", " ").toLowerCase(Locale.ROOT);
        String normalizedSecond = second.trim().replaceAll("\\s+", " ").toLowerCase(Locale.ROOT);
        return !normalizedFirst.isEmpty() && normalizedFirst.equals(normalizedSecond);
    }

    private Bitmap loadScaledLogo() {
        try {
            Bitmap originalLogo = BitmapFactory.decodeResource(getResources(), R.drawable.logo);
            if (originalLogo != null) {
                // Scale logo to fit thermal paper (200 pixels width for better visibility)
                int targetWidth = 200;
                int targetHeight = (int) ((float) targetWidth / originalLogo.getWidth() * originalLogo.getHeight());
                Bitmap scaledLogo = Bitmap.createScaledBitmap(originalLogo, targetWidth, targetHeight, true);
                if (originalLogo != scaledLogo) {
                    originalLogo.recycle(); // Free original bitmap memory
                }
                return scaledLogo;
            }
        } catch (Exception e) {
            Log.w(TAG, "Failed to load logo", e);
        }
        return null;
    }

    private void printCenteredLogo(Bitmap logo) {
        if (logo != null) {
            // Get paper width in pixels (typical 58mm thermal printer = ~384 pixels)
            int paperWidth = 384;
            int logoWidth = logo.getWidth();

            // Calculate left margin to center the logo
            int leftMargin = (paperWidth - logoWidth) / 2;

            // Create a centered bitmap with margins
            if (leftMargin > 0) {
                Bitmap centeredBitmap = Bitmap.createBitmap(paperWidth, logo.getHeight(), Bitmap.Config.ARGB_8888);
                android.graphics.Canvas canvas = new android.graphics.Canvas(centeredBitmap);
                canvas.drawColor(0xFFFFFFFF); // White background
                canvas.drawBitmap(logo, leftMargin, 0, null);
                PrinterApi.PrnLogo_Api(centeredBitmap);
            } else {
                // If logo is too wide, just print it as is
                PrinterApi.PrnLogo_Api(logo);
            }
        }
    }

    private Bitmap generateQrCode(String myCodeText) throws WriterException {
        Hashtable<EncodeHintType, ErrorCorrectionLevel> hintMap = new Hashtable<EncodeHintType, ErrorCorrectionLevel>();
        hintMap.put(EncodeHintType.ERROR_CORRECTION, ErrorCorrectionLevel.H); // H = 30% damage

        QRCodeWriter qrCodeWriter = new QRCodeWriter();

        int size = 350;

        BitMatrix bitMatrix = qrCodeWriter.encode(myCodeText, BarcodeFormat.QR_CODE, size, size, hintMap);
        int width = bitMatrix.getWidth();
        int height = bitMatrix.getHeight();
        int[] pixels = new int[width * height];
        for (int y = 0; y < height; y++) {
            int offset = y * width;
            for (int x = 0; x < width; x++) {
                pixels[offset + x] = bitMatrix.get(x, y) ? 0xFF000000 : 0xFFFFFFFF; // BLACK : WHITE
            }
        }

        Bitmap bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888);
        bmp.setPixels(pixels, 0, width, 0, 0, width, height);

        return bmp;
    }

}
