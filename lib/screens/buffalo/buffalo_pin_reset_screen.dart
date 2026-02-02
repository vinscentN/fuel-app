import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/buffalo_provider.dart';
import '../../services/pos_service.dart';

class BuffaloPinResetScreen extends StatefulWidget {
  const BuffaloPinResetScreen({Key? key}) : super(key: key);

  @override
  State<BuffaloPinResetScreen> createState() => _BuffaloPinResetScreenState();
}

class _BuffaloPinResetScreenState extends State<BuffaloPinResetScreen> {
  final PosService _posService = PosService();
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isReadingCard = false;
  bool _isResetting = false;
  String? _cardNumber;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _readCard() async {
    setState(() {
      _isReadingCard = true;
      _errorMessage = null;
      _successMessage = null;
      _cardNumber = null;
    });

    try {
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
              content: Text('Card read successfully'),
              backgroundColor: BuffaloColors.success,
              duration: Duration(seconds: 2),
            ),
          );
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

  Future<void> _resetPin() async {
    if (_cardNumber == null || _cardNumber!.isEmpty) {
      setState(() {
        _errorMessage = 'Please tap your card first';
      });
      return;
    }

    if (_oldPinController.text.length != 4) {
      setState(() {
        _errorMessage = 'Please enter your current 4-digit PIN';
      });
      return;
    }

    if (_newPinController.text.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a new 4-digit PIN';
      });
      return;
    }

    if (_newPinController.text != _confirmPinController.text) {
      setState(() {
        _errorMessage = 'New PIN and confirmation do not match';
      });
      return;
    }

    if (_oldPinController.text == _newPinController.text) {
      setState(() {
        _errorMessage = 'New PIN must be different from current PIN';
      });
      return;
    }

    setState(() {
      _isResetting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final provider = context.read<BuffaloProvider>();
      final result = await provider.resetPin(
        cardNumber: _cardNumber!,
        oldPin: _oldPinController.text,
        newPin: _newPinController.text,
      );

      setState(() {
        _isResetting = false;
        if (result['success'] == true) {
          _successMessage = result['message'] ?? 'PIN reset successfully';
          _oldPinController.clear();
          _newPinController.clear();
          _confirmPinController.clear();
          _cardNumber = null;
        } else {
          _errorMessage = result['message'] ?? 'Failed to reset PIN';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error resetting PIN: $e';
        _isResetting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset PIN'),
        backgroundColor: BuffaloColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BuffaloColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: BuffaloColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: BuffaloColors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap your card and enter your current PIN, then choose a new PIN',
                      style: TextStyle(
                        fontSize: 14,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Success Message
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                          color: BuffaloColors.success,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Card Reading Section
            Text(
              'Step 1: Tap Your Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BuffaloColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            if (_cardNumber == null)
              InkWell(
                onTap: _isReadingCard ? null : _readCard,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: BuffaloColors.tertiary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: BuffaloColors.tertiary.withOpacity(0.05),
                  ),
                  child: Column(
                    children: [
                      if (_isReadingCard)
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              BuffaloColors.tertiary),
                        )
                      else
                        Icon(
                          Icons.contactless,
                          size: 80,
                          color: BuffaloColors.tertiary,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _isReadingCard
                            ? 'Reading card...'
                            : 'Tap here to read card',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: BuffaloColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
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
                          _oldPinController.clear();
                          _newPinController.clear();
                          _confirmPinController.clear();
                        });
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: BuffaloColors.tertiary,
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

            const SizedBox(height: 32),

            // PIN Entry Sections
            Text(
              'Step 2: Enter Current PIN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BuffaloColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            PinCodeTextField(
              appContext: context,
              length: 4,
              controller: _oldPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 60,
                fieldWidth: 60,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                selectedFillColor: Colors.white,
                activeColor: BuffaloColors.tertiary,
                inactiveColor: BuffaloColors.cardBorder,
                selectedColor: BuffaloColors.tertiary,
              ),
              cursorColor: BuffaloColors.primary,
              animationDuration: const Duration(milliseconds: 300),
              enableActiveFill: true,
              onCompleted: (v) {},
              onChanged: (value) {},
              beforeTextPaste: (text) => true,
            ),

            const SizedBox(height: 24),

            Text(
              'Step 3: Enter New PIN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BuffaloColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            PinCodeTextField(
              appContext: context,
              length: 4,
              controller: _newPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 60,
                fieldWidth: 60,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                selectedFillColor: Colors.white,
                activeColor: BuffaloColors.secondary,
                inactiveColor: BuffaloColors.cardBorder,
                selectedColor: BuffaloColors.secondary,
              ),
              cursorColor: BuffaloColors.primary,
              animationDuration: const Duration(milliseconds: 300),
              enableActiveFill: true,
              onCompleted: (v) {},
              onChanged: (value) {},
              beforeTextPaste: (text) => true,
            ),

            const SizedBox(height: 24),

            Text(
              'Step 4: Confirm New PIN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BuffaloColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            PinCodeTextField(
              appContext: context,
              length: 4,
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 60,
                fieldWidth: 60,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.white,
                selectedFillColor: Colors.white,
                activeColor: BuffaloColors.secondary,
                inactiveColor: BuffaloColors.cardBorder,
                selectedColor: BuffaloColors.secondary,
              ),
              cursorColor: BuffaloColors.primary,
              animationDuration: const Duration(milliseconds: 300),
              enableActiveFill: true,
              onCompleted: (v) {},
              onChanged: (value) {},
              beforeTextPaste: (text) => true,
            ),

            const SizedBox(height: 32),

            // Reset PIN Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isResetting ? null : _resetPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuffaloColors.tertiary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: BuffaloColors.buttonDisabled,
                ),
                child: _isResetting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Reset PIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
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
