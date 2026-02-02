import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/buffalo_provider.dart';
import '../../services/pos_service.dart';
import 'buffalo_receipt_screen.dart';

class BuffaloCardPaymentScreen extends StatefulWidget {
  const BuffaloCardPaymentScreen({Key? key}) : super(key: key);

  @override
  State<BuffaloCardPaymentScreen> createState() =>
      _BuffaloCardPaymentScreenState();
}

class _BuffaloCardPaymentScreenState extends State<BuffaloCardPaymentScreen> {
  final PosService _posService = PosService();

  bool _isReadingCard = false;
  bool _isProcessing = false;
  String? _cardNumber;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-start card reading when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readCard();
    });
  }

  Future<void> _readCard() async {
    setState(() {
      _isReadingCard = true;
      _errorMessage = null;
      _cardNumber = null;
    });

    try {
      // Try NFC first
      final result = await _posService.readNfc();

      if (result != null) {
        // Extract card number from various possible fields
        final extractedCardNumber = result['pan'] ??
                                    result['card_number'] ??
                                    result['uid'] ??
                                    result['cardNumber'];

        if (extractedCardNumber != null && extractedCardNumber.toString().isNotEmpty) {
          setState(() {
            _cardNumber = extractedCardNumber.toString();
            _isReadingCard = false;
          });

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card read successfully - Processing payment...'),
              backgroundColor: BuffaloColors.success,
              duration: Duration(seconds: 2),
            ),
          );

          // Auto-process payment after card read (no PIN required)
          await _processPayment();
        } else {
          setState(() {
            _errorMessage = 'Failed to read card. Please try again.';
            _isReadingCard = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to read card. Please try again.';
          _isReadingCard = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error reading card: $e';
        _isReadingCard = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_cardNumber == null || _cardNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap your card first'),
          backgroundColor: BuffaloColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<BuffaloProvider>();
      // Use empty PIN since we're not enforcing it
      provider.setCardDetails(_cardNumber!, '');

      // Get serial number
      final serialNumber =
          await _posService.readSerialNumber() ?? 'POS-DEFAULT';

      // Submit sale
      final success = await provider.submitSale(serialNumber);

      if (success) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BuffaloReceiptScreen(),
          ),
        );
      } else {
        setState(() {
          _errorMessage = provider.lastSaleResponse?.error ??
              'Payment failed. Please try again.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing payment: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BuffaloProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: BuffaloColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Payment Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: BuffaloColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.cartItemCount} item(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      provider.cartTotalFormatted,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Card Reading Section
            Text(
              'Tap Your Card to Pay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BuffaloColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            if (_cardNumber == null)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: BuffaloColors.secondary,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: BuffaloColors.secondary.withOpacity(0.05),
                ),
                child: Column(
                  children: [
                    if (_isReadingCard)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            BuffaloColors.secondary),
                      )
                    else
                      Icon(
                        Icons.contactless,
                        size: 80,
                        color: BuffaloColors.secondary,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _isReadingCard
                          ? 'Reading card...'
                          : 'Waiting for card...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hold your card near the device',
                      style: TextStyle(
                        fontSize: 14,
                        color: BuffaloColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!_isReadingCard) ...[
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _readCard,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(
                          foregroundColor: BuffaloColors.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BuffaloColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BuffaloColors.success),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: BuffaloColors.success,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card Read Successfully',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BuffaloColors.success,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _maskCardNumber(_cardNumber!),
                            style: TextStyle(
                              fontSize: 14,
                              color: BuffaloColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _cardNumber = null;
                        });
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: BuffaloColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BuffaloColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BuffaloColors.error),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: BuffaloColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: BuffaloColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isProcessing) ...[
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          BuffaloColors.secondary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Processing payment...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    final last4 = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $last4';
  }
}
