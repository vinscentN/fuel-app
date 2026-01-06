import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_service.dart';
import '../home/landing_menu_screen.dart';
import '../driver/driver_menu_screen.dart';
import './password_reset_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final PosService _posService = PosService();
  bool _obscurePassword = true;
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
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Unfocus to dismiss keyboard
    FocusScope.of(context).unfocus();

    try {
      // Read device serial number
      final serial = await _posService.readSerialNumber();

      if (serial == null || serial.isEmpty) {
        if (mounted) {
          _showErrorSnackBar(
            'Device serial number not available. Please contact support.',
          );
        }
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.mobileLogin(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        serial,
      );

      if (success && mounted) {
        final user = authProvider.currentUser;
        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => user.isDriver
                  ? const DriverMenuScreen()
                  : const LandingMenuScreen(),
            ),
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackBar(
            authProvider.errorMessage ?? 'Invalid credentials',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Login failed: ${e.toString()}');
      }
    }
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    _buildLogo(),
                    const SizedBox(height: 28),
                    _buildLoginForm(primaryBlue),
                    const SizedBox(height: 20),
                    _buildFooter(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'app_logo',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Image.asset(
          "images/logo.png",
          height: 65,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildLoginForm(Color primaryBlue) {
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
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUsernameField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 28),
              _buildSignInButton(primaryBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'USERNAME',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextFormField(
          controller: _usernameController,
          focusNode: _usernameFocus,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
          decoration: InputDecoration(
            hintText: 'Enter your username',
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              child: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF9CA3AF),
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
              vertical: 18,
            ),
            errorStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
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

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'PASSWORD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscurePassword,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 16,
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
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF9CA3AF),
                size: 22,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
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
              vertical: 18,
            ),
            errorStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignInButton(Color primaryBlue) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: authProvider.isLoading
                ? null
                : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryBlue,
                primaryBlue.withOpacity(0.85),
              ],
            ),
            color: authProvider.isLoading ? const Color(0xFFE5E7EB) : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: authProvider.isLoading
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
              onTap: authProvider.isLoading ? null : _handleLogin,
              borderRadius: BorderRadius.circular(14),
              splashColor: Colors.white.withOpacity(0.2),
              highlightColor: Colors.white.withOpacity(0.1),
              child: Center(
                child: authProvider.isLoading
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
                  'Sign In',
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
      },
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Forgot Password button
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PasswordResetScreen(),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: const Text(
            'Reset Password?',
            style: TextStyle(
              color: Color(0xFF0A4DA3),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Powered by Poscloud',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}