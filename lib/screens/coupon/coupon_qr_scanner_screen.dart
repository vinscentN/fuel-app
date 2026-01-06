import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/colors.dart';

class CouponQrScannerScreen extends StatefulWidget {
  const CouponQrScannerScreen({super.key});

  @override
  State<CouponQrScannerScreen> createState() => _CouponQrScannerScreenState();
}

class _CouponQrScannerScreenState extends State<CouponQrScannerScreen> {
  MobileScannerController? _controller;
  final TextEditingController _manualInputController = TextEditingController();
  bool _handled = false;
  bool _hasPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    try {
      // Add timeout to prevent hanging
      final status = await Permission.camera.status.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          // On timeout, assume permission is granted (for older Android)
          debugPrint('Permission check timeout - assuming granted');
          return PermissionStatus.granted;
        },
      );

      debugPrint('Camera permission status: $status');

      if (status.isGranted) {
        if (mounted) {
          setState(() {
            _hasPermission = true;
            _isCheckingPermission = false;
          });
          _initializeCamera();
        }
      } else if (status.isDenied) {
        final result = await Permission.camera.request().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Permission request timeout - assuming granted');
            return PermissionStatus.granted;
          },
        );

        if (mounted) {
          setState(() {
            _hasPermission = result.isGranted;
            _isCheckingPermission = false;
          });
          if (result.isGranted) {
            _initializeCamera();
          }
        }
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          setState(() {
            _hasPermission = false;
            _isCheckingPermission = false;
          });
          _showPermissionDeniedDialog();
        }
      } else {
        // Fallback for older Android versions or unknown states
        debugPrint('Unknown permission state: $status - initializing camera');
        if (mounted) {
          setState(() {
            _hasPermission = true;
            _isCheckingPermission = false;
          });
          _initializeCamera();
        }
      }
    } catch (e) {
      // If permission check fails (e.g., on older Android), try to initialize anyway
      debugPrint('Permission check failed: $e');
      if (mounted) {
        setState(() {
          _hasPermission = true;
          _isCheckingPermission = false;
        });
        _initializeCamera();
      }
    }
  }

  void _initializeCamera() {
    _controller = MobileScannerController();
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera access is required to scan QR codes. Please grant camera permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openAppSettings();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  String? _extractCouponCode(String raw) {
    final s = raw.trim();
    // If full URL containing validate-coupon, pick the last path segment
    final idx = s.toLowerCase().indexOf('validate-coupon');
    if (idx != -1) {
      final pieces = Uri.tryParse(s)?.pathSegments;
      if (pieces != null && pieces.isNotEmpty) {
        return pieces.last.toUpperCase();
      }
    }
    // Otherwise, look for a token like 250001-UIZLSF (alnum-hyphen-alnum)
    final re = RegExp(r"[A-Za-z0-9]+-[A-Za-z0-9]+");
    final m = re.firstMatch(s);
    if (m != null) return m.group(0)!.toUpperCase();
    // If the whole raw looks like a code, accept it
    if (RegExp(r"^[A-Za-z0-9-]{5,}$").hasMatch(s)) return s.toUpperCase();
    return null;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    final raw = codes.first.rawValue;
    if (raw == null) return;
    final code = _extractCouponCode(raw);
    if (code == null) return;
    _handled = true;
    Navigator.of(context).pop(code);
  }

  void _showManualInputDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Enter Coupon Code'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _manualInputController.clear();
                Navigator.of(context).pop();
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Text(
                  'Enter the coupon code manually',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _manualInputController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 18,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Coupon Code',
                    hintText: 'e.g., 250001-UIZLSF',
                    prefixIcon: const Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _submitManualCode(value);
                    }
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    final code = _manualInputController.text.trim();
                    if (code.isNotEmpty) {
                      _submitManualCode(code);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  void _submitManualCode(String code) {
    if (_handled) return;
    final extractedCode = _extractCouponCode(code);
    if (extractedCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid coupon code format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _handled = true;
    Navigator.of(context).pop();
    _manualInputController.clear();
    Navigator.of(context).pop(extractedCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Coupon QR'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isCheckingPermission
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : !_hasPermission
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 80,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Camera Permission Required',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Please grant camera permission to scan QR codes',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await openAppSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'flash',
                              backgroundColor: Colors.white,
                              onPressed: () async {
                                await _controller?.toggleTorch();
                                setState(() {});
                              },
                              child: const Icon(Icons.flash_on, color: Colors.black),
                            ),
                            FloatingActionButton.extended(
                              heroTag: 'manual',
                              backgroundColor: Colors.white,
                              onPressed: _showManualInputDialog,
                              label: const Text('Manual Entry', style: TextStyle(color: Colors.black)),
                              icon: const Icon(Icons.keyboard, color: Colors.black),
                            ),
                            FloatingActionButton.small(
                              heroTag: 'cancel',
                              backgroundColor: Colors.white,
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Icon(Icons.close, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

