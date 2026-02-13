import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pos_service.dart';

class PosProvider extends ChangeNotifier {
  final PosService _posService = PosService();

  // Add a MethodChannel for direct platform calls like testPrint
  static const MethodChannel _channel = MethodChannel("aisino_pos_sdk");

  Map? _lastResult;
  String? _lastError;
  bool _isLoading = false;

  Map? get lastResult => _lastResult;
  String? get lastError => _lastError;
  bool get isLoading => _isLoading;

  // Clear any sensitive card data (e.g., PAN/UID) cached from last read
  void clearCardData() {
    _lastResult = null;
    _lastError = null;
    notifyListeners();
  }

  Future<void> readNfcCard() async {
    _setLoading(true);
    try {
      _lastResult = await _posService.readNfc();
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
    }
    _setLoading(false);
  }

  Future<void> readChipCard() async {
    _setLoading(true);
    try {
      _lastResult = await _posService.readChip();
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
    }
    _setLoading(false);
  }

  Future<void> readMagstripeCard() async {
    _setLoading(true);
    try {
      _lastResult = await _posService.readMagstripe();
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
    }
    _setLoading(false);
  }

  Future<void> requestPinEntry() async {
    _setLoading(true);
    try {
      _lastResult = await _posService.requestPin();
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
    }
    _setLoading(false);
  }

