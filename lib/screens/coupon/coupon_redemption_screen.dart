// screens/coupon/coupon_redemption_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/colors.dart';
// Removed local dummy coupon model usage; integrating API validation
import '../../services/coupon_service.dart';
import '../../models/coupon_validation.dart';
import 'coupon_confirmation_screen.dart';
import 'coupon_qr_scanner_screen.dart';
import '../../widgets/common/app_bar_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
// Success flow handled in confirmation screen

class CouponRedemptionScreen extends StatefulWidget {
  const CouponRedemptionScreen({super.key});

  @override
  State<CouponRedemptionScreen> createState() => _CouponRedemptionScreenState();
}

class _CouponRedemptionScreenState extends State<CouponRedemptionScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Use app navy color via AppColors.primary

  bool _isValidating = false;
  bool _isManualEntry = true; // true for manual, false for QR scan
  final _couponService = CouponService();
  CouponInfo? _lastValidCoupon;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    if (_isManualEntry && !_formKey.currentState!.validate()) return;
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _lastValidCoupon = null;
    });

    try {
      final resp = await _couponService.validateCoupon(code);
      setState(() => _isValidating = false);

      if (!resp.success || resp.coupon == null) {
        _showErrorMessage(resp.message.isNotEmpty ? resp.message : 'Coupon validation failed');
        return;
      }

      final c = resp.coupon!;
      if (c.isExpired || !c.isValid) {
        _showErrorMessage('Coupon cannot be used: ${c.isExpired ? 'Expired' : 'Invalid'}');
        return;
      }

      _lastValidCoupon = c;
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CouponConfirmationScreen(coupon: c)),
      );
    } catch (e) {
      setState(() => _isValidating = false);
      _showErrorMessage('Validation error: ${e.toString()}');
    }
  }

  Future<void> _startQRScan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CouponQrScannerScreen()),
    );
    if (code == null || code.isEmpty) return;
    _codeController.text = code;
    await _validateCoupon();
  }

  Future<void> _redeemCoupon() async {
    // Deprecated: handled in CouponConfirmationScreen
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Redeem Coupon',
        backgroundColor: AppColors.primary,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInputMethodToggle(),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: _buildInputSection(),
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        onPressed: _isValidating ? null : _validateCoupon,
                        backgroundColor: AppColors.primary,
                        child: _isValidating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Validate'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Header removed as per new minimalist design

  Widget _buildInputMethodToggle() {
    final isCompact = MediaQuery.of(context).size.height < 650;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isManualEntry = true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
                  decoration: BoxDecoration(
                    color: _isManualEntry ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard,
                        color: _isManualEntry ? Colors.white : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Enter Code',
                        style: TextStyle(
                          color: _isManualEntry ? Colors.white : AppColors.textSecondary,
                          fontWeight: _isManualEntry ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isManualEntry = false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
                  decoration: BoxDecoration(
                    color: !_isManualEntry ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: !_isManualEntry ? Colors.white : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scan QR',
                        style: TextStyle(
                          color: !_isManualEntry ? Colors.white : AppColors.textSecondary,
                          fontWeight: !_isManualEntry ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    final isCompact = MediaQuery.of(context).size.height < 650;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isManualEntry) ...[
              CustomTextField(
                controller: _codeController,
                label: 'Coupon Code',
                hint: 'e.g. 250001-UIZLSF',
                prefixIcon: Icons.confirmation_number,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter coupon code';
                  if (value.length < 5) return 'Coupon code seems too short';
                  if (!value.contains('-')) return 'Coupon code must include a hyphen (-)';
                  return null;
                },
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.black54),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scan a QR code to auto-fill the coupon.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 8 : 12),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: isCompact ? 180 : 220),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isValidating ? 1.0 : _pulseAnimation.value,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: isCompact ? 90 : 110,
                                height: isCompact ? 90 : 110,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary, width: 1),
                                ),
                                child: _isValidating
                                    ? const Center(child: CircularProgressIndicator())
                                    : Icon(Icons.qr_code_scanner, size: isCompact ? 44 : 56),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: isCompact ? 8 : 12),
                      CustomButton(
                        onPressed: _isValidating ? null : _startQRScan,
                        backgroundColor: AppColors.primary,
                        child: _isValidating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Start QR Scan'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCouponDetails() {
    // Deprecated: details are shown on the confirmation screen now
    return const SizedBox.shrink();
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          onPressed: _isValidating ? null : _validateCoupon,
          backgroundColor: AppColors.primary,
          child: _isValidating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Validate'),
        ),
        const SizedBox(height: 12),
        CustomButton(
          onPressed: () => Navigator.of(context).pop(),
          isOutlined: true,
          backgroundColor: AppColors.textSecondary,
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
