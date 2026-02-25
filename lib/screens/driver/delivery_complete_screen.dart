import 'package:flutter/material.dart';
import '../../models/delivery_order.dart';
import '../../providers/pos_provider.dart';

class DeliveryCompleteScreen extends StatefulWidget {
  final DeliveryOrder order;
  final Map<String, String> receiptData;
  final PosProvider posProvider;
  /// Callback to print a copy. Accepts the data map, copy-type, provider,
  /// and an optional cylinderDetailsOverride.
  final Future<void> Function(
      Map<String, String> data,
      String copyType,
      PosProvider posProvider, {
      String? cylinderDetailsOverride})
      onPrint;

  const DeliveryCompleteScreen({
    super.key,
    required this.order,
    required this.receiptData,
    required this.posProvider,
    required this.onPrint,
  });

  @override
  State<DeliveryCompleteScreen> createState() =>
      _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState extends State<DeliveryCompleteScreen> {
  // ── Palette ────────────────────────────────────────────────────
  static const _navy   = Color(0xFF1C2B4A);
  static const _green  = Color(0xFF16A34A);
  static const _blue   = Color(0xFF2563EB);
  static const _bg     = Color(0xFFF5F7FA);
  static const _border = Color(0xFFE2E8F0);
  static const _text   = Color(0xFF1E293B);
  static const _muted  = Color(0xFF64748B);

  bool _customerPrinted = false;
  bool _customerPrinting = true; // auto-print in progress
  bool _driverPrinting = false;
  String? _printError;

  @override
  void initState() {
    super.initState();
    // Auto-print customer copy (home) or attendant copy (retail/site) on mount
    WidgetsBinding.instance.addPostFrameCallback((_) => _printCustomer());
  }

  bool get _isHome =>
      widget.order.typeLabel == 'HOME';

  Future<void> _printCustomer() async {
    setState(() {
      _customerPrinting = true;
      _printError = null;
    });
    try {
      if (_isHome) {
        // Home delivery → customer receipt: serial, qty, unit price, total
        await widget.onPrint(
          widget.receiptData,
          'CUSTOMER COPY',
          widget.posProvider,
          cylinderDetailsOverride:
              widget.receiptData['customerCylinderDetails'],
        );
      } else {
        // Retail / site delivery → attendant copy: bottom edge, product weight, current weight
        await widget.onPrint(
          widget.receiptData,
          'ATTENDANT COPY',
          widget.posProvider,
        );
      }
      if (mounted) {
        setState(() {
          _customerPrinted = true;
          _customerPrinting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _customerPrinting = false;
          _printError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _printDriver() async {
    setState(() => _driverPrinting = true);
    try {
      await widget.onPrint(
        widget.receiptData,
        'DRIVER COPY',
        widget.posProvider,
      );
      if (mounted) {
        setState(() => _driverPrinting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver copy printed'),
            backgroundColor: _green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _driverPrinting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Print failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final totalKgsValue = order.hasBobtail
        ? (order.expectedKg ?? order.totalKg ?? order.totalKgsLoaded)
        : order.totalKgsLoaded;
    final totalKgs = totalKgsValue.toStringAsFixed(2);
    final recipientName =
        order.site?.name ?? order.customer?.name ?? 'Unknown';
    final invoiceNo = widget.receiptData['invoiceNumber'] ?? 'N/A';

    return PopScope(
      // Prevent back-swipe returning to details; force use of Done button
      canPop: false,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────
              Container(
                color: _navy,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Delivery Complete',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // ── Success icon ──────────────────────────────
                      const SizedBox(height: 12),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _green.withValues(alpha: 0.3),
                              width: 2),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: _green,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Delivery Confirmed',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        recipientName,
                        style: const TextStyle(
                            fontSize: 14,
                            color: _muted,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 24),

                      // ── Order summary card ────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          children: [
                            _summaryRow(
                                'Invoice',
                                invoiceNo,
                                Icons.receipt_long_outlined),
                            _divider(),
                            _summaryRow(
                                'Cylinders',
                                order.items.length.toString(),
                                Icons.propane_tank_outlined),
                            _divider(),
                            _summaryRow(
                                'Total KGs Delivered',
                                '$totalKgs kg',
                                Icons.scale_outlined),
                            _divider(),
                            _summaryRow(
                                'Order Type',
                                order.typeLabel,
                                Icons.category_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Customer copy status ──────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _customerPrinted
                              ? _green.withValues(alpha: 0.07)
                              : _customerPrinting
                                  ? _blue.withValues(alpha: 0.07)
                                  : Colors.red.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _customerPrinted
                                ? _green.withValues(alpha: 0.3)
                                : _customerPrinting
                                    ? _blue.withValues(alpha: 0.3)
                                    : Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_customerPrinting)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _blue),
                              )
                            else
                              Icon(
                                _customerPrinted
                                    ? Icons.print_rounded
                                    : Icons.print_disabled_outlined,
                                size: 16,
                                color: _customerPrinted
                                    ? _green
                                    : Colors.red,
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _customerPrinting
                                    ? (_isHome
                                        ? 'Printing customer copy…'
                                        : 'Printing attendant copy…')
                                    : _customerPrinted
                                        ? (_isHome
                                            ? 'Customer copy printed'
                                            : 'Attendant copy printed')
                                        : (_isHome
                                            ? 'Customer copy failed — tap to retry'
                                            : 'Attendant copy failed — tap to retry'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _customerPrinted
                                      ? _green
                                      : _customerPrinting
                                          ? _blue
                                          : Colors.red,
                                ),
                              ),
                            ),
                            if (!_customerPrinting && !_customerPrinted)
                              GestureDetector(
                                onTap: _printCustomer,
                                child: const Text('Retry',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _blue,
                                        decoration:
                                            TextDecoration.underline)),
                              ),
                          ],
                        ),
                      ),

                      if (_printError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _printError!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.red),
                        ),
                      ],

                      // ── Customer info card ─────────────────────────
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline_rounded,
                                    size: 14, color: _muted),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.receiptData['customerName'] ??
                                        recipientName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if ((widget.receiptData['address'] ?? '').isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 14, color: _muted),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.receiptData['address']!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: _muted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom action bar ───────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border(top: BorderSide(color: _border)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Print Driver Copy button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed:
                            _driverPrinting ? null : _printDriver,
                        icon: _driverPrinting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _blue),
                              )
                            : const Icon(Icons.print_outlined,
                                size: 18),
                        label: Text(
                          _driverPrinting
                              ? 'Printing…'
                              : 'Print Driver Copy',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _blue,
                          side: const BorderSide(color: _blue),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Done button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .popUntil((r) => r.isFirst),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _muted),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 13, color: _muted)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _text)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: _border);
}
