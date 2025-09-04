// screens/fuel/amount_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/fuel_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/common/app_bar_widget.dart';
import '../../widgets/common/custom_text_field.dart';
import '../payment/payment_method_screen.dart';

class AmountInputScreen extends StatefulWidget {
  const AmountInputScreen({super.key});

  @override
  State<AmountInputScreen> createState() => _AmountInputScreenState();
}

class _AmountInputScreenState extends State<AmountInputScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  bool _isAmountInput = true; // true for amount, false for quantity

  // Navy blue color scheme
  static const Color navyBlue = Color(0xFF1E3A8A);
  static const Color lightNavyBlue = Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) {
    if (value.isEmpty) return;

    final amount = double.tryParse(value) ?? 0.0;
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    fuelProvider.setAmount(amount);

    if (fuelProvider.selectedQuantity > 0) {
      _quantityController.text = fuelProvider.selectedQuantity.toStringAsFixed(
        2,
      );
    }
  }

  void _onQuantityChanged(String value) {
    if (value.isEmpty) return;

    final quantity = double.tryParse(value) ?? 0.0;
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    fuelProvider.setQuantity(quantity);

    if (fuelProvider.selectedAmount > 0) {
      _amountController.text = fuelProvider.selectedAmount.toStringAsFixed(2);
    }
  }

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) return;

    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    if (fuelProvider.selectedAmount <= 0) {
      _showErrorMessage('Please enter a valid amount');
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PaymentMethodScreen()));
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'Enter Amount', backgroundColor: navyBlue),

      body: Consumer<FuelProvider>(
        builder: (context, fuelProvider, child) {
          final product = fuelProvider.selectedProduct;
          final currency = fuelProvider.selectedCurrency;

          if (product == null || currency == null) {
            return const Center(child: Text('Error: Missing data'));
          }

          final price = product.prices[currency.code] ?? 0.0;

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCompactSummary(product, currency, price),
                    const SizedBox(height: 16),
                    _buildCompactToggle(),
                    const SizedBox(height: 16),
                    _buildCompactInput(fuelProvider, currency, price),
                    const SizedBox(height: 20),
                    _buildCompactButtons(fuelProvider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactSummary(product, currency, double price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: navyBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: navyBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.local_gas_station, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${currency.symbol}${price.toStringAsFixed(2)}/L',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            currency.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAmountInput = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isAmountInput ? navyBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: _isAmountInput ? Colors.white : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Amount',
                      style: TextStyle(
                        color: _isAmountInput ? Colors.white : Colors.grey[600],
                        fontWeight:
                            _isAmountInput
                                ? FontWeight.w600
                                : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAmountInput = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isAmountInput ? navyBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      color: !_isAmountInput ? Colors.white : Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Liters',
                      style: TextStyle(
                        color:
                            !_isAmountInput ? Colors.white : Colors.grey[600],
                        fontWeight:
                            !_isAmountInput
                                ? FontWeight.w600
                                : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInput(FuelProvider fuelProvider, currency, double price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isAmountInput ? 'Enter Amount' : 'Enter Quantity',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (_isAmountInput) ...[
            CustomTextField(
              controller: _amountController,
              label: 'Amount (${currency.symbol})',
              hint: 'Enter amount',
              prefixIcon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: _onAmountChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount > 10000) {
                  return 'Amount cannot exceed ${currency.symbol}10,000';
                }
                return null;
              },
            ),
          ] else ...[
            CustomTextField(
              controller: _quantityController,
              label: 'Quantity (Liters)',
              hint: 'Enter liters',
              prefixIcon: Icons.local_gas_station,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: _onQuantityChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                final quantity = double.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return 'Please enter a valid quantity';
                }
                if (quantity > 1000) {
                  return 'Quantity cannot exceed 1000 liters';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: lightNavyBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: lightNavyBlue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isAmountInput
                        ? 'Quantity calculated automatically'
                        : 'Amount calculated automatically',
                    style: TextStyle(fontSize: 12, color: lightNavyBlue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactButtons(FuelProvider fuelProvider) {
    final canProceed = fuelProvider.selectedAmount > 0;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: canProceed ? _proceedToPayment : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: navyBlue,
              disabledBackgroundColor: Colors.grey[300],
              elevation: canProceed ? 4 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Center(
              child: Text(
                'Proceed to Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: canProceed ? Colors.white : Colors.grey[600],
                  height: 0.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Back',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
