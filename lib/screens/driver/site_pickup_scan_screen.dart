import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/auth_provider.dart';
import '../../services/gas_order_service.dart';
import '../../utils/colors.dart';
import 'site_pickup_details_screen.dart';

class SitePickupScanScreen extends StatefulWidget {
  const SitePickupScanScreen({super.key});

  @override
  State<SitePickupScanScreen> createState() => _SitePickupScanScreenState();
}

class _SitePickupScanScreenState extends State<SitePickupScanScreen> {
  final GasOrderService _gasOrderService = GasOrderService();
  final TextEditingController _manualInputController = TextEditingController();
  MobileScannerController? cameraController;
  bool _isProcessing = false;
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
    cameraController = MobileScannerController();
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
    cameraController?.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  Future<void> _handleQRScanned(String code) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Fetch order details using the scanned request code
      final order = await _gasOrderService.getOrderByRequestCode(code, token);

      if (mounted) {
        // Navigate to details screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SitePickupDetailsScreen(order: order),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showManualInputDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Enter Request Code'),
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
                  'Enter the request code manually',
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
                    labelText: 'Request Code',
                    hintText: 'e.g., REQ-12345',
                    prefixIcon: const Icon(Icons.qr_code_2),
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
                      Navigator.of(context).pop();
                      _submitManualCode(value);
                    }
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    final code = _manualInputController.text.trim();
                    if (code.isNotEmpty) {
                      Navigator.of(context).pop();
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
    _manualInputController.clear();
    _handleQRScanned(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: 'Manual Entry',
            onPressed: _showManualInputDialog,
          ),
        ],
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
                    // Camera view
                    MobileScanner(
                      controller: cameraController,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            _handleQRScanned(barcode.rawValue!);
                            break;
                          }
                        }
                      },
                    ),

                    // Overlay with scanning frame
                    CustomPaint(
                      painter: ScannerOverlay(),
                      child: Container(),
                    ),

          // Manual entry button at bottom
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.extended(
                onPressed: _showManualInputDialog,
                backgroundColor: Colors.white,
                icon: const Icon(Icons.keyboard, color: Colors.black),
                label: const Text('Manual Entry', style: TextStyle(color: Colors.black)),
              ),
            ),
          ),

                    // Loading indicator
                    if (_isProcessing)
                      Container(
                        color: Colors.black.withOpacity(0.7),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 250,
    );

    // Draw the overlay with a transparent square in the middle
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(12)))
          ..close(),
      ),
      paint,
    );

    // Draw corner brackets
    final bracketPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top + cornerLength),
      Offset(scanArea.left, scanArea.top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left + cornerLength, scanArea.top),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.top),
      Offset(scanArea.right, scanArea.top),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right, scanArea.top + cornerLength),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom - cornerLength),
      Offset(scanArea.left, scanArea.bottom),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left + cornerLength, scanArea.bottom),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom - cornerLength),
      Offset(scanArea.right, scanArea.bottom),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
