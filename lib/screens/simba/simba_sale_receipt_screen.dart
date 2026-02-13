import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/buffalo_colors.dart';
import '../../models/api_product.dart';
import '../../providers/pos_provider.dart';

class SimbaSaleReceiptScreen extends StatefulWidget {
  final ApiProduct product;
  final int quantity;
  final ProductPurchaseResponse response;

  const SimbaSaleReceiptScreen({
    Key? key,
    required this.product,
    required this.quantity,
    required this.response,
  }) : super(key: key);

  @override
  State<SimbaSaleReceiptScreen> createState() => _SimbaSaleReceiptScreenState();
}

class _SimbaSaleReceiptScreenState extends State<SimbaSaleReceiptScreen> {
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
    final posProvider = context.read<PosProvider>();
    final now = DateTime.now();
    final totalAmount = widget.product.priceValue * widget.quantity;

    await posProvider.printSimbaProductReceipt(
      companyName: 'CLUB MATE POS',
      receiptNumber: widget.response.transaction?.transactionNumber ?? 'N/A',
      date: DateFormat('dd/MM/yyyy').format(now),
      time: DateFormat('HH:mm:ss').format(now),
      cardNo: _maskCardNumber(widget.response.transaction?.membershipCardId?.toString() ?? ''),
      productName: widget.product.name,
      quantity: widget.quantity.toString(),
      unitPrice: widget.product.price,
      totalAmount: totalAmount.toStringAsFixed(2),
      currency: widget.product.currency?.symbol ?? '',
      balanceBefore: widget.response.transaction?.balanceBefore,
      balanceAfter: widget.response.transaction?.balanceAfter,
      copyType: copyType,
    );
  }

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    final last4 = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $last4';
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.product.priceValue * widget.quantity;

    return Scaffold(
      backgroundColor: BuffaloColors.background,
      appBar: AppBar(
        title: const Text('Purchase Complete'),
        backgroundColor: BuffaloColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Success icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: BuffaloColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 80,
                        color: BuffaloColors.success,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Receipt card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'RECEIPT',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: BuffaloColors.textPrimary,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildReceiptRow(
                              'Transaction #',
                              widget.response.transaction?.transactionNumber ?? 'N/A',
                              isBold: true,
                            ),
                            const Divider(height: 24),
                            _buildReceiptRow('Product', widget.product.name),
                            const SizedBox(height: 12),
                            _buildReceiptRow(
                              'Unit Price',
                              '${widget.product.currency?.symbol ?? ''} ${widget.product.price}',
                            ),
                            const SizedBox(height: 12),
                            _buildReceiptRow('Quantity', '${widget.quantity}'),
                            const Divider(height: 24),
                            _buildReceiptRow(
                              'Total Amount',
                              '${widget.product.currency?.symbol ?? ''} ${totalAmount.toStringAsFixed(2)}',
                              isBold: true,
                              isLarge: true,
                            ),
                            const SizedBox(height: 12),
                            _buildReceiptRow('Payment Method', 'Card'),
                            const SizedBox(height: 12),
                            _buildReceiptRow(
                              'Status',
                              widget.response.transaction?.status.toUpperCase() ?? 'COMPLETED',
                              color: BuffaloColors.success,
                            ),
                            if (widget.response.transaction?.balanceBefore != null) ...[
                              const Divider(height: 24),
                              _buildReceiptRow(
                                'Balance Before',
                                '${widget.product.currency?.symbol ?? ''} ${widget.response.transaction!.balanceBefore}',
                              ),
                              const SizedBox(height: 12),
                              _buildReceiptRow(
                                'Balance After',
                                '${widget.product.currency?.symbol ?? ''} ${widget.response.transaction!.balanceAfter}',
                                isBold: true,
                              ),
                            ],
                            if (widget.response.balance != null) ...[
                              const Divider(height: 24),
                              _buildReceiptRow(
                                'Current Balance',
                                '${widget.product.currency?.symbol ?? ''} ${widget.response.balance}',
                                isBold: true,
                                color: BuffaloColors.info,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Thank you message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BuffaloColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Thank you for your purchase!',
                        style: TextStyle(
                          fontSize: 16,
                          color: BuffaloColors.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
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
                        foregroundColor: BuffaloColors.textOnSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Pop until we get back to the landing screen
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Return to Menu'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BuffaloColors.secondary,
                        side: const BorderSide(color: BuffaloColors.secondary, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    bool isLarge = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            color: BuffaloColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 20 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? BuffaloColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
