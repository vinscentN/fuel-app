import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _currentCodeController = TextEditingController();
  final _newCodeController = TextEditingController();
  final _confirmCodeController = TextEditingController();
  final _currentCodeFocus = FocusNode();
  final _newCodeFocus = FocusNode();
  final _confirmCodeFocus = FocusNode();

  bool _isLoading = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _currentCodeController.dispose();
    _newCodeController.dispose();
    _confirmCodeController.dispose();
    _currentCodeFocus.dispose();
    _newCodeFocus.dispose();
    _confirmCodeFocus.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resetPassword(
        username: _usernameController.text.trim(),
        oldPassword: _currentCodeController.text.trim(),
        newPassword: _newCodeController.text.trim(),
        confirmPassword: _confirmCodeController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);
      if (success) {
        _showSuccessDialog();
        return;
      }

      final errorMessage =
          authProvider.errorMessage ?? 'Password reset failed. Please try again.';
      _showErrorSnackBar(errorMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Password reset failed. Please try again.');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Success',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
        content: const Text(
          'Operator code changed successfully. You can now login with your new code.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'AUTHORIZATION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _navyMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE8EDF5),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Reset 4-digit operator code',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _navy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Use the same compact PIN format as operator verification.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _navyMuted,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildUsernameField(),
                                const SizedBox(height: 12),
                                _buildPinField(
                                  label: 'CURRENT OPERATOR CODE',
                                  controller: _currentCodeController,
                                  focusNode: _currentCodeFocus,
                                  autoFocus: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your current operator code';
                                    }
                                    if (value.trim().length != AppConstants.pinLength) {
                                      return 'Operator code must be exactly 4 digits';
                                    }
                                    return null;
                                  },
                                  onCompleted: (_) =>
                                      FocusScope.of(context).requestFocus(_newCodeFocus),
                                ),
                                const SizedBox(height: 12),
                                _buildPinField(
                                  label: 'NEW OPERATOR CODE',
                                  controller: _newCodeController,
                                  focusNode: _newCodeFocus,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter new operator code';
                                    }
                                    if (value.trim().length != AppConstants.pinLength) {
                                      return 'Operator code must be exactly 4 digits';
                                    }
                                    if (value.trim() == _currentCodeController.text.trim()) {
                                      return 'New operator code must be different';
                                    }
                                    return null;
                                  },
                                  onCompleted: (_) => FocusScope.of(context)
                                      .requestFocus(_confirmCodeFocus),
                                ),
                                const SizedBox(height: 12),
                                _buildPinField(
                                  label: 'CONFIRM NEW OPERATOR CODE',
                                  controller: _confirmCodeController,
                                  focusNode: _confirmCodeFocus,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please confirm your operator code';
                                    }
                                    if (value.trim().length != AppConstants.pinLength) {
                                      return 'Operator code must be exactly 4 digits';
                                    }
                                    if (value.trim() != _newCodeController.text.trim()) {
                                      return 'Operator codes do not match';
                                    }
                                    return null;
                                  },
                                  onCompleted: (_) => _handlePasswordReset(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handlePasswordReset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Reset Operator Code',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Container(
        decoration: const BoxDecoration(
          color: _navy,
          border: Border(
            bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  splashRadius: 20,
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Operator Code',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Secure verification',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'USERNAME',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _navyMuted,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Enter your username',
            isDense: true,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: _navyMuted,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFD),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _navy, width: 1.5),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your username';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPinField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? Function(String?) validator,
    required ValueChanged<String> onCompleted,
    bool autoFocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _navyMuted,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        PinCodeTextField(
          appContext: context,
          controller: controller,
          focusNode: focusNode,
          autoFocus: autoFocus,
          autoDisposeControllers: false,
          length: AppConstants.pinLength,
          obscureText: true,
          obscuringCharacter: '•',
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          enableActiveFill: true,
          autoDismissKeyboard: false,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: validator,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(10),
            fieldHeight: 48,
            fieldWidth: 48,
            activeFillColor: _navy.withOpacity(0.08),
            inactiveFillColor: const Color(0xFFF8FAFD),
            selectedFillColor: _navy.withOpacity(0.12),
            activeColor: _navy,
            inactiveColor: const Color(0xFFE8EDF5),
            selectedColor: _navy,
          ),
          errorTextSpace: 20,
          beforeTextPaste: (_) => false,
          onChanged: (_) {},
          onCompleted: onCompleted,
        ),
      ],
    );
  }
}
