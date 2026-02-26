import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_service.dart';
import '../home/landing_menu_screen.dart';
import '../driver/driver_menu_screen.dart';
import './password_reset_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  final String? sessionExpiredMessage;

  const MobileLoginScreen({super.key, this.sessionExpiredMessage});

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msg = widget.sessionExpiredMessage;
      if (msg != null && msg.isNotEmpty && mounted) {
        _showErrorSnackBar(msg);
      }
    });
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        32,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),
                        _buildLogo(),
                        const SizedBox(height: 16),
                        _buildLoginForm(primaryBlue),
                        const SizedBox(height: 8),
                        _buildFooter(),
                        const Spacer(flex: 1),
                      ],
                    ),
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
      child: Image.asset(
        "images/logo.png",
        height: 56,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildLoginForm(Color primaryBlue) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to continue',
              style: TextStyle(
                color: const Color(0xFF6B7280).withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildUsernameField(primaryBlue),
            const SizedBox(height: 24),
            _buildPasswordField(primaryBlue),
            const SizedBox(height: 32),
            _buildSignInButton(primaryBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernameField(Color primaryBlue) {
    return TextFormField(
      controller: _usernameController,
      focusNode: _usernameFocus,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
        letterSpacing: 0.2,
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
      decoration: InputDecoration(
        labelText: 'Username',
        labelStyle: TextStyle(
          color: const Color(0xFF6B7280).withOpacity(0.8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        floatingLabelStyle: TextStyle(
          color: primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Icon(
            Icons.person_outline_rounded,
            color: const Color(0xFF6B7280).withOpacity(0.7),
            size: 20,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: const Color(0xFF6B7280).withOpacity(0.25),
            width: 1.5,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: primaryBlue,
            width: 2.5,
          ),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFFF3B30),
            width: 2,
          ),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFFF3B30),
            width: 2.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 0,
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFF3B30),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your username';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(Color primaryBlue) {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
        letterSpacing: 0.2,
      ),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(
          color: const Color(0xFF6B7280).withOpacity(0.8),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
        floatingLabelStyle: TextStyle(
          color: primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Icon(
            Icons.lock_outline_rounded,
            color: const Color(0xFF6B7280).withOpacity(0.7),
            size: 20,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 36),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF6B7280).withOpacity(0.7),
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          splashRadius: 20,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: const Color(0xFF6B7280).withOpacity(0.25),
            width: 1.5,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: primaryBlue,
            width: 2.5,
          ),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFFF3B30),
            width: 2,
          ),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFFF3B30),
            width: 2.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 0,
        ),
        errorStyle: const TextStyle(
          color: Color(0xFFFF3B30),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildSignInButton(Color primaryBlue) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: authProvider.isLoading
                ? null
                : LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
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
                      color: primaryBlue.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                        width: 20,
                        height: 20,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
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
              horizontal: 16,
              vertical: 4,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Reset Password?',
            style: TextStyle(
              color: Color(0xFF0A4DA3),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Text(
          'Powered by Poscloud',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
