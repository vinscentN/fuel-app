import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/supplier.dart';
import '../../providers/auth_provider.dart';
import '../../services/warehouse_service.dart';
import '../../utils/colors.dart';

class RecordPurchaseScreen extends StatefulWidget {
  const RecordPurchaseScreen({super.key});

  @override
  State<RecordPurchaseScreen> createState() => _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends State<RecordPurchaseScreen> {
  final WarehouseService _warehouseService = WarehouseService();
  final TextEditingController _invoiceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitPriceController = TextEditingController();

  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  bool _isLoadingSuppliers = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isLoadingSuppliers = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final suppliers = await _warehouseService.getSuppliers(token);

      setState(() {
        _suppliers = suppliers;
        _isLoadingSuppliers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSuppliers = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load suppliers: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _submitPurchase() async {
    // Validate invoice number
    if (_invoiceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an invoice number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate supplier selection
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate quantity
    if (_quantityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate unit price
    if (_unitPriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter unit price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final unitPrice = double.tryParse(_unitPriceController.text.trim());
    if (unitPrice == null || unitPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid unit price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Purchase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice: ${_invoiceController.text.trim()}'),
              const SizedBox(height: 8),
              Text('Supplier: ${_selectedSupplier!.name}'),
              const SizedBox(height: 8),
              Text('Quantity: ${quantity.toStringAsFixed(2)} kg'),
              const SizedBox(height: 8),
              Text('Unit Price: \$${unitPrice.toStringAsFixed(2)}'),
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
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Submit the purchase
    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final user = authProvider.currentUser;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      if (user == null) {
        throw Exception('User information not available');
      }

      final response = await _warehouseService.recordPurchase(
        invoiceNumber: _invoiceController.text.trim(),
        supplierId: _selectedSupplier!.id,
        attendantId: user.id,
        quantity: quantity,
        unitPrice: unitPrice,
        token: token,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Purchase recorded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back with success result
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record purchase: ${e.toString().replaceAll('Exception: ', '')}'),
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
        title: const Text('Record Purchase'),
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
        child: _isLoadingSuppliers
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Invoice Number Card
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
                              'Invoice Number',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _invoiceController,
                              decoration: InputDecoration(
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

                    const SizedBox(height: 16),

                    // Supplier Selection Card
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
                              'Select Supplier',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<Supplier>(
                              value: _selectedSupplier,
                              decoration: InputDecoration(
                                hintText: 'Choose a supplier',
                                prefixIcon: const Icon(Icons.business),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              isExpanded: true,
                              items: _suppliers.map((supplier) {
                                return DropdownMenuItem<Supplier>(
                                  value: supplier,
                                  child: Text(
                                    supplier.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSupplier = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quantity and Price Card
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
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Quantity (kg)',
                                hintText: 'e.g., 1200.50',
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
                              controller: _unitPriceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              decoration: InputDecoration(
                                labelText: 'Unit Price (\$)',
                                hintText: 'e.g., 2.50',
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

                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitPurchase,
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
                              'Record Purchase',
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
