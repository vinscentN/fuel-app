// screens/coupon/coupon_redemption_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/colors.dart';
import '../../models/coupon.dart';
import '../../widgets/common/app_bar_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/success_screen.dart';

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

  // Navy blue color scheme
  static const Color navyBlue = Color(0xFF1E3A8A);
  static const Color lightNavyBlue = Color(0xFF3B82F6);

  bool _isValidating = false;
  bool _isManualEntry = true; // true for manual, false for QR scan
  Coupon? _validatedCoupon;

  // Dummy coupon data
  final List<Coupon> _dummyCoupons = [
    Coupon(
      id: '1',
      code: 'FUEL20',
      title: '20% Off Premium Fuel',
      description: 'Get 20% discount on premium petrol purchases',
      type: CouponType.percentage,
      value: 20.0,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      status: CouponStatus.active,
      minimumAmount: 10.0,
      maximumDiscount: 50.0,
    ),
    Coupon(
      id: '2',
      code: 'SAVE50',
      title: '\$50 Off Your Purchase',
      description: 'Get \$50 off on any fuel purchase above \$100',
      type: CouponType.fixed,
      value: 50.0,
      expiryDate: DateTime.now().add(const Duration(days: 15)),
      status: CouponStatus.active,
      minimumAmount: 100.0,
    ),
    Coupon(
      id: '3',
      code: 'DIESEL10',
      title: '10% Off Diesel',
      description: 'Special discount on diesel fuel',
      type: CouponType.fuelDiscount,
      value: 10.0,
      expiryDate: DateTime.now().add(const Duration(days: 45)),
      status: CouponStatus.active,
      applicableProductId: '2',
    ),
  ];

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

    setState(() {
      _isValidating = true;
      _validatedCoupon = null;
    });

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));

    final code = _codeController.text.trim().toUpperCase();
    final coupon = _dummyCoupons.firstWhere(
          (c) => c.code == code && c.status == CouponStatus.active,
      orElse: () => Coupon(
        id: '',
        code: '',
        title: '',
        description: '',
        type: CouponType.percentage,
        value: 0,
        expiryDate: DateTime.now(),
        status: CouponStatus.invalid,
      ),
    );

    setState(() {
      _isValidating = false;
      if (coupon.status != CouponStatus.invalid) {
        _validatedCoupon = coupon;
      }
    });

    if (coupon.status == CouponStatus.invalid) {
      _showErrorMessage('Invalid or expired coupon code');
    }
  }

  Future<void> _startQRScan() async {
    setState(() {
      _isValidating = true;
    });

    // Simulate QR scan process
    await Future.delayed(const Duration(seconds: 3));

    // Simulate successful QR scan with first dummy coupon
    _codeController.text = _dummyCoupons.first.code;

    setState(() {
      _isValidating = false;
      _validatedCoupon = _dummyCoupons.first;
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _redeemCoupon() async {
    if (_validatedCoupon == null) return;

    setState(() {
      _isValidating = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            title: 'Coupon Redeemed!',
            message: 'Coupon has been successfully redeemed.',
            actionText: 'Back to Dashboard',
            onAction: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    }
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
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Redeem Coupon',
        backgroundColor: navyBlue,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Compact header
            _buildCompactHeader(),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInputMethodToggle(),
                      const SizedBox(height: 24),
                      _buildInputSection(),
                      if (_validatedCoupon != null) ...[
                        const SizedBox(height: 24),
                        _buildCouponDetails(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Fixed buttons at bottom
            Container(
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
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Redeem Coupon',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Enter code or scan QR to get discounts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputMethodToggle() {
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _isManualEntry ? navyBlue : Colors.transparent,
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_isManualEntry ? navyBlue : Colors.transparent,
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isManualEntry ? 'Enter Coupon Code' : 'Scan QR Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            if (_isManualEntry) ...[
              CustomTextField(
                controller: _codeController,
                label: 'Coupon Code',
                hint: 'Enter your coupon code',
                prefixIcon: Icons.confirmation_number,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter coupon code';
                  }
                  if (value.length < 3) {
                    return 'Coupon code must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomButton(
                onPressed: _isValidating ? null : _validateCoupon,
                backgroundColor: navyBlue,
                child: _isValidating
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Validate Coupon',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              // QR Scanner Section
              Center(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isValidating ? 1.0 : _pulseAnimation.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: navyBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: navyBlue,
                                width: 2,
                              ),
                            ),
                            child: _isValidating
                                ? const Center(
                              child: CircularProgressIndicator(),
                            )
                                : Icon(
                              Icons.qr_code_scanner,
                              size: 80,
                              color: navyBlue,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isValidating ? 'Scanning QR Code...' : 'Tap to scan QR code',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      onPressed: _isValidating ? null : _startQRScan,
                      backgroundColor: navyBlue,
                      child: _isValidating
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Start QR Scanner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightNavyBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: lightNavyBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: lightNavyBlue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo codes: FUEL20, SAVE50, DIESEL10',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: lightNavyBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponDetails() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Valid Coupon Found!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _validatedCoupon!.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _validatedCoupon!.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Discount:', _getDiscountText()),
                  if (_validatedCoupon!.minimumAmount != null)
                    _buildDetailRow('Minimum Amount:', '\$${_validatedCoupon!.minimumAmount!.toStringAsFixed(2)}'),
                  if (_validatedCoupon!.maximumDiscount != null)
                    _buildDetailRow('Maximum Discount:', '\$${_validatedCoupon!.maximumDiscount!.toStringAsFixed(2)}'),
                  _buildDetailRow('Expires:', _formatDate(_validatedCoupon!.expiryDate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getDiscountText() {
    switch (_validatedCoupon!.type) {
      case CouponType.percentage:
        return '${_validatedCoupon!.value.toStringAsFixed(0)}% OFF';
      case CouponType.fixed:
        return '\$${_validatedCoupon!.value.toStringAsFixed(2)} OFF';
      case CouponType.fuelDiscount:
        return '${_validatedCoupon!.value.toStringAsFixed(0)}% OFF Fuel';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_validatedCoupon != null)
          CustomButton(
            onPressed: _isValidating ? null : _redeemCoupon,
            backgroundColor: Colors.green,
            child: _isValidating
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Redeem Coupon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        if (_validatedCoupon != null) const SizedBox(height: 12),
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