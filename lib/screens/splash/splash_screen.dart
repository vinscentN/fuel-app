import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../auth/mobile_login_screen.dart';
import '../home/landing_menu_screen.dart';
import '../driver/driver_menu_screen.dart';
import 'device_launch_failed_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final Animation<double> _fade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  final PosService _posService = PosService();
  String _status = 'App initialisation';

  @override
  void initState() {
    super.initState();

    // Pulsing animation for progress indicator
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Logo entrance animation - quick and subtle
    _logoController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );
    _logoFade = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    // Text entrance animation - slides up and fades in
    _textController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _logoController.forward();
    _textController.forward();

    // Kick off device launch flow after first frame to ensure UI paints.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLaunchFlow();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    String displayName = auth.serviceStationName ?? '';
    displayName = displayName.replaceAll(RegExp(r'\s*GASMATE\s+?\s*$', caseSensitive: false), '').trim();
    if (displayName.isEmpty) {
      displayName = 'GASMATE';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo - simple without card
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Image.asset(
                      'images/logo.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Service Station name - clean text
                FadeTransition(
                  opacity: _logoFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Loading message with icon
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      // Animated progress indicator - clean
                      FadeTransition(
                        opacity: _fade,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: AppColors.primary,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status text with slide and fade animation
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textFade,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: Text(
                              _status,
                              key: ValueKey<String>(_status),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Bottom branding or version
                FadeTransition(
                  opacity: _logoFade,
                  child: Text(
                    'Powered by Poscloud',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startLaunchFlow() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Small delay to ensure UI renders
      await Future.delayed(const Duration(milliseconds: 50));

      _updateStatus('Preparing app...');
      await Future.delayed(const Duration(milliseconds: 500));

      // Check device configuration
      _updateStatus('Checking device...');
      final deviceConfigured = await _checkDeviceConfiguration();

      if (!mounted) return;

      if (!deviceConfigured) {
        // Device is not configured, show failure screen
        return;
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Load any saved session (token, user, etc.)
      _updateStatus('Checking session...');
      await auth.loadSession();
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Check if user is already logged in
      if (auth.isAuthenticated && auth.currentUser != null) {
        _updateStatus('Welcome back!');
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate based on user designation
        final user = auth.currentUser!;
        if (user.isDriver) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DriverMenuScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LandingMenuScreen()),
          );
        }
      } else {
        // No saved session, go to login
        _updateStatus('Starting...');
        await Future.delayed(const Duration(milliseconds: 500));

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // On error, go to login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
      );
    }
  }

  Future<bool> _checkDeviceConfiguration() async {
    try {
      // Read device serial number
      final serial = await _posService.readSerialNumber();

      if (serial == null || serial.isEmpty) {
        _goToFailure('Device serial number not available. Please contact support.');
        return false;
      }

      // Call device launch API to check if device is configured
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final isConfigured = await auth.launchDevice(serial);

      if (!isConfigured) {
        final errorMsg = auth.errorMessage ??
                        'This device is not configured. Please contact your administrator to configure this device.';
        _goToFailure(errorMsg);
        return false;
      }

      // Device is configured, continue
      return true;
    } catch (e) {
      _goToFailure('Failed to verify device configuration: ${e.toString()}');
      return false;
    }
  }

  Future<bool> _waitForSdkReady({int timeoutMs = 15000}) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start).inMilliseconds < timeoutMs) {
      try {
        final ok = await _posService.checkNfcAvailability();
        if (ok == true) return true;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  void _updateStatus(String s) {
    if (!mounted) return;
    setState(() => _status = s);
  }

  void _goToFailure(String message) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DeviceLaunchFailedScreen(message: message),
      ),
    );
  }
}
