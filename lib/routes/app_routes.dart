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
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isValidating = false;
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
      applicableProductId: '2', // Diesel product ID
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon() async {
    if (!_formKey.currentState!.validate()) return;

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

  Future<void> _redeemCoupon() async {
    if (_validatedCoupon == null) return;

    setState(() {
      _isValidating = true;
    });

    // Simulate redemption process
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            title: 'Coupon Redeemed!',
            message: 'Your coupon "${_validatedCoupon!.title}" has been successfully applied.',
            actionText: 'Continue Shopping',
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
      appBar: const CustomAppBar(title: 'Redeem Coupon'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildCouponForm(),
                if (_validatedCoupon != null) ...[
                  const SizedBox(height: 24),
                  _buildCouponDetails(),
                ],
                const SizedBox(height: 32),
                _buildSampleCoupons(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard,
                color: AppColors.secondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Redeem Your Coupon',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your coupon code to get instant discounts on fuel purchases',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Coupon Code',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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
              backgroundColor: AppColors.secondary,
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
                ),
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
              AppColors.success.withOpacity(0.1),
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
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Valid Coupon Found!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
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

  Widget _buildSampleCoupons() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Demo Coupon Codes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._dummyCoupons.map((coupon) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        coupon.code,
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        coupon.title,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _codeController.text = coupon.code;
                      },
                      icon: Icon(
                        Icons.copy,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_validatedCoupon != null)
          CustomButton(
            onPressed: _isValidating ? null : _redeemCoupon,
            backgroundColor: AppColors.success,
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
              ),
            ),
          ),
        if (_validatedCoupon != null) const SizedBox(height: 12),
        CustomButton(
          onPressed: () => Navigator.of(context).pop(),
          isOutlined: true,
          backgroundColor: AppColors.textSecondary,
          child: const Text(
            'Back to Dashboard',
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

