import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../providers/pos_provider.dart';
import '../../services/card_service.dart';
import '../../utils/colors.dart';
import '../home/landing_menu_screen.dart';

class CardPinResetScreen extends StatefulWidget {
  const CardPinResetScreen({super.key});

  @override
  State<CardPinResetScreen> createState() => _CardPinResetScreenState();
}

class _CardPinResetScreenState extends State<CardPinResetScreen> {
  final TextEditingController _newPin = TextEditingController();
  final TextEditingController _confirmPin = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Begin NFC read immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pos = Provider.of<PosProvider>(context, listen: false);
      // Ensure we don't reuse PAN from a previous flow
      pos.clearCardData();
      pos.readNfcCard();
    });
  }

  @override
  void dispose() {
    _newPin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  String? _panFrom(Map? data) {
    if (data == null) return null;
    final pan = data['pan']?.toString();
    if (pan != null && pan.isNotEmpty) return pan;
    final uid = data['uid_raw']?.toString();
    return (uid != null && uid.isNotEmpty) ? uid : null;
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
      body: Consumer<PosProvider>(
        builder: (context, pos, child) {
          final pan = _panFrom(pos.lastResult);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                _WaitingForCardWidget(isLoading: pos.isLoading, hasPan: _panFrom(pos.lastResult) != null),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Card Number (PAN/UID)', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          SelectableText(pan ?? 'No card read yet',
                              style: TextStyle(color: pan != null ? AppColors.textPrimary : AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          const Text('Enter New PIN', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          PinCodeTextField(
                            appContext: context,
                            length: 4,
                            controller: _newPin,
                            obscureText: true,
                            obscuringCharacter: '•',
                            keyboardType: TextInputType.number,
                            animationType: AnimationType.fade,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(10),
                              fieldHeight: 52,
                              fieldWidth: 52,
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
                          const SizedBox(height: 10),
                          const Text('Confirm New PIN', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          PinCodeTextField(
                            appContext: context,
                            length: 4,
                            controller: _confirmPin,
                            obscureText: true,
                            obscuringCharacter: '•',
                            keyboardType: TextInputType.number,
                            animationType: AnimationType.fade,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(10),
                              fieldHeight: 52,
                              fieldWidth: 52,
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
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: !_submitting && pan != null && _pinsValid
                                  ? () => _resetPin(pan)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: _submitting
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                  : const Text('Reset PIN'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _resetPin(String pan) async {
    if (!_pinsValid) return;
    setState(() => _submitting = true);
    try {
      final resp = await CardService().setPin(
        cardPan: pan,
        pin: _newPin.text,
        pinConfirmation: _confirmPin.text,
      );
      final msg = resp['message']?.toString() ?? 'PIN set successfully.';
      final data = resp['data'] as Map<String, dynamic>?;
      final maskedPan = data?['pan']?.toString();

      if (!mounted) return;
      await _showSuccessDialog(message: msg, cardMasked: maskedPan);
      if (!mounted) return;
      // Clear any cached card data after successful PIN reset
      Provider.of<PosProvider>(context, listen: false).clearCardData();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingMenuScreen()),
        (route) => false,
      );
      if (mounted) {
        _newPin.clear();
        _confirmPin.clear();
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set PIN: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Waiting UI similar to card sale screen
  Widget _WaitingForCardWidget({required bool isLoading, required bool hasPan}) {
    if (hasPan) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(Icons.credit_card, size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          isLoading ? 'Waiting for card...' : 'Please tap or insert card',
          style: const TextStyle(color: AppColors.textSecondary),
        )
      ],
    );
  }

  Future<void> _showSuccessDialog({required String message, String? cardMasked}) async {
    // Auto-close dialog after a short delay, but allow manual close too
    final future = showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'PIN Reset Successful',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (cardMasked != null && cardMasked.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Card: $cardMasked', style: const TextStyle(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Schedule auto-dismiss
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
    return future;
  }
}
