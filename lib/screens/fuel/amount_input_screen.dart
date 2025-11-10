// screens/fuel/amount_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/fuel_provider.dart';
import '../../models/currency.dart';
import '../../models/product.dart';
import '../../utils/colors.dart';
import '../../widgets/common/app_bar_widget.dart';
import '../../widgets/common/custom_text_field.dart';
import '../payment/payment_method_screen.dart';

class AmountInputScreen extends StatefulWidget {
  final Product product;

  const AmountInputScreen({super.key, required this.product});

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

  bool _isAmountInput = true;
  // Use app navy via AppColors.primary

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
      fuelProvider.selectProduct(widget.product);
      // Ensure currency is set for downstream payment screens
      fuelProvider.selectCurrency(_currencyFromCode(widget.product.currencyCode));
    });
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    _amountController.dispose();
    _quantityController.dispose();
    // ❌ REMOVED: Do not reset the provider here.
    // The state should persist for the next screens in the flow.
    super.dispose();
  }

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) return;
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    if (fuelProvider.selectedAmount <= 0) {
      _showErrorMessage('Please enter a valid amount');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
    );
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

  Currency _currencyFromCode(String code) {
    final upper = code.toUpperCase();
    switch (upper) {
      case 'USD':
        return Currency(code: 'USD', name: 'US Dollar', symbol: '\$', exchangeRate: 1.0);
      case 'ZWL':
        return Currency(code: 'ZWL', name: 'Zimbabwe Dollar', symbol: 'ZWL\$', exchangeRate: 1.0);
      case 'ZAR':
        return Currency(code: 'ZAR', name: 'South African Rand', symbol: 'R', exchangeRate: 1.0);
      default:
        return Currency(code: upper, name: upper, symbol: upper, exchangeRate: 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(
        title: 'Enter Amount',
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        bottom: true,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(_slideAnimation),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16.0,
              16.0,
              16.0,
              16.0 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 8.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCompactSummary(widget.product, widget.product.price, widget.product.currencyCode),
                  const SizedBox(height: 16),
                  _buildCompactToggle(),
                  const SizedBox(height: 16),
                  _buildCompactInput(Provider.of<FuelProvider>(context, listen: false), widget.product.price, widget.product.currencyCode),
                  const SizedBox(height: 20),
                  _buildCompactButtons(Provider.of<FuelProvider>(context, listen: false)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSummary(Product product, double price, String currency) {
    final unitShort = _unitShort(product.unitOfMeasure);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Accent bar
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          // Product + station
          Expanded(
            child: Text(
              product.productName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Price chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_codeWithSymbol(currency)}${price.toStringAsFixed(2)}/$unitShort',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToggle() {
    final unitPlural = _unitPlural(widget.product.unitOfMeasure);
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
                  color: _isAmountInput ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.attach_money,
                        color:
                        _isAmountInput ? Colors.white : Colors.grey[600],
                        size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Amount',
                      style: TextStyle(
                        color: _isAmountInput
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: _isAmountInput
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
                  color: !_isAmountInput ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_gas_station,
                        color:
                        !_isAmountInput ? Colors.white : Colors.grey[600],
                        size: 18),
                    const SizedBox(width: 6),
                    Text(
                      unitPlural,
                      style: TextStyle(
                        color: !_isAmountInput
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: !_isAmountInput
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

  Widget _buildCompactInput(
      FuelProvider fuelProvider, double price, String currency) {
    final unitPlural = _unitPlural(widget.product.unitOfMeasure);
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
              label: 'Amount ($currency)',
              hint: 'Enter amount',
              prefixIcon: Icons.attach_money,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                fuelProvider.setAmount(amount);
                if (price > 0) {
                  _quantityController.text =
                      (amount / price).toStringAsFixed(2);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Enter valid amount';
                }
                return null;
              },
            ),
          ] else ...[
            CustomTextField(
              controller: _quantityController,
              label: 'Quantity ($unitPlural)',
              hint: 'Enter $unitPlural',
              prefixIcon: Icons.local_gas_station,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0.0;
                fuelProvider.setQuantity(qty);
                _amountController.text = (qty * price).toStringAsFixed(2);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                final qty = double.tryParse(value);
                if (qty == null || qty <= 0) {
                  return 'Enter valid quantity';
                }
                return null;
              },
            ),
          ],

          // Info helper removed per request
        ],
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

  String _codeWithSymbol(String code) {
    final c = code.toUpperCase();
    switch (c) {
      case 'USD':
        return 'USD\$';
      case 'ZWL':
      case 'ZWG':
        return '${c}\$';
      case 'ZAR':
        return 'ZARR';
      default:
        return c;
    }
  }

  String _unitPlural(String? uom) {
    final code = (uom ?? 'L').trim().toUpperCase();
    switch (code) {
      case 'L':
      case 'LT':
      case 'LTR':
      case 'LITRE':
      case 'LITER':
        return 'Litres';
      case 'KG':
      case 'KGS':
      case 'KILOGRAM':
      case 'KILOGRAMS':
        return 'Kgs';
      default:
        return code;
    }
  }

  Widget _buildCompactButtons(FuelProvider fuelProvider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _proceedToPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Proceed to Payment',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
