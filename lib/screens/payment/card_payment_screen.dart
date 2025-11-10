// screens/payment/card_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:fuels_app/aisino_pos_sdk.dart';
import '../../providers/fuel_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../models/transaction.dart';
import '../../widgets/common/app_bar_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/success_screen.dart';
import '../common/success_screen.dart';
import '../common/operator_code_screen.dart';

// Card payment states
enum CardPaymentState {
  waitingForCard,
  cardDetected,
  enteringPin,
  processing,
  success,
  error
}


class CardPaymentScreen extends StatefulWidget {
  const CardPaymentScreen({super.key});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _pin = '';

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  // Use app navy color via AppColors.primary

  CardPaymentState _currentState = CardPaymentState.waitingForCard;
  // Card number display handling
  String? _cardPanRaw;    // full PAN (or UID fallback)
  String? _cardPanMasked; // masked for display/receipts
  String? _errorMessage;
  Map<String, dynamic>? _rawNfcData;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();

    // Start real NFC listening using platform channel
    _beginNfcRead();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    // no controller to dispose
    super.dispose();
  }

  Future<void> _beginNfcRead() async {
    setState(() {
      _currentState = CardPaymentState.waitingForCard;
      _errorMessage = null;
      _rawNfcData = null;
      _cardPanRaw = null;
      _cardPanMasked = null;
    });

    try {
      final available = await AisinoPosSdk.checkNfcAvailability();
      if (available != true) {
        setState(() {
          _currentState = CardPaymentState.error;
          _errorMessage = 'NFC not available or SDK not initialized';
        });
        return;
      }

      final data = await AisinoPosSdk.startNfcTransaction();
      if (!mounted) return;

      if (data != null) {
        _rawNfcData = Map<String, dynamic>.from(data);
        final pan = (_rawNfcData!["pan"] ?? '').toString();
        final uid = (_rawNfcData!["uid_raw"] ?? '').toString();
        if (pan.isNotEmpty) {
          debugPrint('Card PAN read: $pan');
        } else {
          debugPrint('NFC UID read: $uid');
        }

        // Prefer PAN (fallback to UID). Keep both raw and masked variants
        final chosen = pan.isNotEmpty ? pan : uid;
        final displayPan = _maskPan(chosen);

        setState(() {
          _cardPanRaw = chosen;
          _cardPanMasked = displayPan;
          _currentState = CardPaymentState.cardDetected;
        });

        HapticFeedback.lightImpact();

        // Proceed to PIN after short acknowledgement
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() {
          _currentState = CardPaymentState.enteringPin;
        });
      } else {
        setState(() {
          _currentState = CardPaymentState.error;
          _errorMessage = 'Failed to read NFC card';
        });
        // Auto-retry back to waiting
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _beginNfcRead();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentState = CardPaymentState.error;
        _errorMessage = 'NFC error: ${e.toString()}';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _beginNfcRead();
      });
    }
  }

  String _maskPan(String pan) {
    if (pan.isEmpty) return '';
    // Keep last 4, mask others; group in 4s for readability
    final clean = pan.replaceAll(' ', '');
    if (clean.length <= 4) return clean;
    final masked = '*' * (clean.length - 4) + clean.substring(clean.length - 4);
    final buf = StringBuffer();
    for (int i = 0; i < masked.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(masked[i]);
    }
    return buf.toString();
  }

  void _onPinDigitPressed(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
      });
      HapticFeedback.selectionClick();
      if (_pin.length == 4) {
        _processPayment();
      }
    }
  }

  void _onPinBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
      HapticFeedback.selectionClick();
    }
  }

  void _onPinClear() {
    setState(() {
      _pin = '';
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _processPayment() async {
    setState(() {
      _currentState = CardPaymentState.processing;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

    // Guard: ensure required sale context is available
    if (/* authProvider.currentUser == null || */
        fuelProvider.selectedProduct == null ||
        fuelProvider.selectedCurrency == null) {
      setState(() {
        _currentState = CardPaymentState.enteringPin;
        _errorMessage = 'Missing sale details. Please restart the sale.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing sale details. Please restart the sale.')),
      );
      return;
    }

    // Prefer PAN to send to backend; fall back to UID only if PAN missing
    final cardDetails = {
      'cardNumber': (_rawNfcData?['pan'] ?? _rawNfcData?['uid_raw'] ?? '').toString(),
      'pin': _pin,
      'nfc': _rawNfcData,
    };

    // Ask for operator code as last step before submission
    final operatorCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const OperatorCodeScreen(
          title: 'Operator Code',
          subtitle: 'Enter your operator code to confirm this card transaction',
        ),
      ),
    );
    if (operatorCode == null || operatorCode.isEmpty) {
      setState(() {
        _currentState = CardPaymentState.enteringPin;
      });
      return;
    }

    final success = await paymentProvider.processPayment(
      userId: authProvider.currentUser?.id ?? '0',
      productId: fuelProvider.selectedProduct!.id,
      currencyCode: fuelProvider.selectedCurrency!.code,
      amount: fuelProvider.selectedAmount,
      quantity: fuelProvider.selectedQuantity,
      paymentMethod: PaymentMethod.card,
      cardDetails: cardDetails,
      operatorPin: operatorCode,
    );

    if (success && mounted) {
      // Fire receipt printing using native printer (non-blocking)
      _printReceiptSafely();

      // Navigate directly to the final success screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SuccessScreen(
            title: 'Payment Successful!',
            message: 'Your fuel card payment has been processed successfully.',
          ),
        ),
      );
    } else if (mounted) {
      setState(() {
        _currentState = CardPaymentState.error;
        _errorMessage = paymentProvider.errorMessage ?? 'Payment failed';
        _pin = '';
      });

      // Return to PIN entry after showing error
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _currentState = CardPaymentState.enteringPin;
            _errorMessage = null;
          });
        }
      });
    }
  }

  Future<void> _printReceiptSafely() async {
    try {
      final posProvider = Provider.of<PosProvider>(context, listen: false);
      final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

      // Prefer receipt data from API if available
      final r = paymentProvider.receiptData;
      if (r != null && r.isNotEmpty) {
        final unit = _unitShort(fuelProvider.selectedProduct?.unitOfMeasure);
        final operatorName = (r['attendant'] ?? authProvider.currentUser?.fullName ?? '').toString();
        await posProvider.printReceiptCopy(copyType: 'CUSTOMER COPY', 
          stationName: (r['stationName'] ?? '').toString(),
          address: (r['address'] ?? '').toString(),
          phone: (r['phone'] ?? '').toString(),
          date: (r['date'] ?? '').toString(),
          time: (r['time'] ?? '').toString(),
          pumpNo: (r['pumpNo'] ?? '').toString(),
          product: (r['product'] ?? '').toString(),
          unit: unit,
          litres: (r['litres'] ?? '').toString(),
          pricePerLitre: (r['pricePerLitre'] ?? '').toString(),
          total: (r['total'] ?? '').toString(),
          payment: (r['payment'] ?? '').toString(),
          cardNo: (r['cardNo'] ?? _cardPanMasked ?? '').toString(),
          authNo: (r['authNo'] ?? '').toString(),
          rrn: (r['rrn'] ?? '').toString(),
          operatorName: operatorName,
        );
        return;
      }

      // Fallback to locally-computed receipt
      final product = fuelProvider.selectedProduct;
      final currency = fuelProvider.selectedCurrency;
      final txn = paymentProvider.currentTransaction;

      final stationName = product?.serviceStationName
          ?? authProvider.currentUser?.serviceStationName
          ?? 'Fuel Station';
      final address = '';
      final phone = '';

      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final date = '${now.year}-${two(now.month)}-${two(now.day)}';
      final time = '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';

      final pumpNo = '1';
      final productName = product?.productName ?? 'Fuel';
      final litres = fuelProvider.selectedQuantity.toStringAsFixed(2);
      final pricePerLitre = product?.price.toStringAsFixed(2) ?? '0.00';
      final total = currency != null
          ? '${currency.symbol}${fuelProvider.selectedAmount.toStringAsFixed(2)}'
          : fuelProvider.selectedAmount.toStringAsFixed(2);
      final payment = 'card';
      final cardNo = _cardPanMasked ?? '';
      final authNo = txn?.referenceNumber ?? txn?.id ?? '';
      final rrn = txn?.id ?? txn?.referenceNumber ?? '';

      final unit = _unitShort(product?.unitOfMeasure);
      await posProvider.printReceiptCopy(copyType: 'CUSTOMER COPY', 
        stationName: stationName,
        address: address,
        phone: phone,
        date: date,
        time: time,
        pumpNo: pumpNo,
        product: productName,
        unit: unit,
        litres: litres,
        pricePerLitre: pricePerLitre,
        total: total,
        payment: payment,
        cardNo: cardNo,
        authNo: authNo,
        rrn: rrn,
        operatorName: authProvider.currentUser?.fullName ?? '',
      );
    } catch (e) {
      debugPrint('Receipt print failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: CustomAppBar(
      title: 'Fuel Card Payment',
      backgroundColor: AppColors.primary,
    ),
    body: SafeArea(
      child: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          return Column(
            children: [
              _buildTransactionSummary(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildCurrentStateWidget(),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}Widget _buildTransactionSummary() {
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
                    'Amount to Pay',
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
                    '${fuelProvider.selectedQuantity.toStringAsFixed(2)} ${_unitShort(fuelProvider.selectedProduct?.unitOfMeasure)}',
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
                  Icons.credit_card,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentStateWidget() {
    switch (_currentState) {
      case CardPaymentState.waitingForCard:
        return _buildWaitingForCard();
      case CardPaymentState.cardDetected:
        return _buildCardDetected();
      case CardPaymentState.enteringPin:
        return _buildPinEntry();
      case CardPaymentState.processing:
        return _buildProcessing();
      case CardPaymentState.success:
        return _buildSuccess();
      case CardPaymentState.error:
        return _buildError();
    }
  }

  Widget _buildWaitingForCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.credit_card,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Insert or Tap Your Fuel Card',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please insert your fuel card into the reader or tap it on the contactless area',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetected() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 48,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Card Detected!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Card: ${_cardPanMasked ?? ''}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPinEntry() {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottom > 0 ? bottom : 0),
      child: Column(
        children: [
          Text(
            'Enter Your PIN',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if ((_cardPanRaw ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Card: ${_cardPanRaw!}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          PinCodeTextField(
            appContext: context,
            length: 4,
            obscureText: true,
            obscuringCharacter: '*',
            keyboardType: TextInputType.number,
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(12),
              fieldHeight: bottom > 0 ? 50 : 60,
              fieldWidth: bottom > 0 ? 50 : 60,
              activeFillColor: AppColors.primary.withOpacity(0.1),
              inactiveFillColor: AppColors.surfaceVariant,
              selectedFillColor: AppColors.primary.withOpacity(0.2),
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
              selectedColor: AppColors.primary,
            ),
            enableActiveFill: true,
            onCompleted: (v) { setState(() { _pin = v; }); _processPayment(); },
            onChanged: (v) => setState(() { _pin = v; }),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _pin.length == 4 ? _processPayment : null,
            child: const Text('Confirm PIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildPinKeypad() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Numbers 1-3
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['1', '2', '3'].map((digit) => _buildKeypadButton(digit)).toList(),
            ),
            const SizedBox(height: 16),
            // Numbers 4-6
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['4', '5', '6'].map((digit) => _buildKeypadButton(digit)).toList(),
            ),
            const SizedBox(height: 16),
            // Numbers 7-9
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['7', '8', '9'].map((digit) => _buildKeypadButton(digit)).toList(),
            ),
            const SizedBox(height: 16),
            // Clear, 0, Backspace
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKeypadButton('Clear', onTap: _onPinClear),
                _buildKeypadButton('0'),
                _buildKeypadButton('DEL', onTap: _onPinBackspace),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => _onPinDigitPressed(text),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: text == 'Clear' ? 12 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingWidget(size: 48, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          'Processing Payment...',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Please wait while we process your fuel card payment',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Payment Successful!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            size: 64,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Payment Failed',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Please try again',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Cancel button removed as requested

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





