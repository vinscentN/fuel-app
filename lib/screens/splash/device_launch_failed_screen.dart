import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_service.dart';
import '../auth/mobile_login_screen.dart';
import '../home/landing_menu_screen.dart';

class DeviceLaunchFailedScreen extends StatefulWidget {
  final String message;
  const DeviceLaunchFailedScreen({super.key, required this.message});

  @override
  State<DeviceLaunchFailedScreen> createState() => _DeviceLaunchFailedScreenState();
}

class _DeviceLaunchFailedScreenState extends State<DeviceLaunchFailedScreen> {
  bool _loading = false;
  String? _message;
  final PosService _pos = PosService();

  @override
  void initState() {
    super.initState();
    _message = widget.message;
  }

  Future<void> _retry() async {
    if (_loading) return;
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      // Read serial then attempt device launch again
      final serial = await _pos.readSerialNumber();
      if (serial == null || serial.isEmpty) {
        setState(() {
          _message = 'Device serial number not available';
          _loading = false;
        });
        return;
      }

      final ok = await auth.launchDevice(serial);
      if (!mounted) return;
      if (ok) {
        // Preload products and go to login unless already authenticated
        await auth.ensureProductsLoaded();
        if (!mounted) return;
        final next = auth.isAuthenticated
            ? const LandingMenuScreen()
            : const MobileLoginScreen();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => next),
          (route) => false,
        );
      } else {
        setState(() {
          _message = auth.errorMessage ?? 'Device launch failed';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Retry failed: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 72, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Device Launch Failed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                if (_message != null)
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _retry,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_loading ? 'Retrying…' : 'Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
}
