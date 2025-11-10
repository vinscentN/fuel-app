package com.example.fuels_app;

import android.util.Log;

import com.vanstone.trans.api.IcApi;
import com.vanstone.trans.api.MagCardApi;
import com.vanstone.trans.api.PiccApi;
import com.vanstone.trans.api.SystemApi;
import com.vanstone.trans.api.struct.MemCardInfo;
import com.vanstone.trans.api.struct.MemCardOut;
import com.vanstone.utils.CommonConvert;

/**
 * Minimal extraction of PAN reading logic for NFC (M1) and Contact (Memory IC).
 *
 * Copy this class (and ensure the vendor SDK is present) into your Flutter
 * Android plugin, then call the methods from a background thread.
 */
public class CardPanReader {

    private static final String TAG = "CardPanReader";

    // M1/Mifare defaults used in the original code
    private static final int PASSWORD_TYPE = 66; // vendor-specific
    private static final int PAN_BLOCK_NO = 1;   // block that stores 19-digit PAN

    /**
     * Reads a PAN from an NFC M1 card by authenticating and reading block 1.
     * Returns the 19-digit PAN string, or null on timeout/failure.
     *
     * @param timeoutMs maximum time to wait for a card (ms)
     */
    public static String readNfcPan(int timeoutMs) {
        // Open PICC interface
        int ret = PiccApi.PiccOpen_Api();
        if (ret != 0) {
            PiccApi.PiccClose_Api();
            ret = PiccApi.PiccOpen_Api();
            if (ret != 0) return null;
        }

        byte[] cardType = new byte[2];
        byte[] serialNo = new byte[20];

        int timerId = SystemApi.TimerSet_Api();
        long start = System.currentTimeMillis();

        try {
            while (SystemApi.TimerCheck_Api(timerId, timeoutMs) == 0) {
                if (PiccApi.PiccCheck_Api(3, cardType, serialNo) == 0) {
                    // Card present: authenticate and read PAN block
                    String pan = readM1PanFromBlock();
                    return pan;
                }
            }
        } finally {
            PiccApi.PiccClose_Api();
            MagCardApi.MagClose_Api();
        }

        return null; // timeout
    }

    private static String readM1PanFromBlock() {
        // Authorize with default key FFFFFFFFFFFF for the target block
        byte[] defaultKey = CommonConvert.ascStringToBCD("ffffffffffff");
        int auth = PiccApi.M1Authority_Api(PASSWORD_TYPE, PAN_BLOCK_NO, defaultKey);
        if (auth != 0) {
            Log.w(TAG, "M1 auth failed for block " + PAN_BLOCK_NO + ": " + auth);
            return null;
        }

        byte[] blk = new byte[16];
        int rd = PiccApi.M1ReadBlock_Api(PAN_BLOCK_NO, blk);
        if (rd != 0) {
            Log.w(TAG, "M1 read failed for block " + PAN_BLOCK_NO + ": " + rd);
            return null;
        }

        String asc = CommonConvert.bcdToASCString(blk);
        // Original code truncates to 19 characters
        if (asc == null || asc.length() < 19) return null;
        return asc.substring(0, 19);
    }

    /**
     * Reads a PAN from a contact memory IC card (SLE44x2) by reading the first bytes
     * and converting hex -> ASCII. Returns the PAN string, or null on failure.
     *
     * @param timeoutMs maximum time to wait for card detection
     */
    public static String readChipPan(int timeoutMs) {
        MemCardInfo cardInf = new MemCardInfo();
        MemCardOut out = new MemCardOut();
        cardInf.CardNo = 0;
        cardInf.CardType = IcApi.SLE44X2; // From original code

        int powerOn = IcApi.MemIccPowerOn_Api(cardInf);
        Log.v(TAG, "MemIccPowerOn: " + powerOn);

        int timerId = SystemApi.TimerSet_Api();
        long start = System.currentTimeMillis();

        try {
            while (true) {
                if (SystemApi.TimerCheck_Api(timerId, timeoutMs) != 0) {
                    return null; // timeout
                }

                int det = IcApi.IccDetect_Api(0);
                if (det == 0) {
                    break; // card detected
                }
            }

            int rd = IcApi.MemIccReadData_Api(cardInf, 0, 100, out);
            if (rd != 0) {
                Log.w(TAG, "MemIccReadData_Api failed: " + rd);
                return null;
            }

            // Convert read buffer to PAN: take first 19 bytes as hex->ASCII (matches original logic)
            String hex = CommonConvert.bytes2HexString(out.getOutBufHex());
            if (hex == null || hex.length() < 38) return null;
            String first19BytesHex = hex.substring(0, 38);
            return hexToAscii(first19BytesHex);
        } catch (Exception e) {
            Log.e(TAG, "readChipPan error", e);
            return null;
        } finally {
            try { IcApi.MemIccPowerOff_Api(cardInf); } catch (Exception ignored) {}
        }
    }

    private static String hexToAscii(String hexStr) {
        StringBuilder output = new StringBuilder();
        for (int i = 0; i < hexStr.length(); i += 2) {
            String str = hexStr.substring(i, i + 2);
            output.append((char) Integer.parseInt(str, 16));
        }
        return output.toString();
    }
}

