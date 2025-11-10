// screens/payment/cash_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../providers/fuel_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../models/transaction.dart';
import '../../widgets/common/app_bar_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/success_screen.dart';
import '../common/success_screen.dart';

class CashPaymentScreen extends StatefulWidget {
  const CashPaymentScreen({super.key});

  @override
  State<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends State<CashPaymentScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPinEntered = false;
  String _operatorPin = '';

  // Navy blue color scheme
  static const Color navyBlue = Color(0xFF1E3A8A);
  static const Color lightNavyBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onPinCompleted(String pin) {
    setState(() {
      _operatorPin = pin;
      _isPinEntered = true;
    });
  }

  Future<void> _processPayment() async {
    if (_operatorPin.length != 4) {
      _showErrorMessage('Please enter a 4-digit PIN');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

    final success = await paymentProvider.processPayment(
      userId: authProvider.currentUser!.id,
      productId: fuelProvider.selectedProduct!.id,
      currencyCode: fuelProvider.selectedCurrency!.code,
      amount: fuelProvider.selectedAmount,
      quantity: fuelProvider.selectedQuantity,
      paymentMethod: PaymentMethod.cash,
      operatorPin: _operatorPin,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SuccessScreen(
            title: 'Cash Payment Confirmed!',
            message: 'Transaction validated successfully with operator PIN.',
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.errorMessage ?? 'Payment validation failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Cash Payment',
        backgroundColor: navyBlue,
      ),
      body: Consumer3<FuelProvider, PaymentProvider, AuthProvider>(
        builder: (context, fuelProvider, paymentProvider, authProvider, child) {
          return Column(
            children: [
              // Compact summary at top
              _buildCompactSummary(fuelProvider),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPinSection(),
                    ],
                  ),
                ),
              ),
              // Fixed buttons at bottom
              Container(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: _buildActionButtons(paymentProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactSummary(FuelProvider fuelProvider) {
    final currency = fuelProvider.selectedCurrency!;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: navyBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: navyBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cash Amount',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${currency.symbol}${fuelProvider.selectedAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Quantity',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${fuelProvider.selectedQuantity.toStringAsFixed(2)} L',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.money,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.security,
                    color: navyBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Enter Operator PIN',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your 4-digit operator PIN to validate the cash transaction',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PinCodeTextField(
                appContext: context,
                length: 4,
                controller: _pinController,
                obscureText: true,
                obscuringCharacter: '●',
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 60,
                  fieldWidth: 60,
                  activeFillColor: navyBlue.withOpacity(0.1),
                  inactiveFillColor: AppColors.surfaceVariant,
                  selectedFillColor: navyBlue.withOpacity(0.2),
                  activeColor: navyBlue,
                  inactiveColor: AppColors.border,
                  selectedColor: navyBlue,
                ),
                enableActiveFill: true,
                onCompleted: _onPinCompleted,
                onChanged: (value) {
                  setState(() {
                    _isPinEntered = value.length == 4;
                    if (value.length < 4) {
                      _operatorPin = '';
                    }
                  });
                },
              ),
              if (_isPinEntered) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PIN Entered Successfully',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightNavyBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: lightNavyBlue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: lightNavyBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo PIN: 1234 (for testing purposes)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: lightNavyBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(PaymentProvider paymentProvider) {
    return Column(
      children: [
        CustomButton(
          onPressed: paymentProvider.isProcessing || !_isPinEntered
              ? null
              : _processPayment,
          backgroundColor: navyBlue,
          child: paymentProvider.isProcessing
              ? const LoadingWidget(size: 24, color: Colors.white)
              : const Text(
            'Validate & Complete Transaction',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CustomButton(
          onPressed: paymentProvider.isProcessing
              ? null
              : () => Navigator.of(context).pop(),
          isOutlined: true,
          backgroundColor: AppColors.textSecondary,
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}