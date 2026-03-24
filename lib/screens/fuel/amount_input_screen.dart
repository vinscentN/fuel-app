// screens/fuel/amount_input_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/fuel_provider.dart';
import '../../models/currency.dart';
import '../../models/product.dart';
import '../../utils/colors.dart';
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
  late Animation<double> _fadeAnimation;

  bool _isAmountInput = true;

  // Navy palette — matches dashboard & last sale screens
  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
      fuelProvider.selectProduct(widget.product);
      fuelProvider.selectCurrency(
          _currencyFromCode(widget.product.currencyCode));
    });
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
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

  void _proceedToPayment() {
    if (!_formKey.currentState!.validate()) return;
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    if (fuelProvider.selectedAmount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Currency _currencyFromCode(String code) {
    final upper = code.toUpperCase();
    switch (upper) {
      case 'USD':
        return Currency(
            code: 'USD',
            name: 'US Dollar',
            symbol: '\$',
            exchangeRate: 1.0);
      case 'ZWL':
        return Currency(
            code: 'ZWL',
            name: 'Zimbabwe Dollar',
            symbol: 'ZWL\$',
            exchangeRate: 1.0);
      case 'ZAR':
        return Currency(
            code: 'ZAR',
            name: 'South African Rand',
            symbol: 'R',
            exchangeRate: 1.0);
      default:
        return Currency(
            code: upper, name: upper, symbol: upper, exchangeRate: 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBg,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        bottom: true,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              14,
              14,
              14,
              14 +
                  MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom +
                  8,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProductStrip(),
                  const SizedBox(height: 10),
                  _buildToggle(),
                  const SizedBox(height: 10),
                  _buildInputCard(),
                  const SizedBox(height: 16),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Container(
        decoration: const BoxDecoration(
          color: _navy,
          border: Border(
            bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                  splashRadius: 20,
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_gas_station_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Amount',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Set amount or quantity',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Product strip ─────────────────────────────────────────

  Widget _buildProductStrip() {
    final unit = _unitShort(widget.product.unitOfMeasure);
    final symbol = _codeWithSymbol(widget.product.currencyCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.product.productName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$symbol${widget.product.price.toStringAsFixed(2)} / $unit',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Toggle ────────────────────────────────────────────────

  Widget _buildToggle() {
    final unitPlural = _unitPlural(widget.product.unitOfMeasure);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _toggleOption(
            label: 'Amount',
            icon: Icons.attach_money_rounded,
            selected: _isAmountInput,
            onTap: () => setState(() => _isAmountInput = true),
          ),
          _toggleOption(
            label: unitPlural,
            icon: Icons.local_gas_station_rounded,
            selected: !_isAmountInput,
            onTap: () => setState(() => _isAmountInput = false),
          ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _navy.withOpacity(0.09) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: selected
                ? Border.all(color: _navy.withOpacity(0.18), width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: selected ? _navy : _navyMuted, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? _navy : _navyMuted,
                  fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Input card ────────────────────────────────────────────

  Widget _buildInputCard() {
    final fuelProvider =
    Provider.of<FuelProvider>(context, listen: false);
    final price = widget.product.price;
    final currency = widget.product.currencyCode;
    final unitPlural = _unitPlural(widget.product.unitOfMeasure);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  _isAmountInput
                      ? Icons.attach_money_rounded
                      : Icons.local_gas_station_rounded,
                  color: _navy,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isAmountInput ? 'Enter Amount' : 'Enter Quantity',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isAmountInput)
            CustomTextField(
              controller: _amountController,
              label: 'Amount ($currency)',
              hint: '0.00',
              prefixIcon: Icons.attach_money_rounded,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
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
                  return 'Enter a valid amount';
                }
                return null;
              },
            )
          else
            CustomTextField(
              controller: _quantityController,
              label: 'Quantity ($unitPlural)',
              hint: '0.00',
              prefixIcon: Icons.local_gas_station_rounded,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final qty = double.tryParse(value) ?? 0.0;
                fuelProvider.setQuantity(qty);
                _amountController.text =
                    (qty * price).toStringAsFixed(2);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                final qty = double.tryParse(value);
                if (qty == null || qty <= 0) {
                  return 'Enter a valid quantity';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  // ── Buttons ───────────────────────────────────────────────

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: _proceedToPayment,
            style: TextButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.payment_rounded, size: 18),
            label: const Text(
              'Proceed to Payment',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: _navyMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: _navyMuted.withOpacity(0.3)),
              ),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────

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

  String _codeWithSymbol(String code) {
    final c = code.toUpperCase();
    switch (c) {
      case 'USD':
        return '\$';
      case 'ZWL':
      case 'ZWG':
        return '${c}\$';
      case 'ZAR':
        return 'R';
      default:
        return c;
    }
  }
}