  Future<void> testPrint({
    required String stationName,
    required String address,
    required String phone,
    required String date,
    required String time,
    required String pumpNo,
    required String product,
    String unit = 'L',
    required String litres,
    required String pricePerLitre,
    required String total,
    required String payment,
    required String cardNo,
    required String authNo,
    required String rrn,
    String operatorName = '',
  }) async {
    _setLoading(true);
    try {
      final result = await _channel.invokeMethod("testPrint", {
        "stationName": stationName,
        "address": address,
        "phone": phone,
        "date": date,
        "time": time,
        "pumpNo": pumpNo,
        "product": product,
        "unit": unit,
        "litres": litres,
        "pricePerLitre": pricePerLitre,
        "total": total,
        "payment": payment,
        "cardNo": cardNo,
        "authNo": authNo,
        "rrn": rrn,
        "operator": operatorName,
      });
      _lastResult = {"printResult": result};
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> printReceiptCopy({
    required String copyType, // 'CUSTOMER COPY' or 'MERCHANT COPY'
    required String stationName,
    required String address,
    required String phone,
    required String date,
    required String time,
    required String pumpNo,
    required String product,
    String unit = 'L',
    required String litres,
    required String pricePerLitre,
    required String total,
    required String payment,
    required String cardNo,
    required String authNo,
    required String rrn,
    String operatorName = '',
  }) async {
    _setLoading(true);
    try {
      final result = await _channel.invokeMethod("printReceiptCopy", {
        "copyType": copyType,
        "stationName": stationName,
        "address": address,
        "phone": phone,
        "date": date,
        "time": time,
        "pumpNo": pumpNo,
        "product": product,
        "unit": unit,
        "litres": litres,
        "pricePerLitre": pricePerLitre,
        "total": total,
        "payment": payment,
        "cardNo": cardNo,
        "authNo": authNo,
        "rrn": rrn,
        "operator": operatorName,
      });
      _lastResult = {"printResult": result};
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> printCardBalanceReceipt({
    required String stationName,
    String address = '',
    String phone = '',
    required String date,
    required String time,
    required String cardNo,
    required List<Map<String, String>> items, // [{currency: 'US Dollar', balance: '28.50'}, ...]
    String title = 'Balance Enquiry',
    String copyType = 'CUSTOMER COPY',
    String footer = '',
    bool boldTitle = true,
  }) async {
    _setLoading(true);
    try {
      final result = await _channel.invokeMethod("printCardBalanceReceipt", {
        "stationName": stationName,
        "address": address,
        "phone": phone,
        "date": date,
        "time": time,
        "cardNo": cardNo,
        "items": items,
        "title": title,
        "copyType": copyType,
        "footer": footer,
        "boldTitle": boldTitle,
      });
      _lastResult = {"printResult": result};
      _lastError = null;
      return true;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // New: Minimal, dedicated Balance Enquiry receipt API
  Future<bool> printBalanceEnquiryReceipt({
    required String stationName,
    String address = '',
    String phone = '',
    required String date,
    required String time,
    required String cardNo,
    required List<Map<String, String>> items, // [{currency: 'USD', balance: '28.50'}, ...]
    String title = 'CARD BALANCE ENQUIRY',
  }) async {
    _setLoading(true);
    try {
      // Dedicated native method for balance enquiry receipt
      final result = await _channel.invokeMethod("printBalanceEnquiryReceipt", {
        "stationName": stationName,
        "address": address,
        "phone": phone,
        "date": date,
        "time": time,
        "cardNo": cardNo,
        "items": items,
        "title": title,
      });
      _lastResult = {"printResult": result};
      _lastError = null;
      return true;
    } catch (e) {
      // Fallback to generic testPrint if the native method is missing
      try {
        final summary = items.map((i) => '${i['currency']}: ${i['balance']}').join('  ');
        await testPrint(
          stationName: stationName,
          address: address.isNotEmpty ? address : title,
          phone: phone,
          date: date,
          time: time,
          pumpNo: '-',
          product: title,
          litres: '-',
          pricePerLitre: '-',
          total: '',
          payment: summary,
          cardNo: cardNo,
          authNo: '-',
          rrn: '-',
        );
        _lastError = null;
        return true;
      } catch (e2) {
        _lastResult = null;
        _lastError = 'Balance receipt print failed: $e2';
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  // New: Batch Cutoff receipt via native printer (same channel as sales receipts)
  Future<bool> printBatchCutoffReceipt({
    required String stationName,
    String address = '',
    String phone = '',
    required String date,
    required String time,
    required String operatorCode,
    required List<Map<String, String>> items, // list of maps using response field names or normalized keys
    Map<String, dynamic>? attendant, // {first_name,last_name,service_station_name}
    Map<String, dynamic>? device,    // {serial_number,terminal_id}
    String title = 'BATCH CUT OFF',
  }) async {
    _setLoading(true);
    try {
      final result = await _channel.invokeMethod("batchCutOffReceipt", {
        "stationName": stationName,
        "address": address,
        "phone": phone,
        "date": date,
        "time": time,
        "operatorCode": operatorCode,
        "items": items,
        "title": title,
        if (attendant != null) "attendant": attendant,
        if (device != null) "device": device,
      });
      _lastResult = {"printResult": result};
      _lastError = null;
      return true;
    } catch (e) {
      // Fallback: summarize transactions into a single line on generic receipt
      try {
        final summary = items.map((i) {
          final txn = (i['txn'] ?? i['transaction'] ?? '').toString();
          final amt = (i['amount'] ?? i['balance'] ?? '').toString();
          final cur = (i['currency'] ?? '').toString();
          return txn.isNotEmpty ? '$txn:$cur $amt' : '$cur $amt';
        }).join('  ');
        await testPrint(
          stationName: stationName,
          address: title,
          phone: phone,
          date: date,
          time: time,
          pumpNo: '-',
          product: '$title (Op: $operatorCode)',
          litres: '-',
          pricePerLitre: '-',
          total: '',
          payment: summary,
          cardNo: '-',
          authNo: '-',
          rrn: '-',
        );
        _lastError = null;
        return true;
      } catch (e2) {
        _lastResult = null;
        _lastError = 'Batch cutoff print failed: $e2';
        return false;
      }
    } finally {
      _setLoading(false);
    }
  }

  // New: LAST SALE TRANSACTION single-copy receipt via native printer
  Future<bool> printLastSaleReceipt({
    required String stationName,
    String address = '',
    String phone = '',
    required String date,
    required String time,
    required String pumpNo,
    required String product,
    String unit = 'L',
    required String litres,
    required String pricePerLitre,
    required String total,
    required String payment,
    required String cardNo,
    required String authNo,
    required String rrn,
    String title = 'LAST SALE TRANSACTION',
  }) async {
    _setLoading(true);
    try {
      final result = await _channel.invokeMethod("printLastSaleReceipt", {
        "title": title,
        "stationName": stationName,
        "address": address,
        "phone": phone,
        "date": date,
        "time": time,
        "pumpNo": pumpNo,
        "product": product,
        "unit": unit,
        "litres": litres,
        "pricePerLitre": pricePerLitre,
        "total": total,
        "payment": payment,
        "cardNo": cardNo,
        "authNo": authNo,
        "rrn": rrn,
      });
      _lastResult = {"printResult": result};
      _lastError = null;
      return true;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // New: Batch Audit summary receipt via native printer
  Future<bool> printBatchAuditReceipt({
    required String title,
    required Map<String, dynamic>? attendant,
    required Map<String, dynamic>? device,
    required String time,
    required List<Map<String, String>> items, // from API 'data'
  }) async {
    _setLoading(true);
    try {
      final result = await _channel.invokeMethod("batchAuditReceipt", {
        "title": title,
        if (attendant != null) "attendant": attendant,
        if (device != null) "device": device,
        "time": time,
        "items": items,
      });
      _lastResult = {"printResult": result};
      _lastError = null;
      return true;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }


  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> readImei() async {
    _setLoading(true);
    try {
      final imei = await _posService.readImei();
      _lastResult = {"imei": imei};
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> readPosType() async {
    _setLoading(true);
    try {
      final posType = await _posService.readPosType();
      _lastResult = {"posType": posType};
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> readSerialNumber() async {
    _setLoading(true);
    try {
      final serial = await _posService.readSerialNumber();
      _lastResult = {"serialNumber": serial};
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> printQRCodeReceipt({
    required String title,
    required String qrData,
    required String requestCode,
    required String stationName,
    required String address,
    required String phone,
    required String date,
    required String time,
    required String status,
    required String description,
    required String cylinderCount,
    required String cylinderDetails,
    required String createdBy,
  }) async {
    _setLoading(true);
    try {
      final result = await _channel.invokeMethod("printQRCodeReceipt", {
        "title": title,
        "qrData": qrData,
        "requestCode": requestCode,
        "stationName": stationName,
        "address": address,
        "phone": phone,
        "date": date,
        "time": time,
        "status": status,
        "description": description,
        "cylinderCount": cylinderCount,
        "cylinderDetails": cylinderDetails,
        "createdBy": createdBy,
      });
      _lastResult = {"printResult": result};
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> printPickupReceipt({
    required String requestCode,
    required String stationName,
    required String address,
    required String phone,
    required String date,
    required String time,
    required String driverName,
    required String cylinderCount,
    required String cylinderDetails,
    required String description,
    required String siteName,
    required String siteCode,
  }) async {
    _setLoading(true);
    try {
      final result = await _channel.invokeMethod("printPickupReceipt", {
        "requestCode": requestCode,
        "stationName": stationName,
        "address": address,
        "phone": phone,
        "date": date,
        "time": time,
        "driverName": driverName,
        "cylinderCount": cylinderCount,
        "cylinderDetails": cylinderDetails,
        "description": description,
        "siteName": siteName,
        "siteCode": siteCode,
      });
      _lastResult = {"printResult": result};
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> printDeliveryReceipt({
    required String requestCode,
    required String deliveryCode,
    required String invoiceNumber,
    required String stationName,
    required String address,
    required String phone,
    required String date,
    required String time,
    required String driverName,
    required String cylinderCount,
    required String cylinderDetails,
    required String description,
    required String siteName,
    required String siteCode,
    String? copyType,
  }) async {
    _setLoading(true);
    try {
      final payload = {
        "requestCode": requestCode,
        "deliveryCode": deliveryCode,
        "invoiceNumber": invoiceNumber,
        "stationName": stationName,
        "address": address,
        "phone": phone,
        "date": date,
        "time": time,
        "driverName": driverName,
        "cylinderCount": cylinderCount,
        "cylinderDetails": cylinderDetails,
        "description": description,
        "siteName": siteName,
        "siteCode": siteCode,
      };

      if (copyType != null && copyType.isNotEmpty) {
        payload["copyType"] = copyType;
      }

      final result = await _channel.invokeMethod("printDeliveryReceipt", payload);
      _lastResult = {"printResult": result};
      _lastError = null;
    } catch (e) {
      _lastResult = null;
      _lastError = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Buffalo Brewing Sales Receipt
  Future<bool> printBuffaloSalesReceipt({
    required String companyName,
    required String receiptNumber,
    required String date,
    required String time,
    required String cardNo,
    required List<Map<String, String>> items, // [{name: 'Product', qty: '2', price: '10.00', total: '20.00'}]
    required String totalAmount,
    required String currency,
    String? remainingBalance,
    String copyType = 'CUSTOMER COPY',
  }) async {
    _setLoading(true);
    try {
      // Generate random reference number
      final random = DateTime.now().millisecondsSinceEpoch % 1000000;
      final refNumber = 'REF${random.toString().padLeft(6, '0')}';

      // Build a minimal, compact receipt
      final StringBuffer receipt = StringBuffer();

      receipt.writeln(companyName);
      receipt.writeln(copyType);
      receipt.writeln(refNumber);
      receipt.writeln('$date  $time');
      receipt.writeln(cardNo);
      receipt.writeln('------------------------');

      // Items - compact format
      for (var item in items) {
        receipt.writeln('${item['name']}');
        receipt.writeln('  ${item['qty']} x ${item['price']}  ${item['total']}');
      }

      receipt.writeln('========================');
      receipt.writeln('TOTAL  $currency$totalAmount');

      if (remainingBalance != null) {
        receipt.writeln('BAL    $currency$remainingBalance');
      }

      receipt.writeln('========================');
      receipt.writeln('Thank you!');
      receipt.writeln('');

      final receiptText = receipt.toString();

      // Use testPrint with minimal fields to avoid labels
      await testPrint(
        stationName: '',
        address: '',
        phone: '',
        date: '',
        time: '',
        pumpNo: '',
        product: '',
        litres: receiptText,
        pricePerLitre: '',
        total: '',
        payment: '',
        cardNo: '',
        authNo: '',
        rrn: '',
        operatorName: '',
      );

      _lastError = null;
      return true;
    } catch (e) {
      _lastResult = null;
      _lastError = 'Sales receipt print failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Buffalo Brewing Balance Receipt
  Future<bool> printBuffaloBalanceReceipt({
    required String companyName,
    required String date,
    required String time,
    required String cardNo,
    required List<Map<String, String>> balances, // [{currency: 'USD', balance: '28.50'}]
  }) async {
    _setLoading(true);
    try {
      // Use existing balance receipt printer
      await printBalanceEnquiryReceipt(
        stationName: companyName,
        date: date,
        time: time,
        cardNo: cardNo,
        items: balances,
        title: 'BALANCE ENQUIRY',
      );
      return true;
    } catch (e) {
      _lastResult = null;
      _lastError = 'Balance receipt print failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Simba Product Sale Receipt
  Future<bool> printSimbaProductReceipt({
    required String companyName,
    required String receiptNumber,
    required String date,
    required String time,
    required String cardNo,
    required String productName,
    required String quantity,
    required String unitPrice,
    required String totalAmount,
    required String currency,
    String? balanceBefore,
    String? balanceAfter,
    String copyType = 'CUSTOMER COPY',
  }) async {
    _setLoading(true);
    try {
      final StringBuffer receipt = StringBuffer();

      receipt.writeln(companyName);
      receipt.writeln('PRODUCT SALE');
      receipt.writeln(copyType);
      receipt.writeln('------------------------');
      receipt.writeln('Receipt: $receiptNumber');
      receipt.writeln('$date  $time');
      receipt.writeln('Card: $cardNo');
      receipt.writeln('========================');
      receipt.writeln(productName);
      receipt.writeln('  $quantity x $currency$unitPrice');
      receipt.writeln('========================');
      receipt.writeln('TOTAL  $currency$totalAmount');

      if (balanceBefore != null && balanceAfter != null) {
        receipt.writeln('------------------------');
        receipt.writeln('Bal Before: $currency$balanceBefore');
        receipt.writeln('Bal After:  $currency$balanceAfter');
      }

      receipt.writeln('========================');
      receipt.writeln('Thank you!');
      receipt.writeln('');

      final receiptText = receipt.toString();

      await testPrint(
        stationName: '',
        address: '',
        phone: '',
        date: '',
        time: '',
        pumpNo: '',
        product: '',
        litres: receiptText,
        pricePerLitre: '',
        total: '',
        payment: '',
        cardNo: '',
        authNo: '',
        rrn: '',
        operatorName: '',
      );

      _lastError = null;
      return true;
    } catch (e) {
      _lastResult = null;
      _lastError = 'Product receipt print failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Simba Card Balance Receipt
  Future<bool> printSimbaBalanceReceipt({
    required String companyName,
    required String date,
    required String time,
    required String cardNo,
    required String status,
    required String currency,
    required String balance,
    String? expiryDate,
  }) async {
    _setLoading(true);
    try {
      final StringBuffer receipt = StringBuffer();

      receipt.writeln(companyName);
      receipt.writeln('CARD BALANCE ENQUIRY');
      receipt.writeln('------------------------');
      receipt.writeln('$date  $time');
      receipt.writeln('Card: $cardNo');
      receipt.writeln('Status: $status');
      if (expiryDate != null) {
        receipt.writeln('Expiry: $expiryDate');
      }
      receipt.writeln('========================');
      receipt.writeln('BALANCE');
      receipt.writeln('$currency $balance');
      receipt.writeln('========================');
      receipt.writeln('');

      final receiptText = receipt.toString();

      await testPrint(
        stationName: '',
        address: '',
        phone: '',
        date: '',
        time: '',
        pumpNo: '',
        product: '',
        litres: receiptText,
        pricePerLitre: '',
        total: '',
        payment: '',
        cardNo: '',
        authNo: '',
        rrn: '',
        operatorName: '',
      );

      _lastError = null;
      return true;
    } catch (e) {
      _lastResult = null;
      _lastError = 'Balance receipt print failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Simba Card Top-Up Receipt
  Future<bool> printSimbaTopUpReceipt({
    required String companyName,
    required String receiptNumber,
    required String date,
    required String time,
    required String cardNo,
    required String amount,
    required String currency,
    required String paymentMethod,
    String? balanceBefore,
    String? balanceAfter,
    String copyType = 'CUSTOMER COPY',
  }) async {
    _setLoading(true);
    try {
      final StringBuffer receipt = StringBuffer();

      receipt.writeln(companyName);
      receipt.writeln('CARD TOP-UP');
      receipt.writeln(copyType);
      receipt.writeln('------------------------');
      receipt.writeln('Receipt: $receiptNumber');
      receipt.writeln('$date  $time');
      receipt.writeln('Card: $cardNo');
      receipt.writeln('========================');
      receipt.writeln('Top-Up Amount');
      receipt.writeln('$currency$amount');
      receipt.writeln('Payment: $paymentMethod');

      if (balanceBefore != null && balanceAfter != null) {
        receipt.writeln('------------------------');
        receipt.writeln('Bal Before: $currency$balanceBefore');
        receipt.writeln('Bal After:  $currency$balanceAfter');
      }

      receipt.writeln('========================');
      receipt.writeln('Thank you!');
      receipt.writeln('');

      final receiptText = receipt.toString();

      await testPrint(
        stationName: '',
        address: '',
        phone: '',
        date: '',
        time: '',
        pumpNo: '',
        product: '',
        litres: receiptText,
        pricePerLitre: '',
        total: '',
        payment: '',
        cardNo: '',
        authNo: '',
        rrn: '',
        operatorName: '',
      );

      _lastError = null;
      return true;
    } catch (e) {
      _lastResult = null;
      _lastError = 'Top-up receipt print failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Simba Ticket Purchase Receipt
  Future<bool> printSimbaTicketReceipt({
    required String companyName,
    required String ticketNumber,
    required String date,
    required String time,
    required String eventName,
    required String venue,
    required String eventDate,
    required String ticketType,
    required String price,
    required String currency,
    required String paymentMethod,
    String? cardNo,
    String? balanceBefore,
    String? balanceAfter,
    String copyType = 'CUSTOMER COPY',
  }) async {
    _setLoading(true);
    try {
      final StringBuffer receipt = StringBuffer();

      receipt.writeln(companyName);
      receipt.writeln('EVENT TICKET');
      receipt.writeln(copyType);
      receipt.writeln('========================');
      receipt.writeln('TICKET: $ticketNumber');
      receipt.writeln('------------------------');
      receipt.writeln(eventName);
      receipt.writeln('Venue: $venue');
      receipt.writeln('Date: $eventDate');
      receipt.writeln('Type: $ticketType');
      receipt.writeln('========================');
      receipt.writeln('PRICE  $currency$price');
      receipt.writeln('Payment: $paymentMethod');

      if (cardNo != null) {
        receipt.writeln('Card: $cardNo');
      }

      if (balanceBefore != null && balanceAfter != null) {
        receipt.writeln('------------------------');
        receipt.writeln('Bal Before: $currency$balanceBefore');
        receipt.writeln('Bal After:  $currency$balanceAfter');
      }

      receipt.writeln('========================');
      receipt.writeln('Present this ticket');
      receipt.writeln('at event entrance');
      receipt.writeln('');

      final receiptText = receipt.toString();

      await testPrint(
        stationName: '',
        address: '',
        phone: '',
        date: '',
        time: '',
        pumpNo: '',
        product: '',
        litres: receiptText,
        pricePerLitre: '',
        total: '',
        payment: '',
        cardNo: '',
        authNo: '',
        rrn: '',
        operatorName: '',
      );

      _lastError = null;
      return true;
    } catch (e) {
      _lastResult = null;
      _lastError = 'Ticket receipt print failed: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }


}
