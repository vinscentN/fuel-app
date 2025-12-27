// screens/payment/mobile_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/fuel_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../models/transaction.dart';
import '../../widgets/common/app_bar_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/success_screen.dart';
import '../common/success_screen.dart';

class MobilePaymentScreen extends StatefulWidget {
  const MobilePaymentScreen({super.key});

  @override
  State<MobilePaymentScreen> createState() => _MobilePaymentScreenState();
}

class _MobilePaymentScreenState extends State<MobilePaymentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Use app navy color via AppColors.primary

  String _selectedProvider = 'EcoCash';
  final List<Map<String, dynamic>> _providers = [
    {'name': 'EcoCash', 'color': Colors.green, 'icon': Icons.phone_android},
    {'name': 'OneMoney', 'color': Colors.red, 'icon': Icons.smartphone},
    {'name': 'Innbucks', 'color': Colors.blue, 'icon': Icons.mobile_friendly},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
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
    _mobileController.dispose();
    super.dispose();
  }

  String _formatMobileNumber(String value) {
    // Remove all non-digits
    value = value.replaceAll(RegExp(r'[^\d]'), '');

    // Add country code if not present
    if (value.isNotEmpty && !value.startsWith('263')) {
      if (value.startsWith('0')) {
        value = '263${value.substring(1)}';
      } else {
        value = '263$value';
      }
    }

    // Format as +263 XX XXX XXXX
    if (value.length >= 3) {
      String formatted = '+${value.substring(0, 3)}';
      if (value.length > 3) {
        formatted += ' ${value.substring(3, value.length > 5 ? 5 : value.length)}';
      }
      if (value.length > 5) {
        formatted += ' ${value.substring(5, value.length > 8 ? 8 : value.length)}';
      }
      if (value.length > 8) {
        formatted += ' ${value.substring(8)}';
      }
      return formatted;
    }

    return value.isNotEmpty ? '+$value' : value;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

    final mobileNumber = _mobileController.text.replaceAll(RegExp(r'[^\d]'), '');

    final success = await paymentProvider.processPayment(
      userId: authProvider.currentUser!.id.toString(),
      productId: fuelProvider.selectedProduct!.id,
      currencyCode: fuelProvider.selectedCurrency!.code,
      amount: fuelProvider.selectedAmount,
      quantity: fuelProvider.selectedQuantity,
      paymentMethod: PaymentMethod.mobile,
      mobileNumber: mobileNumber,
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SuccessScreen(
            title: 'Mobile Payment Successful!',
            message: 'Payment processed via mobile money successfully.',
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.errorMessage ?? 'Mobile payment failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Mobile Money',
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: Column(
              children: [
                // Compact summary at top
                _buildCompactSummary(),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProviderSelection(),
                          const SizedBox(height: 24),
                          _buildMobileNumberForm(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Fixed buttons at bottom (safe from system insets)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactSummary() {
    return Consumer<FuelProvider>(
      builder: (context, fuelProvider, child) {
        final currency = fuelProvider.selectedCurrency!;

        return Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
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
                    'Mobile Payment',
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
                  Icons.phone_android,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProviderSelection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Mobile Money Provider',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._providers.map((provider) {
              final isSelected = _selectedProvider == provider['name'];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedProvider = provider['name'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? provider['color'] as Color
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected
                          ? (provider['color'] as Color).withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                            (provider['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            provider['icon'] as IconData,
                            color: provider['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          provider['name'] as String,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: provider['color'] as Color,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNumberForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mobile Number',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _mobileController,
              label: 'Mobile Number',
              hint: '+263 XX XXX XXXX',
              prefixIcon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return TextEditingValue(
                    text: _formatMobileNumber(newValue.text),
                    selection: TextSelection.collapsed(
                      offset: _formatMobileNumber(newValue.text).length,
                    ),
                  );
                }),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter mobile number';
                }
                final digits = value.replaceAll(RegExp(r'[^\d]'), '');
                if (digits.length < 12) {
                  return 'Please enter a valid mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primaryLight, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter the mobile number registered with $_selectedProvider',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryLight,
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

  Widget _buildActionButtons(PaymentProvider paymentProvider) {
    return Column(
      children: [
        CustomButton(
          onPressed: paymentProvider.isProcessing ? null : _processPayment,
          backgroundColor: AppColors.primary,
          child: paymentProvider.isProcessing
              ? const LoadingWidget(size: 24, color: Colors.white)
              : const Text(
            'Send Payment Request',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        CustomButton(
          onPressed:
          paymentProvider.isProcessing ? null : () => Navigator.of(context).pop(),
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
