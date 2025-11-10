import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../home/landing_menu_screen.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  final PosService _posService = PosService();
  String _status = 'The app is launching. Setting up in progress';

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Kick off device launch flow after first frame to ensure UI paints.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLaunchFlow();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'images/logo.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              // App name
              const Text(
                'LTX Fuels',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              // Loading message
              const Text(
                // Kept as a semantic fallback; UI below uses the dynamic _status
                '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
              // Simple animation: pulsing progress indicator
              FadeTransition(
                opacity: _fade,
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startLaunchFlow() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      _updateStatus('Preparing app...');
      // Load any saved session (station id/name, token, etc.)
      await auth.loadSession();

      // 1) Wait for POS SDK initialization
      _updateStatus('Initializing device (SDK)...');
      final ready = await _waitForSdkReady(timeoutMs: 20000);
      if (!ready) {
        _goToFailure('POS SDK not ready');
        return;
      }
      // 2) Read device serial number from POS SDK
      _updateStatus('Reading device serial number...');
      final serial = await _posService.readSerialNumber();

      if (serial == null || serial.isEmpty) {
        _goToFailure('Device serial number not available');
        return;
      }

      // 3) Hit device launch endpoint
      _updateStatus('Launching device...');
      final ok = await auth.launchDevice(serial);
      if (!mounted) return;

      if (ok) {
        // 4) Ensure products are available before entering the app (force fresh)
        _updateStatus('Loading products...');
        await auth.ensureProductsLoaded(force: true);
        _updateStatus('Starting app...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LandingMenuScreen()),
        );
      } else {
        _goToFailure(auth.errorMessage ?? 'Device launch failed');
      }
    } catch (e) {
      if (!mounted) return;
      _goToFailure('Device launch failed: $e');
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
