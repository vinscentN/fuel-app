import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/buffalo_provider.dart';
import '../../providers/pos_provider.dart';
import 'buffalo_main_menu_screen.dart';

class BuffaloReceiptScreen extends StatefulWidget {
  const BuffaloReceiptScreen({Key? key}) : super(key: key);

  @override
  State<BuffaloReceiptScreen> createState() => _BuffaloReceiptScreenState();
}

class _BuffaloReceiptScreenState extends State<BuffaloReceiptScreen> {
  bool _hasPrinted = false;

  @override
  void initState() {
    super.initState();
    // Auto-print receipt when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPrintReceipt();
    });
  }

  Future<void> _autoPrintReceipt() async {
    if (_hasPrinted) return;
    _hasPrinted = true;

    await _printReceipt(copyType: 'CUSTOMER COPY');
  }

  Future<void> _printReceipt({String copyType = 'CUSTOMER COPY'}) async {
    final buffaloProvider = context.read<BuffaloProvider>();
    final posProvider = context.read<PosProvider>();
    final saleResponse = buffaloProvider.lastSaleResponse;

    if (saleResponse == null || saleResponse.data == null) return;

    final now = DateTime.now();
    final saleData = saleResponse.data!;

    // Create items list for the printer
    final items = [
      {
        'name': saleData.productName ?? 'Meal',
        'qty': (saleData.mealQuantity ?? 1).toString(),
        'price': 'Meal',
        'total': '${saleData.mealQuantity ?? 1} meal(s)',
      }
    ];

    await posProvider.printBuffaloSalesReceipt(
      companyName: 'The Buffalo Brewing Company',
      receiptNumber: saleData.referenceNumber ?? 'N/A',
      date: DateFormat('dd/MM/yyyy').format(now),
      time: DateFormat('HH:mm:ss').format(now),
      cardNo: _maskCardNumber(buffaloProvider.cardNumber ?? ''),
      items: items,
      totalAmount: '${saleData.mealQuantity ?? 1} meal(s)',
      currency: '',
      remainingBalance: (saleData.newMealBalance ?? 0).toString(),
      copyType: copyType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuffaloProvider>();
    final saleResponse = provider.lastSaleResponse;
    final saleData = saleResponse?.data;
    final cardInfo = provider.cardInfo;

    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Receipt'),
          backgroundColor: BuffaloColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Success Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: BuffaloColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        size: 80,
                        color: BuffaloColors.success,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sale Successful!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      saleResponse?.message ?? 'Thank you for your purchase',
                      style: TextStyle(
                        fontSize: 16,
                        color: BuffaloColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Receipt Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Company Header
                            Icon(
                              Icons.coffee,
                              size: 48,
                              color: BuffaloColors.secondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Buffalo Brewing Company',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: BuffaloColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Divider(color: BuffaloColors.cardBorder),
                            const SizedBox(height: 16),

                            // Transaction Details
                            if (saleData?.referenceNumber != null) ...[
                              _ReceiptRow(
                                label: 'Reference No.',
                                value: saleData!.referenceNumber!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (saleData?.timestamp != null) ...[
                              _ReceiptRow(
                                label: 'Date/Time',
                                value: _formatDateTime(saleData!.timestamp!),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (saleData?.employeeName != null) ...[
                              _ReceiptRow(
                                label: 'Employee',
                                value: saleData!.employeeName!,
                              ),
                              const SizedBox(height: 12),
                            ],
                            _ReceiptRow(
                              label: 'Card',
                              value: _maskCardNumber(provider.cardNumber ?? ''),
                            ),
                            if (cardInfo != null) ...[
                              const SizedBox(height: 12),
                              _ReceiptRow(
                                label: 'Card Type',
                                value: cardInfo.cardType,
                              ),
                              const SizedBox(height: 12),
                              _ReceiptRow(
                                label: 'Card Class',
                                value: cardInfo.cardClass,
                              ),
                            ],
                            const SizedBox(height: 16),
                            Divider(color: BuffaloColors.cardBorder),
                            const SizedBox(height: 16),

                            // Sale Details
                            if (saleData?.productName != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      saleData!.productName!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: BuffaloColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (saleData?.mealQuantity != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Meal Quantity',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: BuffaloColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${saleData!.mealQuantity}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: BuffaloColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: BuffaloColors.cardBorder),
                              const SizedBox(height: 16),
                            ],

                            // Balance Information
                            if (saleData?.newMealBalance != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'New Meal Balance',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: BuffaloColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${saleData!.newMealBalance} meals',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: BuffaloColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            if (saleData?.tapsRemainingToday != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Taps Remaining Today',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: BuffaloColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${saleData!.tapsRemainingToday}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: BuffaloColors.info,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 24),
                            Text(
                              'Thank you for your business!',
                              style: TextStyle(
                                fontSize: 14,
                                color: BuffaloColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: BuffaloColors.cardShadow,
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _printReceipt(copyType: 'MERCHANT COPY');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Printing merchant copy...'),
                          duration: Duration(seconds: 2),
                          backgroundColor: BuffaloColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('Print Merchant Copy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BuffaloColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      provider.resetTransaction();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BuffaloMainMenuScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home),
                    label: const Text('Return to Menu'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BuffaloColors.primary,
                      side: BorderSide(color: BuffaloColors.primary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    final last4 = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $last4';
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: BuffaloColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: BuffaloColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
