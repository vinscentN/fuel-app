// screens/payment/payment_method_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fuel_provider.dart';
import '../../providers/payment_provider.dart';
import '../../utils/colors.dart';
import '../../models/transaction.dart';
import '../../models/customer.dart';
import '../../services/external_payment_service.dart';
import 'card_payment_screen.dart';
import 'cash_payment_screen.dart';
import 'transaction_processing_screen.dart';
import '../common/customer_details_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Navy palette — consistent across all screens
  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _selectPaymentMethod(PaymentMethod method) async {
    final paymentProvider =
    Provider.of<PaymentProvider>(context, listen: false);
    paymentProvider.selectPaymentMethod(method);

    switch (method) {
      case PaymentMethod.card:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CardPaymentScreen()),
        );
        break;
      case PaymentMethod.cash:
        await _processCashPayment();
        break;
      case PaymentMethod.mobile:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Mobile Money temporarily unavailable')),
        );
        return;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported payment method')),
        );
        return;
    }
  }

  Future<void> _processCashPayment() async {
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);

    if (fuelProvider.selectedProduct == null ||
        fuelProvider.selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Missing sale details. Please restart the sale.')),
      );
      return;
    }

    final customerResult =
    await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const CustomerDetailsScreen(
          title: 'Customer Details',
          subtitle:
          'Search for existing customer or add new customer details',
        ),
      ),
    );

    if (!mounted) return;
    if (customerResult == null) return;

    final customerId = customerResult['customerId'] as int?;
    final customerData = customerResult['customerData'] as CustomerData?;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionProcessingScreen(
          customerId: customerId,
          customerData: customerData,
        ),
      ),
    );
  }

  Future<void> _launchExternalPayment(String method) async {
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    await ExternalPaymentService.launchExternalPaymentApp(
      amount: fuelProvider.selectedAmount,
      currency: 'USD',
      method: method,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(),
      body: Consumer2<FuelProvider, PaymentProvider>(
        builder: (context, fuelProvider, paymentProvider, child) {
          final product = fuelProvider.selectedProduct;
          final currency = fuelProvider.selectedCurrency;

          if (product == null || currency == null) {
            return const Center(child: Text('Error: Missing data'));
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                _buildSummaryStrip(fuelProvider, currency),
                const SizedBox(height: 14),
                _sectionLabel('Select Payment Method'),
                const SizedBox(height: 8),
                _buildPaymentMethodCard(
                  icon: Icons.money_rounded,
                  title: 'Cash Payment',
                  subtitle: 'Pay with cash at the counter',
                  method: PaymentMethod.cash,
                ),
                // Uncomment to re-enable additional methods:
                // const SizedBox(height: 8),
                // _buildPaymentMethodCard(
                //   icon: Icons.credit_card_rounded,
                //   title: 'Card Payment',
                //   subtitle: 'Pay with debit or credit card',
                //   method: PaymentMethod.card,
                // ),
                // const SizedBox(height: 8),
                // _buildExternalPaymentCard(
                //   icon: Icons.credit_card_outlined,
                //   title: 'Zimswitch',
                //   subtitle: 'Pay via external Zimswitch app',
                //   method: 'Swipe',
                // ),
                // const SizedBox(height: 8),
                // _buildExternalPaymentCard(
                //   icon: Icons.phone_android_rounded,
                //   title: 'Mobile Money',
                //   subtitle: 'Pay with EcoCash or mobile money',
                //   method: 'EcoCash',
                // ),
              ],
            ),
          );
        },
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
                  child: const Icon(Icons.payment_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Choose how to pay',
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

  // ── Summary strip ─────────────────────────────────────────

  Widget _buildSummaryStrip(FuelProvider fuelProvider, currency) {
    final unit = _unitShort(fuelProvider.selectedProduct?.unitOfMeasure);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          // Amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL AMOUNT',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: Color(0xFF8899BB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${currency.symbol}${fuelProvider.selectedAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withOpacity(0.12),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          // Quantity
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'QUANTITY',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.2,
                  color: Color(0xFF8899BB),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${fuelProvider.selectedQuantity.toStringAsFixed(2)} $unit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.local_gas_station_rounded,
                color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _navyMuted,
        letterSpacing: 1.1,
      ),
    );
  }

  // ── Payment method card ───────────────────────────────────

  Widget _buildPaymentMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required PaymentMethod method,
  }) {
    return Material(
      color: _navy,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _selectPaymentMethod(method),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── External payment card ─────────────────────────────────

  Widget _buildExternalPaymentCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String method,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _launchExternalPayment(method),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _navy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _navyMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.open_in_new_rounded,
                    color: _navy, size: 14),
              ),
            ],
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