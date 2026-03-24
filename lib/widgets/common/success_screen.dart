// screens/common/success_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../screens/home/dashboard_screen.dart';
import '../../providers/payment_provider.dart';
import '../../providers/fuel_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/auth_provider.dart';

class SuccessScreen extends StatefulWidget {
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color accentColor;
  final IconData icon;
  final bool showMerchantCopyButton;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;

  const SuccessScreen({
    super.key,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.accentColor = AppColors.success,
    this.icon = Icons.check,
    this.showMerchantCopyButton = true,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleAction() {
    if (widget.onAction != null) {
      widget.onAction!();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  void _handleSecondaryAction() {
    if (widget.onSecondaryAction != null) {
      widget.onSecondaryAction!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.message,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        CustomButton(
                          onPressed: _handleAction,
                          backgroundColor: widget.accentColor,
                          child: Text(
                            widget.actionText ?? 'Back to Dashboard',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.secondaryActionText != null &&
                            widget.onSecondaryAction != null) ...[
                          const SizedBox(height: 12),
                          CustomButton(
                            onPressed: _handleSecondaryAction,
                            isOutlined: true,
                            backgroundColor: widget.accentColor,
                            child: Text(
                              widget.secondaryActionText!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (widget.showMerchantCopyButton) ...[
                          const SizedBox(height: 12),
                          CustomButton(
                            onPressed: () async {
                              final pos = Provider.of<PosProvider>(context, listen: false);
                              final fuel = Provider.of<FuelProvider>(context, listen: false);
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              final payment = Provider.of<PaymentProvider>(context, listen: false);

                              final r = payment.receiptData;
                              if (r != null && r.isNotEmpty) {
                                final unit = _unitShort(fuel.selectedProduct?.unitOfMeasure);
                                await pos.printReceiptCopy(
                                  copyType: 'MERCHANT COPY',
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
                              } else {
                                final product = fuel.selectedProduct;
                                final currency = fuel.selectedCurrency;
                                final txn = payment.currentTransaction;
                                final stationName = product?.serviceStationName ??
                                    auth.currentUser?.serviceStationName ??
                                    'Fuel Station';

                                final now = DateTime.now();
                                String two(int n) => n.toString().padLeft(2, '0');
                                final date = '${now.year}-${two(now.month)}-${two(now.day)}';
                                final time = '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';

                                final unit = _unitShort(product?.unitOfMeasure);
                                await pos.printReceiptCopy(
                                  copyType: 'MERCHANT COPY',
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
                                  payment: payment.selectedPaymentMethod?.name ?? '',
                                  cardNo: '',
                                  authNo: txn?.referenceNumber ?? txn?.id ?? '',
                                  rrn: txn?.id ?? txn?.referenceNumber ?? '',
                                  operatorName: auth.currentUser?.fullName ?? '',
                                );
                              }
                            },
                            isOutlined: true,
                            backgroundColor: AppColors.textSecondary,
                            child: const Text(
                              'Print Merchant Copy',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
}
