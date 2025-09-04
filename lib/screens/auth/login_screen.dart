import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../home/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
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
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final success = await authProvider.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else if (mounted) {
        _showErrorSnackBar('Invalid username or password');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Login failed. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Animated Header Section
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildModernHeader(),
                  ),
                ),

                const SizedBox(height: 24),

                // Animated Login Form
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildModernLoginForm(),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Column(
      children: [
        // Beautiful Icon with modern styling
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF1A237E).withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background glow
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              // Main icon
              const Icon(
                Icons.local_gas_station_rounded,
                color: Colors.white,
                size: 36,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Stylish Title with gradient text
        ShaderMask(
          shaderCallback:
              (bounds) => const LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
          child: Text(
            'Fuel Mate',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Enhanced Subtitle with accent
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1A237E).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            'Fuel Attendant Portal',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF1A237E).withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernLoginForm() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1A237E).withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle gradient background
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFF1A237E).withOpacity(0.02),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Enhanced Welcome section
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Welcome Back',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF1A237E),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Sign in to continue your session',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1A237E).withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Username Field with icon
                  _buildModernTextField(
                    controller: _usernameController,
                    hintText: 'Username',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password Field with icon
                  _buildModernTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: const Color(0xFF1A237E).withOpacity(0.6),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 4) {
                        return 'Password must be at least 4 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // Enhanced Login Button
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return _buildModernButton(
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        isLoading: authProvider.isLoading,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1A237E).withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(
          color: Color(0xFF1A237E),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: const Color(0xFF1A237E).withOpacity(0.4),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon:
              prefixIcon != null
                  ? Container(
                    margin: const EdgeInsets.only(left: 4, right: 8),
                    child: Icon(
                      prefixIcon,
                      color: const Color(0xFF1A237E).withOpacity(0.6),
                      size: 20,
                    ),
                  )
                  : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: prefixIcon != null ? 8 : 16,
            vertical: 15,
          ),
          errorStyle: const TextStyle(
            color: Color(0xFFE74C3C),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildModernButton({
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isLoading) ...[
                  const Icon(
                    Icons.login_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
