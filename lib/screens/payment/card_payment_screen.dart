// screens/payment/card_payment_screen.dart
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
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/success_screen.dart';

// Card payment states
enum CardPaymentState {
  waitingForCard,
  cardDetected,
  enteringPin,
  processing,
  success,
  error,
}

class CardPaymentScreen extends StatefulWidget {
  const CardPaymentScreen({super.key});

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  // Navy blue color scheme
  static const Color navyBlue = Color(0xFF1E3A8A);
  static const Color lightNavyBlue = Color(0xFF3B82F6);

  CardPaymentState _currentState = CardPaymentState.waitingForCard;
  String? _detectedCardNumber;
  String? _errorMessage;

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

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();

    // Simulate card detection after 3 seconds for demo
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentState == CardPaymentState.waitingForCard) {
        _onCardDetected();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _onCardDetected() {
    setState(() {
      _currentState = CardPaymentState.cardDetected;
      _detectedCardNumber = "**** **** **** 1234"; // Simulate detected card
    });

    HapticFeedback.lightImpact();

    // Show card detected for 2 seconds, then request PIN
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentState = CardPaymentState.enteringPin;
        });
      }
    });
  }

  void _onPinDigitPressed(String digit) {
    if (_pinController.text.length < 4) {
      setState(() {
        _pinController.text += digit;
      });

      HapticFeedback.selectionClick();

      if (_pinController.text.length == 4) {
        _processPayment();
      }
    }
  }

  void _onPinBackspace() {
    if (_pinController.text.isNotEmpty) {
      setState(() {
        _pinController.text = _pinController.text.substring(
          0,
          _pinController.text.length - 1,
        );
      });
      HapticFeedback.selectionClick();
    }
  }

  void _onPinClear() {
    setState(() {
      _pinController.clear();
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _processPayment() async {
    setState(() {
      _currentState = CardPaymentState.processing;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final fuelProvider = Provider.of<FuelProvider>(context, listen: false);
    final paymentProvider = Provider.of<PaymentProvider>(
      context,
      listen: false,
    );

    final cardDetails = {
      'cardNumber': _detectedCardNumber?.replaceAll(' ', '') ?? '',
      'pin': _pinController.text,
    };

    final success = await paymentProvider.processPayment(
      userId: authProvider.currentUser!.id,
      productId: fuelProvider.selectedProduct!.id,
      currencyCode: fuelProvider.selectedCurrency!.code,
      amount: fuelProvider.selectedAmount,
      quantity: fuelProvider.selectedQuantity,
      paymentMethod: PaymentMethod.card,
      cardDetails: cardDetails,
    );

    if (success && mounted) {
      setState(() {
        _currentState = CardPaymentState.success;
      });

      // Navigate to success screen after showing success state
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (_) => const SuccessScreen(
                    title: 'Payment Successful!',
                    message:
                        'Your fuel card payment has been processed successfully.',
                  ),
            ),
          );
        }
      });
    } else if (mounted) {
      setState(() {
        _currentState = CardPaymentState.error;
        _errorMessage = paymentProvider.errorMessage ?? 'Payment failed';
        _pinController.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Fuel Card Payment',
        backgroundColor: navyBlue,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, child) {
          return Column(
            children: [
              _buildTransactionSummary(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildCurrentStateWidget(),
                ),
              ),
              _buildBottomActions(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionSummary() {
    return Consumer<FuelProvider>(
      builder: (context, fuelProvider, child) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.credit_card, color: Colors.white, size: 24),
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
                    color: navyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: navyBlue, width: 2),
                  ),
                  child: Icon(Icons.credit_card, size: 48, color: navyBlue),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Insert or Tap Your Fuel Card',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Please insert your fuel card into the reader or tap it on the contactless area',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: const Icon(Icons.check_circle, size: 48, color: Colors.green),
        ),
        const SizedBox(height: 32),
        Text(
          'Card Detected!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Card: $_detectedCardNumber',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPinEntry() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Enter Your PIN',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),

        // PIN display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      index < _pinController.text.length
                          ? navyBlue
                          : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color:
                    index < _pinController.text.length
                        ? navyBlue.withOpacity(0.1)
                        : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  index < _pinController.text.length ? '•' : '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        // PIN keypad
        _buildPinKeypad(),
      ],
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
              children:
                  [
                    '1',
                    '2',
                    '3',
                  ].map((digit) => _buildKeypadButton(digit)).toList(),
            ),
            const SizedBox(height: 16),
            // Numbers 4-6
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  [
                    '4',
                    '5',
                    '6',
                  ].map((digit) => _buildKeypadButton(digit)).toList(),
            ),
            const SizedBox(height: 16),
            // Numbers 7-9
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  [
                    '7',
                    '8',
                    '9',
                  ].map((digit) => _buildKeypadButton(digit)).toList(),
            ),
            const SizedBox(height: 16),
            // Clear, 0, Backspace
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKeypadButton('Clear', onTap: _onPinClear),
                _buildKeypadButton('0'),
                _buildKeypadButton('⌫', onTap: _onPinBackspace),
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
          color: navyBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: navyBlue.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: text == 'Clear' ? 12 : 18,
              fontWeight: FontWeight.bold,
              color: navyBlue,
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
        LoadingWidget(size: 64, color: navyBlue),
        const SizedBox(height: 32),
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
          child: const Icon(Icons.check_circle, size: 64, color: Colors.green),
        ),
        const SizedBox(height: 32),
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
          child: const Icon(Icons.error, size: 64, color: Colors.red),
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
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
      child: CustomButton(
        onPressed:
            _currentState == CardPaymentState.processing
                ? null
                : () => Navigator.of(context).pop(),
        isOutlined: true,
        backgroundColor: AppColors.textSecondary,
        child: const Text(
          'Cancel',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
