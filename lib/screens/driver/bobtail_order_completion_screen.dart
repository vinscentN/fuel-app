import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/bobtail_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/bobtail_order_service.dart';
import '../../utils/colors.dart';

class BobtailOrderCompletionScreen extends StatefulWidget {
  final BobtailOrder order;

  const BobtailOrderCompletionScreen({
    super.key,
    required this.order,
  });

  @override
  State<BobtailOrderCompletionScreen> createState() =>
      _BobtailOrderCompletionScreenState();
}

class _BobtailOrderCompletionScreenState
    extends State<BobtailOrderCompletionScreen> {
  final BobtailOrderService _service = BobtailOrderService();
  final TextEditingController _actualKgController = TextEditingController();
  final TextEditingController _unitCostController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _actualKgController.dispose();
    _unitCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_actualKgController.text.trim().isEmpty) {
      _showSnack('Please enter actual kg', Colors.orange);
      return;
    }
    if (_unitCostController.text.trim().isEmpty) {
      _showSnack('Please enter unit cost', Colors.orange);
      return;
    }

    final actualKg = double.tryParse(_actualKgController.text.trim());
    if (actualKg == null || actualKg <= 0) {
      _showSnack('Invalid actual kg', Colors.orange);
      return;
    }

    final unitCost = double.tryParse(_unitCostController.text.trim());
    if (unitCost == null || unitCost <= 0) {
      _showSnack('Invalid unit cost', Colors.orange);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _service.completeOrder(
        id: widget.order.id,
        actualKg: actualKg,
        unitCost: unitCost,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        token: token,
      );

      if (mounted) {
        await _printDeliveryNotes(
          authProvider: authProvider,
          driverName: authProvider.currentUser?.fullName ?? 'N/A',
          actualKg: actualKg,
          unitCost: unitCost,
          notes: _notesController.text.trim(),
        );
        _showSnack(
          response['message'] ?? 'Bobtail order completed successfully',
          Colors.green,
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          'Failed to complete order: ${e.toString().replaceAll('Exception: ', '')}',
          Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _printDeliveryNotes({
    required AuthProvider authProvider,
    required String driverName,
    required double actualKg,
    required double unitCost,
    required String notes,
  }) async {
    try {
      final posProvider = Provider.of<PosProvider>(context, listen: false);
      final now = DateTime.now();
      final dateFormatter = DateFormat('dd/MM/yyyy');
      final timeFormatter = DateFormat('HH:mm:ss');
      final isPurchase = widget.order.orderType.toUpperCase() == 'PURCHASE';

      final requestCode = 'BOBTAIL-${widget.order.id}';
      final deliveryCode = widget.order.orderType.toUpperCase();
      final siteName = isPurchase
          ? (widget.order.supplier?.name ?? 'Supplier')
          : (widget.order.gasOrder?.site?.name ??
              widget.order.gasOrder?.requestCode ??
              'Site');
      final siteCode = isPurchase ? 'SUPPLIER' : 'N/A';

      final details = [
        'Order Type: ${widget.order.orderType}',
        'Expected: ${widget.order.expectedKg} kg',
        'Actual: ${actualKg.toStringAsFixed(2)} kg',
        'Unit Cost: ${unitCost.toStringAsFixed(2)}',
        if (notes.trim().isNotEmpty) 'Notes: ${notes.trim()}',
      ].join('\n');

      final descriptionBase = [
        'Bobtail: ${widget.order.bobtail?.plateNumber ?? widget.order.bobtailId}',
        if (isPurchase)
          'Supplier: ${widget.order.supplier?.name ?? 'N/A'}'
        else
          'Site: ${widget.order.gasOrder?.site?.name ?? 'N/A'}',
      ].join('\n');

      await posProvider.printDeliveryReceipt(
        requestCode: requestCode,
        deliveryCode: deliveryCode,
        invoiceNumber: 'N/A',
        stationName: authProvider.serviceStationName ?? 'N/A',
        address: authProvider.serviceStationAddress ?? '',
        phone: authProvider.serviceStationPhone ?? '',
        date: dateFormatter.format(now),
        time: timeFormatter.format(now),
        driverName: driverName,
        cylinderCount: '-',
        cylinderDetails: details,
        description: 'COPY: DRIVER\n$descriptionBase',
        siteName: siteName,
        siteCode: siteCode,
      );

      await posProvider.printDeliveryReceipt(
        requestCode: requestCode,
        deliveryCode: deliveryCode,
        invoiceNumber: 'N/A',
        stationName: authProvider.serviceStationName ?? 'N/A',
        address: authProvider.serviceStationAddress ?? '',
        phone: authProvider.serviceStationPhone ?? '',
        date: dateFormatter.format(now),
        time: timeFormatter.format(now),
        driverName: driverName,
        cylinderCount: '-',
        cylinderDetails: details,
        description: 'COPY: ATTENDANT\n$descriptionBase',
        siteName: siteName,
        siteCode: siteCode,
      );
    } catch (e) {
      debugPrint('Bobtail delivery note print failed: $e');
      if (mounted) {
        _showSnack('Print failed: ${e.toString()}', Colors.orange);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPurchase = widget.order.orderType.toUpperCase() == 'PURCHASE';
    final title = isPurchase ? 'Record Purchase' : 'Complete Site Refill';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actual Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _actualKgController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Actual kg',
                          hintText: 'e.g., 5200.75',
                          prefixIcon: const Icon(Icons.scale_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unit Cost',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _unitCostController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Unit cost',
                          hintText: 'e.g., 118.50',
                          prefixIcon: const Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Optional notes',
                          prefixIcon: const Icon(Icons.note_alt_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isPurchase ? 'Record Purchase' : 'Complete Refill',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
