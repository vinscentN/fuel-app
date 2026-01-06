// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/auth_provider.dart';
// import '../../utils/colors.dart';
// import '../home/dashboard_screen.dart';
// import './login_settings_screen.dart';
// import './password_reset_screen.dart';
// import '../card/card_balance_screen.dart';
// import '../card/card_pin_reset_screen.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.1),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
//     );
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _handleLogin() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//
//     try {
//       final success = await authProvider.login(
//         _usernameController.text.trim(),
//         _passwordController.text,
//       );
//
//       if (success && mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (_) => const DashboardScreen()),
//         );
//       } else if (mounted) {
//         _showErrorSnackBar('Invalid username or password');
//       }
//     } catch (e) {
//       if (mounted) {
//         _showErrorSnackBar('Login failed. Please try again.');
//       }
//     }
//   }
//
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: const Color(0xFFE74C3C),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFFFAFAFA),
//               Color(0xFFFFFFFF),
//               Color(0xFFF5F5F7),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
//               child: FadeTransition(
//                 opacity: _fadeAnimation,
//                 child: SlideTransition(
//                   position: _slideAnimation,
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const SizedBox(height: 20),
//
//                       // Refined logo section
//                       Container(
//                         width: 80,
//                         height: 80,
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [
//                               Color(0xFF2563EB),
//                               Color(0xFF1E40AF),
//                             ],
//                           ),
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: const Color(0xFF2563EB).withOpacity(0.15),
//                               blurRadius: 24,
//                               offset: const Offset(0, 4),
//                               spreadRadius: 0,
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.local_gas_station_rounded,
//                           color: Colors.white,
//                           size: 38,
//                         ),
//                       ),
//                       const SizedBox(height: 32),
//
//                       // Clean typography
//                       const Text(
//                         'Welcome Back',
//                         style: TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.w700,
//                           color: Color(0xFF000000),
//                           letterSpacing: -0.5,
//                           height: 1.2,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       const Text(
//                         'Sign in to continue',
//                         style: TextStyle(
//                           fontSize: 17,
//                           fontWeight: FontWeight.w400,
//                           color: Color(0xFF86868B),
//                           letterSpacing: -0.2,
//                         ),
//                       ),
//                       const SizedBox(height: 48),
//
//                       // Clean form container
//                       Container(
//                         constraints: const BoxConstraints(maxWidth: 400),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(20),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.04),
//                               blurRadius: 40,
//                               offset: const Offset(0, 8),
//                               spreadRadius: 0,
//                             ),
//                             BoxShadow(
//                               color: Colors.black.withOpacity(0.02),
//                               blurRadius: 10,
//                               offset: const Offset(0, 2),
//                               spreadRadius: 0,
//                             ),
//                           ],
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(40),
//                           child: Form(
//                             key: _formKey,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.stretch,
//                               children: [
//                                 // Clean, minimal username field
//                                 TextFormField(
//                                   controller: _usernameController,
//                                   style: const TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.w400,
//                                     color: Color(0xFF000000),
//                                     letterSpacing: -0.3,
//                                   ),
//                                   decoration: InputDecoration(
//                                     labelText: 'Username',
//                                     labelStyle: const TextStyle(
//                                       color: Color(0xFF86868B),
//                                       fontSize: 17,
//                                       fontWeight: FontWeight.w400,
//                                       letterSpacing: -0.3,
//                                     ),
//                                     floatingLabelStyle: const TextStyle(
//                                       color: Color(0xFF2563EB),
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w600,
//                                       letterSpacing: -0.1,
//                                     ),
//                                     prefixIcon: const Icon(
//                                       Icons.person_outline_rounded,
//                                       color: Color(0xFF86868B),
//                                       size: 20,
//                                     ),
//                                     filled: true,
//                                     fillColor: const Color(0xFFF5F5F7),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: BorderSide.none,
//                                     ),
//                                     enabledBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: const BorderSide(
//                                         color: Color(0xFFE5E5EA),
//                                         width: 0.5,
//                                       ),
//                                     ),
//                                     focusedBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: const BorderSide(
//                                         color: Color(0xFF2563EB),
//                                         width: 1.5,
//                                       ),
//                                     ),
//                                     errorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: const BorderSide(
//                                         color: Color(0xFFFF3B30),
//                                         width: 1.5,
//                                       ),
//                                     ),
//                                     focusedErrorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: const BorderSide(
//                                         color: Color(0xFFFF3B30),
//                                         width: 1.5,
//                                       ),
//                                     ),
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                       vertical: 16,
//                                     ),
//                                     errorStyle: const TextStyle(
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w400,
//                                     ),
//                                   ),
//                                   validator: (value) => value == null || value.isEmpty
//                                       ? 'Please enter your username'
//                                       : null,
//                                 ),
//                                 const SizedBox(height: 16),
//
//                                 // Clean, minimal password field
//                                 TextFormField(
//                                   controller: _passwordController,
//                                   obscureText: _obscurePassword,
//                                   style: const TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.w400,
//                                     color: Color(0xFF000000),
//                                     letterSpacing: -0.3,
//                                   ),
//                                   decoration: InputDecoration(
//                                     labelText: 'Password',
//                                     labelStyle: const TextStyle(
//                                       color: Color(0xFF86868B),
//                                       fontSize: 17,
//                                       fontWeight: FontWeight.w400,
//                                       letterSpacing: -0.3,
//                                     ),
//                                     floatingLabelStyle: const TextStyle(
//                                       color: Color(0xFF2563EB),
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w600,
//                                       letterSpacing: -0.1,
//                                     ),
//                                     prefixIcon: const Icon(
//                                       Icons.lock_outline_rounded,
//                                       color: Color(0xFF86868B),
//                                       size: 20,
//                                     ),
//                                     suffixIcon: IconButton(
//                                       icon: Icon(
//                                         _obscurePassword
//                                             ? Icons.visibility_off_outlined
//                                             : Icons.visibility_outlined,
//                                         color: const Color(0xFF86868B),
//                                         size: 20,
//                                       ),
//                                       onPressed: () => setState(
//                                         () => _obscurePassword = !_obscurePassword,
//                                       ),
//                                     ),
//                                     filled: true,
//                                     fillColor: const Color(0xFFF5F5F7),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: BorderSide.none,
//                                     ),
//                                     enabledBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: const BorderSide(
//                                         color: Color(0xFFE5E5EA),
//                                         width: 0.5,
//                                       ),
//                                     ),
//                                     focusedBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: const BorderSide(
//                                         color: Color(0xFF2563EB),
//                                         width: 1.5,
//                                       ),
//                                     ),
//                                     errorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: const BorderSide(
//                                         color: Color(0xFFFF3B30),
//                                         width: 1.5,
//                                       ),
//                                     ),
//                                     focusedErrorBorder: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                       borderSide: const BorderSide(
//                                         color: Color(0xFFFF3B30),
//                                         width: 1.5,
//                                       ),
//                                     ),
//                                     contentPadding: const EdgeInsets.symmetric(
//                                       horizontal: 16,
//                                       vertical: 16,
//                                     ),
//                                     errorStyle: const TextStyle(
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w400,
//                                     ),
//                                   ),
//                                   validator: (value) {
//                                     if (value == null || value.isEmpty) {
//                                       return 'Please enter your password';
//                                     }
//                                     if (value.length < 4) {
//                                       return 'Password must be at least 4 characters';
//                                     }
//                                     return null;
//                                   },
//                                 ),
//                                 const SizedBox(height: 32),
//
//                                 // Apple-style sign in button
//                                 Consumer<AuthProvider>(
//                                   builder: (context, authProvider, _) {
//                                     return Container(
//                                       height: 52,
//                                       decoration: BoxDecoration(
//                                         gradient: authProvider.isLoading
//                                             ? null
//                                             : const LinearGradient(
//                                                 begin: Alignment.topCenter,
//                                                 end: Alignment.bottomCenter,
//                                                 colors: [
//                                                   Color(0xFF2563EB),
//                                                   Color(0xFF1D4ED8),
//                                                 ],
//                                               ),
//                                         color: authProvider.isLoading
//                                             ? const Color(0xFFE5E5EA)
//                                             : null,
//                                         borderRadius: BorderRadius.circular(12),
//                                         boxShadow: authProvider.isLoading
//                                             ? []
//                                             : [
//                                                 BoxShadow(
//                                                   color: const Color(0xFF2563EB)
//                                                       .withOpacity(0.25),
//                                                   blurRadius: 16,
//                                                   offset: const Offset(0, 4),
//                                                 ),
//                                               ],
//                                       ),
//                                       child: Material(
//                                         color: Colors.transparent,
//                                         child: InkWell(
//                                           onTap: authProvider.isLoading
//                                               ? null
//                                               : _handleLogin,
//                                           borderRadius: BorderRadius.circular(12),
//                                           splashColor: Colors.white.withOpacity(0.1),
//                                           highlightColor: Colors.white.withOpacity(0.05),
//                                           child: Center(
//                                             child: authProvider.isLoading
//                                                 ? const SizedBox(
//                                                     width: 22,
//                                                     height: 22,
//                                                     child: CircularProgressIndicator(
//                                                       strokeWidth: 2.5,
//                                                       valueColor:
//                                                           AlwaysStoppedAnimation<Color>(
//                                                         Color(0xFF86868B),
//                                                       ),
//                                                     ),
//                                                   )
//                                                 : const Text(
//                                                     'Sign In',
//                                                     style: TextStyle(
//                                                       fontSize: 17,
//                                                       fontWeight: FontWeight.w600,
//                                                       color: Colors.white,
//                                                       letterSpacing: -0.3,
//                                                     ),
//                                                   ),
//                                           ),
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 24),
//
//                       // Forgot Password link
//                       TextButton(
//                         onPressed: () {
//                           Navigator.of(context).push(
//                             MaterialPageRoute(
//                               builder: (_) => const PasswordResetScreen(),
//                             ),
//                           );
//                         },
//                         style: TextButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 20,
//                             vertical: 12,
//                           ),
//                         ),
//                         child: const Text(
//                           'Forgot Password?',
//                           style: TextStyle(
//                             color: Color(0xFF2563EB),
//                             fontSize: 15,
//                             fontWeight: FontWeight.w500,
//                             letterSpacing: -0.2,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _openSettings() {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (_) => const LoginSettingsScreen()),
//     );
//   }
// }
