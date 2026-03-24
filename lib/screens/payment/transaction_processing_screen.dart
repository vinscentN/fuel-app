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
import '../reports/last_sale_screen.dart';

class TransactionProcessingScreen extends StatefulWidget {
  final int? customerId;
  final CustomerData? customerData;

  const TransactionProcessingScreen({
    super.key,
    this.customerId,
    this.customerData,
  });

  @override
  State<TransactionProcessingScreen> createState() =>
      _TransactionProcessingScreenState();
}

class _TransactionProcessingScreenState
    extends State<TransactionProcessingScreen> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  int _currentStep = 0;
  static const _steps = [
    'Validating transaction',
    'Processing payment',
    'Completing transaction',
  ];

  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _processTransaction());
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateStep(int step) {
    if (mounted) setState(() => _currentStep = step);
  }

  Future<void> _processTransaction() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    final paymentProvider =
    Provider.of<PaymentProvider>(context, listen: false);

    if (fuelProvider.selectedProduct == null ||
        fuelProvider.selectedCurrency == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
              Text('Missing sale details. Please restart the sale.')),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    _updateStep(0);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) _updateStep(1);

    try {
      final success = await paymentProvider
          .processPayment(
        userId: authProvider.currentUser?.id.toString() ?? '0',
        productId: fuelProvider.selectedProduct!.id,
        currencyCode: fuelProvider.selectedCurrency!.code,
        amount: fuelProvider.selectedAmount,
        quantity: fuelProvider.selectedQuantity,
        paymentMethod: PaymentMethod.cash,
        operatorPin: authProvider.currentUser?.id.toString() ?? '0',
        customerId: widget.customerId,
        customerData: widget.customerData,
      )
          .timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception(
          'Transaction timed out after 60 seconds. Check Last Sale to confirm whether it went through.',
        ),
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
        final error =
            paymentProvider.errorMessage ?? 'Payment validation failed';
        if (_isConnectivityIssue(error)) {
          _showTimeoutScreen();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(12),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        _spinController.stop();
        final msg = e.toString().replaceAll('Exception: ', '');
        if (_isConnectivityIssue(msg)) {
          _showTimeoutScreen();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(12),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.of(context).pop();
        }
      }
    }
  }

  bool _isConnectivityIssue(String message) {
    final n = message.toLowerCase();
    return n.contains('timed out') ||
        n.contains('timeout') ||
        n.contains('lost internet connection') ||
        n.contains('failed to finish the process') ||
        n.contains('server not responding');
  }

  void _showTimeoutScreen() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => SuccessScreen(
          title: 'Transaction Error',
          message:
          'Please check your network connectivity. Check Last Sale to confirm whether transaction was completed before retrying.',
          actionText: 'Last Sale',
          onAction: () {
            navigator.pushReplacement(
              MaterialPageRoute(
                  builder: (_) => const LastSaleScreen(autoPrint: false)),
            );
          },
          accentColor: AppColors.error,
          icon: Icons.error_outline,
          showMerchantCopyButton: false,
        ),
      ),
    );
  }

  Future<void> _printReceiptCustomer() async {
    try {
      final pos = Provider.of<PosProvider>(context, listen: false);
      final fuel = Provider.of<FuelProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final payment = Provider.of<PaymentProvider>(context, listen: false);
      final r = payment.receiptData;
      final unit = _unitShort(fuel.selectedProduct?.unitOfMeasure);

      if (r != null && r.isNotEmpty) {
        await pos.printReceiptCopy(
          copyType: 'CUSTOMER COPY',
          stationName: (r['stationName'] ??
              auth.currentUser?.serviceStationName ??
              'Fuel Station')
              .toString(),
          address: (r['address'] ?? '').toString(),
          phone: (r['phone'] ?? '').toString(),
          date: (r['date'] ?? '').toString(),
          time: (r['time'] ?? '').toString(),
          pumpNo: (r['pumpNo'] ?? '1').toString(),
          product: (r['product'] ?? fuel.selectedProduct?.productName ?? 'Fuel')
              .toString(),
          unit: unit,
          litres: (r['litres'] ?? fuel.selectedQuantity.toStringAsFixed(2))
              .toString(),
          pricePerLitre:
          (r['pricePerLitre'] ?? fuel.selectedProduct?.price.toStringAsFixed(2) ?? '0.00')
              .toString(),
          total: (r['total'] ?? fuel.selectedAmount.toStringAsFixed(2))
              .toString(),
          payment: (r['payment'] ??
              payment.selectedPaymentMethod?.name ??
              '')
              .toString(),
          cardNo: (r['cardNo'] ?? '').toString(),
          authNo: (r['authNo'] ??
              payment.currentTransaction?.referenceNumber ??
              '')
              .toString(),
          rrn: (r['rrn'] ?? payment.currentTransaction?.id ?? '').toString(),
          operatorName:
          (r['attendant'] ?? auth.currentUser?.fullName ?? '').toString(),
        );
        return;
      }

      final product = fuel.selectedProduct;
      final currency = fuel.selectedCurrency;
      final txn = payment.currentTransaction;
      final stationName = product?.serviceStationName ??
          auth.currentUser?.serviceStationName ??
          'Fuel Station';
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');

      await pos.printReceiptCopy(
        copyType: 'CUSTOMER COPY',
        stationName: stationName,
        address: '',
        phone: '',
        date: '${now.year}-${two(now.month)}-${two(now.day)}',
        time: '${two(now.hour)}:${two(now.minute)}:${two(now.second)}',
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
      canPop: false,
      child: Scaffold(
        backgroundColor: _navyBg,
        body: Consumer3<FuelProvider, PaymentProvider, AuthProvider>(
          builder: (context, fuelProvider, paymentProvider, authProvider, _) {
            final product = fuelProvider.selectedProduct;
            final currency = fuelProvider.selectedCurrency;
            final amount = fuelProvider.selectedAmount;
            final quantity = fuelProvider.selectedQuantity;
            final unit = _unitShort(product?.unitOfMeasure);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Column(
                  children: [
                    // ── Top spacer ──
                    const Spacer(flex: 2),

                    // ── Spinner ──
                    _buildSpinner(),

                    const SizedBox(height: 28),

                    // ── Amount ──
                    _buildAmountDisplay(currency, amount),

                    const SizedBox(height: 8),

                    // ── Product + quantity ──
                    Text(
                      '${product?.productName ?? 'Fuel'}  ·  ${quantity.toStringAsFixed(2)} $unit',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _navyMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(flex: 2),

                    // ── Step progress ──
                    _buildStepProgress(),

                    const SizedBox(height: 24),

                    // ── Warning ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFFD98A), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Color(0xFFB07B00), size: 16),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Do not close this screen.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7A5500),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Spinner ───────────────────────────────────────────────

  Widget _buildSpinner() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: 110,
        height: 110,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _navy.withOpacity(0.06),
              ),
            ),
            // Spinning arc
            AnimatedBuilder(
              animation: _spinController,
              builder: (context, _) => CustomPaint(
                size: const Size(110, 110),
                painter: _ArcPainter(
                  progress: _spinController.value,
                  color: _navy,
                ),
              ),
            ),
            // Inner circle
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _navy,
              ),
              child: const Icon(
                Icons.payments_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Amount display ────────────────────────────────────────

  Widget _buildAmountDisplay(currency, double amount) {
    return Column(
      children: [
        const Text(
          'TOTAL AMOUNT',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.4,
            color: _navyMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${currency?.symbol ?? ''}${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: _navy,
            letterSpacing: -1.5,
          ),
        ),
      ],
    );
  }

  // ── Step progress ─────────────────────────────────────────

  Widget _buildStepProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        children: List.generate(_steps.length, (i) {
          final isDone = i < _currentStep;
          final isActive = i == _currentStep;
          final isPending = i > _currentStep;

          return Padding(
            padding: EdgeInsets.only(bottom: i < _steps.length - 1 ? 10 : 0),
            child: Row(
              children: [
                // Step indicator
                SizedBox(
                  width: 28,
                  height: 28,
                  child: isDone
                      ? Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2ECC71),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  )
                      : isActive
                      ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _navy.withOpacity(0.08),
                      border: Border.all(color: _navy, width: 1.5),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          valueColor:
                          const AlwaysStoppedAnimation(_navy),
                        ),
                      ),
                    ),
                  )
                      : Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                      border: Border.all(
                          color: const Color(0xFFDDE4EE),
                          width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: _navyMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _steps[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isPending
                          ? const Color(0xFFBBCCDD)
                          : isDone
                          ? const Color(0xFF2ECC71)
                          : _navy,
                    ),
                  ),
                ),
                if (isDone)
                  const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2ECC71),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Arc spinner painter ───────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    final startAngle = progress * 2 * math.pi;
    const sweepAngle = math.pi * 1.2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}