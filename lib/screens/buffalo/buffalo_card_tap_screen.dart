import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/buffalo_provider.dart';
import '../../services/pos_service.dart';
import '../../services/buffalo_api_service.dart';
import 'buffalo_card_info_screen.dart';

class BuffaloCardTapScreen extends StatefulWidget {
  const BuffaloCardTapScreen({Key? key}) : super(key: key);

  @override
  State<BuffaloCardTapScreen> createState() => _BuffaloCardTapScreenState();
}

class _BuffaloCardTapScreenState extends State<BuffaloCardTapScreen>
    with SingleTickerProviderStateMixin {
  final PosService _posService = PosService();

  bool _isReadingCard = false; // Waiting for tap
  bool _isProcessingCard = false; // Card tapped, processing request
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
      _isProcessingCard = false;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Starting card read...');
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
            _isProcessingCard = true;
          });

          if (!mounted) return;

          print('DEBUG: Calling getCardInfo API with card number: $cardNumber');

          // Test connectivity first
          print('DEBUG: Testing API connectivity...');
          final canConnect = await BuffaloApiService.testConnection();
          print('DEBUG: Can connect to API: $canConnect');

          if (!canConnect && mounted) {
            setState(() {
              _errorMessage = 'Cannot reach server. Please check WiFi connection.';
              _isReadingCard = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot reach server. Check WiFi connection.'),
                backgroundColor: BuffaloColors.error,
                duration: Duration(seconds: 4),
              ),
            );
            return;
          }

          // Get card info from API
          final provider = context.read<BuffaloProvider>();
          final success = await provider.getCardInfo(cardNumber);

          print('DEBUG: getCardInfo success: $success');
          print('DEBUG: Card info error: ${provider.cardInfoError}');

          setState(() {
            _isReadingCard = false;
            _isProcessingCard = false;
          });

          if (success && mounted) {
            // Navigate to card info screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const BuffaloCardInfoScreen(),
              ),
            );
          } else {
            setState(() {
              _errorMessage = provider.cardInfoError ?? 'Card not found';
            });

            // Show error in snackbar too
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.cardInfoError ?? 'Card not found'),
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
            _isProcessingCard = false;
          });
          print('DEBUG: Card number extraction failed');
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to read card. Please try again.';
          _isReadingCard = false;
          _isProcessingCard = false;
        });
        print('DEBUG: Card read returned null');
      }
    } catch (e) {
      print('DEBUG: Exception during card read: $e');
      setState(() {
        _errorMessage = 'Error reading card: $e';
        _isReadingCard = false;
        _isProcessingCard = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuffaloColors.background,
      appBar: AppBar(
        title: const Text('Tap Card to Continue'),
        backgroundColor: BuffaloColors.primary,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              else if (_isProcessingCard)
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
                    : _isProcessingCard
                        ? 'Card tapped. Processing...'
                    : _errorMessage != null
                        ? 'Card Read Failed'
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
              else if (_isProcessingCard)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Please wait while we verify card details.',
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
                    'Hold your card near the reader to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: BuffaloColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 40),

              // Retry button
              if (_errorMessage != null && !_isReadingCard && !_isProcessingCard)
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
