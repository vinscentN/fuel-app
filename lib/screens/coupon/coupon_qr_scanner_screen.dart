import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/colors.dart';

class CouponQrScannerScreen extends StatefulWidget {
  const CouponQrScannerScreen({super.key});

  @override
  State<CouponQrScannerScreen> createState() => _CouponQrScannerScreenState();
}

class _CouponQrScannerScreenState extends State<CouponQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Coupon QR'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
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
                      await _controller.toggleTorch();
                      setState(() {});
                    },
                    child: const Icon(Icons.flash_on, color: Colors.black),
                  ),
                  FloatingActionButton.extended(
                    heroTag: 'cancel',
                    backgroundColor: Colors.white,
                    onPressed: () => Navigator.of(context).pop(),
                    label: const Text('Cancel', style: TextStyle(color: Colors.black)),
                    icon: const Icon(Icons.close, color: Colors.black),
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

