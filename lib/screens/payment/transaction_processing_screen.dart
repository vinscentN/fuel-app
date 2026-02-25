import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  int _currentStep = 0;
  final List<String> _steps = [
    'Validating transaction...',
    'Processing payment...',
    'Completing transaction...',
  ];

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processTransaction();
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _processTransaction() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

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

    _progressController.forward();
    _updateStep(0);
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) _updateStep(1);

    // Add 60-second timeout
    try {
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
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Transaction Timed out. Check your Internet connection or ask Admin for Assistance.');
        },
      );

      if (success && mounted) {
        _updateStep(2);
        await _printReceiptCustomer();
        if (!mounted) return;

        _spinController.stop();
        await Future.delayed(const Duration(milliseconds: 200));
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
        _spinController.stop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.errorMessage ?? 'Payment validation failed'),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      // Handle timeout and other errors
      if (mounted) {
        _spinController.stop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red[600],
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _updateStep(int step) {
    if (mounted) {
      setState(() => _currentStep = step);
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
      final stationName = product?.serviceStationName ?? auth.currentUser?.serviceStationName ?? 'Fuel Station';

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
      case 'L': case 'LT': case 'LTR': case 'LITRE': case 'LITER': return 'L';
      case 'KG': case 'KGS': case 'KILOGRAM': case 'KILOGRAMS': return 'KG';
      default: return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer3<FuelProvider, PaymentProvider, AuthProvider>(
            builder: (context, fuelProvider, paymentProvider, authProvider, child) {
              final product = fuelProvider.selectedProduct;
              final currency = fuelProvider.selectedCurrency;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                               MediaQuery.of(context).padding.top -
                               MediaQuery.of(context).padding.bottom,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildMainIndicator(),
                        const SizedBox(height: 20),
                        _buildCompactAmount(currency: currency, fuelProvider: fuelProvider),
                        const SizedBox(height: 12),
                        _buildProductName(product: product),
                        const SizedBox(height: 20),
                        _buildSimpleProgress(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(0.2),
                      const Color(0xFF2563EB).withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SpinnerPainter(
                      progress: _spinController.value,
                      color: const Color(0xFF3B82F6),
                    ),
                    child: const Center(
                      child: Icon(Icons.payments_rounded, size: 38, color: Color(0xFF3B82F6)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Processing Transaction',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactAmount({
    required currency,
    required FuelProvider fuelProvider,
  }) {
    return Column(
      children: [
        Text(
          'TOTAL AMOUNT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary.withOpacity(0.7),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                currency?.symbol ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            Text(
              fuelProvider.selectedAmount.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: -2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductName({required product}) {
    return Text(
      product?.productName ?? 'N/A',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSimpleProgress() {
    return Column(
      children: [
        Text(
          _steps[_currentStep],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Please wait. Do not close this screen.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class SpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;
  SpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final startAngle = progress * 2 * math.pi;
    const sweepAngle = math.pi;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(SpinnerPainter oldDelegate) => oldDelegate.progress != progress;
}
