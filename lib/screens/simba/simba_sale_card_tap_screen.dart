import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/simba_provider.dart';
import '../../services/pos_service.dart';
import '../../models/api_product.dart';
import 'simba_sale_receipt_screen.dart';

class SimbaSaleCardTapScreen extends StatefulWidget {
  final ApiProduct product;
  final int quantity;

  const SimbaSaleCardTapScreen({
    Key? key,
    required this.product,
    required this.quantity,
  }) : super(key: key);

  @override
  State<SimbaSaleCardTapScreen> createState() => _SimbaSaleCardTapScreenState();
}

class _SimbaSaleCardTapScreenState extends State<SimbaSaleCardTapScreen>
    with SingleTickerProviderStateMixin {
  final PosService _posService = PosService();

  bool _isReadingCard = false;
  bool _isProcessingPayment = false;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Auto-start card reading when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readCard();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _readCard() async {
    setState(() {
      _isReadingCard = true;
      _isProcessingPayment = false;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Starting card read for sale...');
      final result = await _posService.readNfc();
      print('DEBUG: Card read result: $result');

      if (result != null) {
        // Extract card number from various possible fields
        final extractedCardNumber = result['pan'] ??
            result['card_number'] ??
            result['uid'] ??
            result['cardNumber'];

        print('DEBUG: Extracted card number: $extractedCardNumber');

        if (extractedCardNumber != null &&
            extractedCardNumber.toString().isNotEmpty) {
          final cardNumber = extractedCardNumber.toString();

          setState(() {
            _isReadingCard = false;
            _isProcessingPayment = true;
          });

          if (!mounted) return;

          print('DEBUG: Processing purchase for card: $cardNumber');

          // Process the purchase
          final provider = context.read<SimbaProvider>();
          final success = await provider.purchaseProduct(
            productId: widget.product.id,
            quantity: widget.quantity,
            cardNumber: cardNumber,
            paymentMethod: 'card',
          );

          print('DEBUG: Purchase success: $success');

          setState(() {
            _isProcessingPayment = false;
          });

          if (success && mounted) {
            // Navigate to receipt screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SimbaSaleReceiptScreen(
                  product: widget.product,
                  quantity: widget.quantity,
                  response: provider.lastProductPurchase!,
                ),
              ),
            );
          } else {
            setState(() {
              _errorMessage = provider.lastProductPurchase?.message ??
                  'Purchase failed. Please try again.';
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_errorMessage!),
                  backgroundColor: BuffaloColors.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to read card number. Please try again.';
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
      print('DEBUG: Exception during card read: $e');
      setState(() {
        _errorMessage = 'Error reading card: $e';
        _isReadingCard = false;
        _isProcessingPayment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.product.priceValue * widget.quantity;

    return Scaffold(
      backgroundColor: BuffaloColors.background,
      appBar: AppBar(
        title: const Text('Tap Card to Pay'),
        backgroundColor: BuffaloColors.primary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Purchase summary card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BuffaloColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Quantity: ${widget.quantity}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: BuffaloColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Total: ${widget.product.currency?.symbol ?? ''} ${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: BuffaloColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Animated card icon
              if (_isReadingCard)
                RotationTransition(
                  turns: _animationController,
                  child: const Icon(
                    Icons.contactless,
                    size: 120,
                    color: BuffaloColors.secondary,
                  ),
                )
              else if (_isProcessingPayment)
                const SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(BuffaloColors.secondary),
                  ),
                )
              else if (_errorMessage != null)
                const Icon(
                  Icons.error_outline,
                  size: 120,
                  color: BuffaloColors.error,
                )
              else
                const Icon(
                  Icons.contactless,
                  size: 120,
                  color: BuffaloColors.secondary,
                ),

              const SizedBox(height: 40),

              // Status text
              Text(
                _isReadingCard
                    ? 'Waiting for card tap...'
                    : _isProcessingPayment
                        ? 'Processing payment...'
                        : _errorMessage != null
                            ? 'Payment Failed'
                            : 'Please tap your card',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BuffaloColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: BuffaloColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (_isProcessingPayment)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Please wait while we process your payment.',
                    style: TextStyle(
                      fontSize: 16,
                      color: BuffaloColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Hold your card near the reader to complete purchase',
                    style: TextStyle(
                      fontSize: 16,
                      color: BuffaloColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 40),

              // Retry button
              if (_errorMessage != null && !_isReadingCard && !_isProcessingPayment)
                ElevatedButton.icon(
                  onPressed: _readCard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BuffaloColors.secondary,
                    foregroundColor: BuffaloColors.textOnSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
