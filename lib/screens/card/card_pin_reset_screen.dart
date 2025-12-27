import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../providers/pos_provider.dart';
import '../../services/card_service.dart';
import '../../utils/colors.dart';
import '../home/landing_menu_screen.dart';
import 'package:gasman/aisino_pos_sdk.dart';

enum PinResetState {
  waitingForCard,
  cardDetected,
  enteringPin,
  processing,
  success,
  error
}

class CardPinResetScreen extends StatefulWidget {
  const CardPinResetScreen({super.key});

  @override
  State<CardPinResetScreen> createState() => _CardPinResetScreenState();
}

class _CardPinResetScreenState extends State<CardPinResetScreen> with TickerProviderStateMixin {
  final TextEditingController _newPin = TextEditingController();
  final TextEditingController _confirmPin = TextEditingController();
  bool _submitting = false;

  PinResetState _currentState = PinResetState.waitingForCard;
  String? _cardPan;
  String? _errorMessage;

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

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

    _beginNfcRead();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _newPin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  Future<void> _beginNfcRead() async {
    try {
      final result = await AisinoPosSdk.startNfcTransaction();

      if (!mounted) return;

      if (result != null && result is Map) {
        // Beep on successful card detection
        try {
          await AisinoPosSdk.beep();
        } catch (e) {
          print('Beep failed: $e');
        }

        final pan = result['pan']?.toString() ?? result['uid_raw']?.toString() ?? '';

        if (pan.isNotEmpty) {
          setState(() {
            _cardPan = pan;
            _currentState = PinResetState.enteringPin;
          });
        } else {
          setState(() {
            _errorMessage = 'Card read but no PAN found';
            _currentState = PinResetState.error;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No card detected';
          _currentState = PinResetState.error;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Card reading failed: $e';
        _currentState = PinResetState.error;
      });
    }
  }

  bool get _pinsValid =>
      _newPin.text.length == 4 && _newPin.text == _confirmPin.text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Card PIN Reset'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case PinResetState.waitingForCard:
        return _buildWaitingForCard();
      case PinResetState.cardDetected:
      case PinResetState.enteringPin:
        return _buildPinEntry();
      case PinResetState.processing:
        return _buildProcessing();
      case PinResetState.success:
        return _buildSuccess();
      case PinResetState.error:
        return _buildError();
    }
  }

  Widget _buildWaitingForCard() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 200,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: const Icon(
                  Icons.credit_card,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tap your card',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Place card near reader',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      const Text('Card Detected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Card PAN', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SelectableText(
                    _maskPan(_cardPan ?? ''),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Set New PIN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 16),
                  const Text('Enter New PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    controller: _newPin,
                    obscureText: true,
                    obscuringCharacter: '•',
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 56,
                      fieldWidth: 56,
                      activeFillColor: AppColors.primary.withOpacity(0.08),
                      inactiveFillColor: AppColors.surfaceVariant,
                      selectedFillColor: AppColors.primary.withOpacity(0.12),
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                      selectedColor: AppColors.primary,
                    ),
                    enableActiveFill: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  const Text('Confirm New PIN', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    controller: _confirmPin,
                    obscureText: true,
                    obscuringCharacter: '•',
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 56,
                      fieldWidth: 56,
                      activeFillColor: AppColors.primary.withOpacity(0.08),
                      inactiveFillColor: AppColors.surfaceVariant,
                      selectedFillColor: AppColors.primary.withOpacity(0.12),
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                      selectedColor: AppColors.primary,
                    ),
                    enableActiveFill: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_newPin.text.isNotEmpty && _confirmPin.text.isNotEmpty && !_pinsValid) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'PINs do not match',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting || !_pinsValid ? null : _resetPin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Reset PIN',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessing() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 4,
            color: AppColors.primary,
          ),
          SizedBox(height: 24),
          Text(
            'Resetting PIN...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 32),
            const Text(
              'PIN Reset Successful',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Card: ${_maskPan(_cardPan ?? '')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LandingMenuScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPin() async {
    if (!_pinsValid || _cardPan == null) return;

    setState(() {
      _submitting = true;
      _currentState = PinResetState.processing;
    });

    try {
      final resp = await CardService().setPin(
        cardPan: _cardPan!,
        pin: _newPin.text,
        pinConfirmation: _confirmPin.text,
      );

      if (!mounted) return;

      setState(() {
        _currentState = PinResetState.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to reset PIN: $e';
        _currentState = PinResetState.error;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _maskPan(String pan) {
    if (pan.isEmpty) return '';
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
}
