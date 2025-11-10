// screens/payment/payment_method_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fuel_provider.dart';
import '../../providers/payment_provider.dart';
import '../../utils/colors.dart';
import '../../models/transaction.dart';
import '../../widgets/common/app_bar_widget.dart';
import '../../widgets/common/custom_button.dart';
import 'card_payment_screen.dart';
import 'cash_payment_screen.dart';
// import 'mobile_payment_screen.dart'; // Temporarily disabled

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectPaymentMethod(PaymentMethod method) {
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    paymentProvider.selectPaymentMethod(method);

    Widget nextScreen;
    switch (method) {
      case PaymentMethod.card:
        nextScreen = const CardPaymentScreen();
        break;
      case PaymentMethod.cash:
        nextScreen = const CashPaymentScreen();
        break;
      case PaymentMethod.mobile:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mobile Money temporarily unavailable')),
        );
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Payment Method',
        backgroundColor: navyBlue,
      ),
      body: Consumer2<FuelProvider, PaymentProvider>(
        builder: (context, fuelProvider, paymentProvider, child) {
          final product = fuelProvider.selectedProduct;
          final currency = fuelProvider.selectedCurrency;

          if (product == null || currency == null) {
            return const Center(child: Text('Error: Missing data'));
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Compact summary at top
                _buildCompactSummary(fuelProvider, currency),
                // Scrollable payment methods
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPaymentMethodsSection(),
                      ],
                    ),
                  ),
                ),
                // Fixed back button at bottom
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
                  child: _buildBackButton(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactSummary(FuelProvider fuelProvider, currency) {
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
                'Total Amount',
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
              Icons.local_gas_station,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Payment Method',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _buildPaymentMethodCard(
          icon: Icons.credit_card,
          title: 'Card Payment',
          subtitle: 'Pay with debit or credit card',
          color: navyBlue,
          method: PaymentMethod.card,
          delay: 0,
        ),
        const SizedBox(height: 16),
        _buildPaymentMethodCard(
          icon: Icons.money,
          title: 'Cash Payment',
          subtitle: 'Pay with cash and validate with PIN',
          color: lightNavyBlue,
          method: PaymentMethod.cash,
          delay: 100,
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 20), // Extra space for visual separation
      ],
    );
  }

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required PaymentMethod method,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                onTap: () => _selectPaymentMethod(method),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(18), // Slightly reduced padding
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.1),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 55, // Slightly smaller
                        height: 55,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return CustomButton(
      onPressed: () => Navigator.of(context).pop(),
      isOutlined: true,
      backgroundColor: AppColors.textSecondary,
      child: const Text(
        'Back to Amount',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
