import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/driver_order.dart';
import '../../providers/auth_provider.dart';
import '../../services/warehouse_service.dart';
import '../../utils/colors.dart';

class FulfillDriverOrderScreen extends StatefulWidget {
  final DriverOrder order;

  const FulfillDriverOrderScreen({
    super.key,
    required this.order,
  });

  @override
  State<FulfillDriverOrderScreen> createState() =>
      _FulfillDriverOrderScreenState();
}

class _FulfillDriverOrderScreenState extends State<FulfillDriverOrderScreen> {
  final WarehouseService _warehouseService = WarehouseService();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _invoiceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final presetQuantity = widget.order.productWeight ?? widget.order.actualKg;
    if (presetQuantity != null && presetQuantity.trim().isNotEmpty) {
      _quantityController.text = presetQuantity;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  String _orderTypeLabel() {
    final normalizedType = widget.order.type.toUpperCase();
    if (normalizedType == 'GAS_REFILL') {
      return 'Cylinder Refill';
    }
    if (normalizedType == 'BOBTAIL_ORDER') {
      final orderType = (widget.order.orderType ?? '').toUpperCase();
      if (orderType == 'BOBTAIL_REFILL_SITE') {
        return 'Bobtail Refill';
      }
      if (orderType == 'BOBTAIL_PURCHASE') {
        return 'Bobtail Purchase';
      }
      return 'Bobtail Order';
    }
    return widget.order.type;
  }

  String _orderTitle() {
    if (widget.order.type.toUpperCase() == 'GAS_REFILL') {
      return widget.order.requestCode ?? 'Gas Refill #${widget.order.id}';
    }
    return widget.order.bobtail?.name ?? 'Bobtail #${widget.order.id}';
  }

  String _orderSubtitle() {
    if (widget.order.type.toUpperCase() == 'GAS_REFILL') {
      return widget.order.site?.name ?? 'Site';
    }
    if (widget.order.supplier?.name != null &&
        widget.order.supplier!.name.isNotEmpty) {
      return widget.order.supplier!.name;
    }
    return widget.order.site?.name ?? 'Supplier';
  }

  Future<void> _submit() async {
    final quantityText = _quantityController.text.trim();
    final invoiceText = _invoiceController.text.trim();

    if (quantityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter product quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final quantity = double.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (invoiceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter invoice number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: ${_orderTitle()}'),
            const SizedBox(height: 6),
            Text('Quantity: ${quantity.toStringAsFixed(2)} kg'),
            const SizedBox(height: 6),
            Text('Invoice: $invoiceText'),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await _warehouseService.recordPurchaseFromOrder(
        orderId: widget.order.id,
        quantity: quantity,
        invoiceNumber: invoiceText,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(response['message'] ?? 'Purchase recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to submit: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fulfill Order'),
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
                      Text(
                        _orderTitle(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _orderTypeLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _orderSubtitle(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
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
                        'Purchase Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _quantityController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Product Quantity (kg)',
                          hintText: 'e.g., 5000',
                          prefixIcon: const Icon(Icons.scale),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _invoiceController,
                        decoration: InputDecoration(
                          labelText: 'Invoice Number',
                          hintText: 'e.g., INV-2026-001',
                          prefixIcon: const Icon(Icons.receipt_long),
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
                    : const Text(
                        'Submit Purchase',
                        style: TextStyle(
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
