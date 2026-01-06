import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fuel_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../utils/colors.dart';
import '../../models/transaction.dart';
import '../../models/customer.dart';
import '../../widgets/common/success_screen.dart';

class TransactionProcessingScreen extends StatefulWidget {
  final int? customerId;
  final CustomerData? customerData;

  const TransactionProcessingScreen({
    super.key,
    this.customerId,
    this.customerData,
  });

  @override
  State<TransactionProcessingScreen> createState() => _TransactionProcessingScreenState();
}

class _TransactionProcessingScreenState extends State<TransactionProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start processing transaction after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processTransaction();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processTransaction() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

    // Guard required fields
    if (fuelProvider.selectedProduct == null ||
        fuelProvider.selectedCurrency == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing sale details. Please restart the sale.')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final success = await paymentProvider.processPayment(
      userId: authProvider.currentUser?.id.toString() ?? '0',
      productId: fuelProvider.selectedProduct!.id,
      currencyCode: fuelProvider.selectedCurrency!.code,
      amount: fuelProvider.selectedAmount,
      quantity: fuelProvider.selectedQuantity,
      paymentMethod: PaymentMethod.cash,
      operatorPin: authProvider.currentUser?.id.toString() ?? '0',
      customerId: widget.customerId,
      customerData: widget.customerData,
    );

    if (success && mounted) {
      await _printReceiptCustomer();
      if (!mounted) return;

      setState(() => _isProcessing = false);

      // Navigate to success screen after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SuccessScreen(
            title: 'Cash Payment Confirmed!',
            message: 'Cash transaction completed successfully.',
          ),
        ),
      );
    } else if (mounted) {
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.errorMessage ?? 'Payment validation failed'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );

      // Navigate back after error
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _printReceiptCustomer() async {
    try {
      final pos = Provider.of<PosProvider>(context, listen: false);
      final fuel = Provider.of<FuelProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final payment = Provider.of<PaymentProvider>(context, listen: false);

      final r = payment.receiptData;
      if (r != null && r.isNotEmpty) {
        final unit = _unitShort(fuel.selectedProduct?.unitOfMeasure);
        await pos.printReceiptCopy(
          copyType: 'CUSTOMER COPY',
          stationName: (r['stationName'] ?? auth.currentUser?.serviceStationName ?? 'Fuel Station').toString(),
          address: (r['address'] ?? '').toString(),
          phone: (r['phone'] ?? '').toString(),
          date: (r['date'] ?? '').toString(),
          time: (r['time'] ?? '').toString(),
          pumpNo: (r['pumpNo'] ?? '1').toString(),
          product: (r['product'] ?? fuel.selectedProduct?.productName ?? 'Fuel').toString(),
          unit: unit,
          litres: (r['litres'] ?? fuel.selectedQuantity.toStringAsFixed(2)).toString(),
          pricePerLitre: (r['pricePerLitre'] ?? fuel.selectedProduct?.price.toStringAsFixed(2) ?? '0.00').toString(),
          total: (r['total'] ?? fuel.selectedAmount.toStringAsFixed(2)).toString(),
          payment: (r['payment'] ?? payment.selectedPaymentMethod?.name ?? '').toString(),
          cardNo: (r['cardNo'] ?? '').toString(),
          authNo: (r['authNo'] ?? payment.currentTransaction?.referenceNumber ?? '').toString(),
          rrn: (r['rrn'] ?? payment.currentTransaction?.id ?? '').toString(),
          operatorName: (r['attendant'] ?? auth.currentUser?.fullName ?? '').toString(),
        );
        return;
      }

      final product = fuel.selectedProduct;
      final currency = fuel.selectedCurrency;
      final txn = payment.currentTransaction;
      final stationName = product?.serviceStationName
          ?? auth.currentUser?.serviceStationName
          ?? 'Fuel Station';

      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final date = '${now.year}-${two(now.month)}-${two(now.day)}';
      final time = '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';

      final unit = _unitShort(product?.unitOfMeasure);
      await pos.printReceiptCopy(
        copyType: 'CUSTOMER COPY',
        stationName: stationName,
        address: '',
        phone: '',
        date: date,
        time: time,
        pumpNo: '1',
        product: product?.productName ?? 'Fuel',
        unit: unit,
        litres: fuel.selectedQuantity.toStringAsFixed(2),
        pricePerLitre: product?.price.toStringAsFixed(2) ?? '0.00',
        total: currency != null
            ? '${currency.symbol}${fuel.selectedAmount.toStringAsFixed(2)}'
            : fuel.selectedAmount.toStringAsFixed(2),
        payment: payment.selectedPaymentMethod?.name ?? 'cash',
        cardNo: '',
        authNo: txn?.referenceNumber ?? txn?.id ?? '',
        rrn: txn?.id ?? txn?.referenceNumber ?? '',
        operatorName: auth.currentUser?.fullName ?? '',
      );
    } catch (e) {
      debugPrint('Cash receipt print failed: $e');
    }
  }

  String _unitShort(String? uom) {
    final code = (uom ?? 'L').trim().toUpperCase();
    switch (code) {
      case 'L':
      case 'LT':
      case 'LTR':
      case 'LITRE':
      case 'LITER':
        return 'L';
      case 'KG':
      case 'KGS':
      case 'KILOGRAM':
      case 'KILOGRAMS':
        return 'KG';
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button during processing
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Consumer3<FuelProvider, PaymentProvider, AuthProvider>(
              builder: (context, fuelProvider, paymentProvider, authProvider, child) {
                final product = fuelProvider.selectedProduct;
                final currency = fuelProvider.selectedCurrency;
                final unit = _unitShort(product?.unitOfMeasure);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 8),

                    // Processing Animation
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.7),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.payment,
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Status Text
                    Text(
                      _isProcessing ? 'Processing Transaction' : 'Transaction Complete',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    if (_isProcessing) ...[
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.check_circle,
                        size: 32,
                        color: Colors.green[600],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Transaction Details Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transaction Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),

                            _buildDetailRow(
                              'Product',
                              product?.productName ?? 'N/A',
                              Icons.local_gas_station,
                            ),
                            const Divider(height: 18),

                            _buildDetailRow(
                              'Quantity',
                              '${fuelProvider.selectedQuantity.toStringAsFixed(2)} $unit',
                              Icons.speed,
                            ),
                            const Divider(height: 18),

                            _buildDetailRow(
                              'Amount',
                              '${currency?.symbol ?? ''}${fuelProvider.selectedAmount.toStringAsFixed(2)}',
                              Icons.attach_money,
                            ),
                            const Divider(height: 18),

                            _buildDetailRow(
                              'Payment Method',
                              'Cash',
                              Icons.money,
                            ),

                            if (widget.customerData != null || widget.customerId != null) ...[
                              const Divider(height: 18),
                              _buildDetailRow(
                                'Customer',
                                widget.customerData?.name ?? 'Registered Customer',
                                Icons.person,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Warning message
                    if (_isProcessing) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Please do not close or navigate away',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
