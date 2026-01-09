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

  bool _isProcessing = true;
  int _currentStep = 0;
  final List<String> _steps = [
    'Validating transaction...',
    'Processing payment...',
    'Printing receipt...',
    'Finalizing...',
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
      _updateStep(2);
      await _printReceiptCustomer();
      if (!mounted) return;

      _updateStep(3);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      setState(() => _isProcessing = false);
      _spinController.stop();

      await Future.delayed(const Duration(milliseconds: 800));
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
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          // Center ensures the Column stays centered horizontally on any screen size
          child: Center(
            child: Consumer3<FuelProvider, PaymentProvider, AuthProvider>(
              builder: (context, fuelProvider, paymentProvider, authProvider, child) {
                final product = fuelProvider.selectedProduct;
                final currency = fuelProvider.selectedCurrency;
                final unit = _unitShort(product?.unitOfMeasure);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                    child: Container(
                      // Constrain width so it looks good on tablets, but full width on phones
                      constraints: const BoxConstraints(maxWidth: 500),
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildMainIndicator(),
                          const SizedBox(height: 40),
                          _buildDetailsCard(
                            product: product,
                            currency: currency,
                            unit: unit,
                            fuelProvider: fuelProvider,
                          ),
                          const SizedBox(height: 24),
                          if (_isProcessing) _buildProgressSteps(),
                          const SizedBox(height: 24),
                          if (_isProcessing) _buildWarningMessage(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isProcessing
                        ? [const Color(0xFF3B82F6).withOpacity(0.2), const Color(0xFF2563EB).withOpacity(0.1)]
                        : [const Color(0xFF10B981).withOpacity(0.2), const Color(0xFF059669).withOpacity(0.1)],
                  ),
                ),
              ),
            ),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: (_isProcessing ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _isProcessing
                  ? AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: SpinnerPainter(
                      progress: _spinController.value,
                      color: const Color(0xFF3B82F6),
                    ),
                    child: const Center(
                      child: Icon(Icons.payments_rounded, size: 60, color: Color(0xFF3B82F6)),
                    ),
                  );
                },
              )
                  : const Center(
                child: Icon(Icons.check_circle_rounded, size: 80, color: Color(0xFF10B981)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          _isProcessing ? 'Processing Transaction' : 'Transaction Complete!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isProcessing ? const Color(0xFF1E293B) : const Color(0xFF10B981),
          ),
        ),
        const SizedBox(height: 8),
        if (_isProcessing)
          Text(
            _steps[_currentStep],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          )
        else
          const Text(
            'Payment successful',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF10B981), fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  Widget _buildDetailsCard({
    required product,
    required currency,
    required String unit,
    required FuelProvider fuelProvider,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary.withOpacity(0.1), AppColors.primary.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Text(
                  'TOTAL AMOUNT',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary.withOpacity(0.7), letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(currency?.symbol ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    Text(
                      fuelProvider.selectedAmount.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: -1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDetailRow(icon: Icons.local_gas_station_rounded, label: 'Product', value: product?.productName ?? 'N/A', color: const Color(0xFF3B82F6)),
                const SizedBox(height: 16),
                _buildDetailRow(icon: Icons.speed_rounded, label: 'Quantity', value: '${fuelProvider.selectedQuantity.toStringAsFixed(2)} $unit', color: const Color(0xFF8B5CF6)),
                const SizedBox(height: 16),
                _buildDetailRow(icon: Icons.attach_money_rounded, label: 'Price per $unit', value: '${currency?.symbol ?? ''}${product?.price.toStringAsFixed(2) ?? '0.00'}', color: const Color(0xFFF59E0B)),
                const SizedBox(height: 16),
                _buildDetailRow(icon: Icons.payments_rounded, label: 'Payment Method', value: 'CASH', color: const Color(0xFF10B981)),
                if (widget.customerData != null || widget.customerId != null) ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(icon: Icons.person_rounded, label: 'Customer', value: widget.customerData?.name ?? 'Registered Customer', color: const Color(0xFFEC4899)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value, required Color color}) {
    return Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          ...List.generate(_steps.length, (index) {
            final isCompleted = index < _currentStep;
            final isCurrent = index == _currentStep;
            return Padding(
              padding: EdgeInsets.only(bottom: index < _steps.length - 1 ? 12 : 0),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? const Color(0xFF10B981) : isCurrent ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : isCurrent ? const Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _steps[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                        color: isCompleted || isCurrent ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWarningMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.amber.shade50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
            child: Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please wait. Do not close or navigate away.',
              style: TextStyle(fontSize: 13, color: Colors.orange.shade900, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
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