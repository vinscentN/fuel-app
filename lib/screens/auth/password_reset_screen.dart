import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
        oldPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          _showSuccessDialog();
        } else {
          // Error message already set in provider
          final errorMessage = authProvider.errorMessage ?? 'Password reset failed. Please try again.';
          _showErrorSnackBar(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Password reset failed. Please try again.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text(
          'Success',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        content: const Text(
          'Operator code changed successfully. You can now login with your new code.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to login
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A4DA3),
                letterSpacing: -0.3,
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
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0A4DA3);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Back button header
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Color(0xFF0A4DA3),
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Back',
                    style: TextStyle(
                      color: Color(0xFF0A4DA3),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          _buildTitle(),
                          const SizedBox(height: 24),
                          _buildResetForm(primaryBlue),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Reset Operator Code',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Enter your details to reset your operator code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResetForm(Color primaryBlue) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 48,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                label: 'USERNAME',
                controller: _usernameController,
                hintText: 'Enter your username',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                label: 'CURRENT OPERATOR CODE',
                controller: _currentPasswordController,
                hintText: 'Enter current operator code',
                obscureText: _obscureCurrentPassword,
                onToggleVisibility: () =>
                    setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current operator code';
                  }
                  if (value.length < 4) {
                    return 'Operator code must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                label: 'NEW OPERATOR CODE',
                controller: _newPasswordController,
                hintText: 'Enter new operator code',
                obscureText: _obscureNewPassword,
                onToggleVisibility: () =>
                    setState(() => _obscureNewPassword = !_obscureNewPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new operator code';
                  }
                  if (value.length < 4) {
                    return 'Operator code must be at least 4 characters';
                  }
                  if (value == _currentPasswordController.text) {
                    return 'New operator code must be different';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                label: 'CONFIRM NEW OPERATOR CODE',
                controller: _confirmPasswordController,
                hintText: 'Confirm new operator code',
                obscureText: _obscureConfirmPassword,
                onToggleVisibility: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your operator code';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Operator codes do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildResetButton(primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Icon(
                icon,
                color: const Color(0xFF9CA3AF),
                size: 22,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0A4DA3),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFFF3B30),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFFF3B30),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            errorStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF9CA3AF),
                size: 22,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF),
                size: 22,
              ),
              onPressed: onToggleVisibility,
              splashRadius: 24,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0A4DA3),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFFF3B30),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFFF3B30),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            errorStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildResetButton(Color primaryBlue) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: _isLoading
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBlue,
                  primaryBlue.withOpacity(0.85),
                ],
              ),
        color: _isLoading ? const Color(0xFFE5E7EB) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: primaryBlue.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handlePasswordReset,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.2),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(
                        Color(0xFF9CA3AF),
                      ),
                    ),
                  )
                : const Text(
                    'Reset Operator Code',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
