// screens/payment/cash_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fuel_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/common/app_bar_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/success_screen.dart';
import '../../models/transaction.dart';
import '../../models/customer.dart';
import '../common/customer_details_screen.dart';

class CashPaymentScreen extends StatefulWidget {
  const CashPaymentScreen({super.key});

  @override
  State<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends State<CashPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

    // Guard required fields
    if (fuelProvider.selectedProduct == null ||
        fuelProvider.selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing sale details. Please restart the sale.')),
      );
      return;
    }

    // Navigate to customer details screen
    final customerResult = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => const CustomerDetailsScreen(
          title: 'Customer Details',
          subtitle: 'Search for existing customer or add new customer details',
        ),
      ),
    );

    if (!mounted) return;

    // Extract customer data from result
    int? customerId;
    CustomerData? customerData;

    if (customerResult != null) {
      customerId = customerResult['customerId'] as int?;
      customerData = customerResult['customerData'] as CustomerData?;
    }

    final success = await paymentProvider.processPayment(
      userId: authProvider.currentUser?.id.toString() ?? '0',
      productId: fuelProvider.selectedProduct!.id,
      currencyCode: fuelProvider.selectedCurrency!.code,
      amount: fuelProvider.selectedAmount,
      quantity: fuelProvider.selectedQuantity,
      paymentMethod: PaymentMethod.cash,
      operatorPin: authProvider.currentUser?.id.toString() ?? '0',
      customerId: customerId,
      customerData: customerData,
    );

    if (success && mounted) {
      await _printReceiptCustomer();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paymentProvider.errorMessage ?? 'Payment validation failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: CustomAppBar(
        title: 'Cash Payment',
        backgroundColor: AppColors.primary,
      ),
      body: Consumer3<FuelProvider, PaymentProvider, AuthProvider>(
        builder: (context, fuelProvider, paymentProvider, authProvider, child) {
          return SafeArea(
            top: false,
            child: Column(
              children: [
                _buildCompactSummary(fuelProvider),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      24 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoSection(),
                        const SizedBox(height: 16),
                        _buildActionButtons(paymentProvider),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactSummary(FuelProvider fuelProvider) {
    final currency = fuelProvider.selectedCurrency!;
    final unit = _unitShort(fuelProvider.selectedProduct?.unitOfMeasure);
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
                '${fuelProvider.selectedQuantity.toStringAsFixed(2)} $unit',
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
            child: const Icon(Icons.money, color: Colors.white, size: 20),
          ),
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

  Widget _buildInfoSection() {
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
                  const Icon(Icons.money, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Cash Payment',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Tap confirm to proceed with customer details and complete the transaction.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primaryLight, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Collect cash and tap Confirm to add customer details.',
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
                  'Confirm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
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
        final fiscalData = (r['fiscalisation'] as Map?)?['data'] as Map?;
        final receiptNo = (fiscalData?['receiptID'] ?? '').toString();
        final qrData = ((r['fiscalisation'] as Map?)?['qrData'] ?? '').toString();
        await pos.printReceiptCopy(
          copyType: 'CUSTOMER COPY',
          stationName: (r['stationName'] ?? auth.currentUser?.serviceStationName ?? 'GASMAN').toString(),
          address: (r['address'] ?? '').toString(),
          phone: (r['phone'] ?? '').toString(),
          date: (r['date'] ?? '').toString(),
          time: (r['time'] ?? '').toString(),
          pumpNo: (r['pumpNo'] ?? '1').toString(),
          product: (r['product'] ?? fuel.selectedProduct?.productName ?? 'LPG GAS').toString(),
          unit: unit,
          litres: (r['litres'] ?? fuel.selectedQuantity.toStringAsFixed(2)).toString(),
          pricePerLitre: (r['pricePerLitre'] ?? fuel.selectedProduct?.price.toStringAsFixed(2) ?? '0.00').toString(),
          total: (r['total'] ?? fuel.selectedAmount.toStringAsFixed(2)).toString(),
          payment: (r['payment'] ?? payment.selectedPaymentMethod?.name ?? '').toString(),
          cardNo: (r['cardNo'] ?? '').toString(),
          receiptNo: receiptNo,
          authNo: (r['authNo'] ?? payment.currentTransaction?.referenceNumber ?? '').toString(),
          rrn: (r['rrn'] ?? payment.currentTransaction?.id ?? '').toString(),
          qrData: qrData,
          operatorName: (r['attendant'] ?? auth.currentUser?.fullName ?? '').toString(),
        );
        return;
      }

      final product = fuel.selectedProduct;
      final currency = fuel.selectedCurrency;
      final txn = payment.currentTransaction;
      final stationName = product?.serviceStationName
          ?? auth.currentUser?.serviceStationName
          ?? 'Fuel Station';

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
}



