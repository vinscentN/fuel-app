import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/gas_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/gas_order_service.dart';
import '../../utils/colors.dart';

class CreateDeliveryScreen extends StatefulWidget {
  final PendingGasOrder order;

  const CreateDeliveryScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  final GasOrderService _gasOrderService = GasOrderService();
  final TextEditingController _invoiceController = TextEditingController();
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, bool> _selectedTanks = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and selection for each tank
    for (var item in widget.order.itemsPreview) {
      _weightControllers[item.itemId] = TextEditingController();
      _selectedTanks[item.itemId] = true; // Select all by default
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitDelivery() async {
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

    // Get selected tanks
    final selectedItems = widget.order.itemsPreview.where((item) {
      return _selectedTanks[item.itemId] == true;
    }).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one cylinder'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate weights
    final tanks = <Map<String, dynamic>>[];
    for (var item in selectedItems) {
      final weightText = _weightControllers[item.itemId]?.text.trim() ?? '';

      if (weightText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter weight for ${item.tankName}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final weight = double.tryParse(weightText);
      if (weight == null || weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid weight for ${item.tankName}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      tanks.add({
        'item_id': item.itemId,
        'after_refill_weight': weight,
      });
    }

    // Confirm submission
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: Text(
          'Create delivery for ${tanks.length} cylinder${tanks.length != 1 ? 's' : ''}?',
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
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final user = authProvider.currentUser;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      if (user == null) {
        throw Exception('User not found');
      }

      await _gasOrderService.createDelivery(
        orderId: widget.order.id,
        driverAttendantId: user.id,
        invoiceNumber: _invoiceController.text.trim(),
        tanks: tanks,
        token: token,
      );

      if (mounted) {
        // Fetch the updated order to get the delivery code
        final updatedOrder = await _gasOrderService.getOrderByRequestCode(
          widget.order.requestCode,
          token,
        );

        // Print delivery receipts (driver copy and attendant copy)
        await _printDeliveryReceipts(
          authProvider,
          user,
          updatedOrder,
          _invoiceController.text.trim(),
          selectedItems,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Delivery created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back to driver menu
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _printDeliveryReceipts(
    AuthProvider authProvider,
    dynamic user,
    GasOrder order,
    String invoiceNumber,
    List<TankPreview> selectedItems,
  ) async {
    try {
      final posProvider = Provider.of<PosProvider>(context, listen: false);
      final now = DateTime.now();
      final dateFormatter = DateFormat('dd/MM/yyyy');
      final timeFormatter = DateFormat('HH:mm:ss');

      // Format cylinder details with weights
      final cylinderDetails = selectedItems.map((item) {
        final weightController = _weightControllers[item.itemId];
        final afterRefillWeight = weightController?.text.trim() ?? 'N/A';

        return '${item.tankName} (${item.trackingCode})\n'
            'Type: ${item.cylinderType}\n'
            'Capacity: ${item.capacity} kg\n'
            'Bottom Weight: ${item.bottomWeight} kg\n'
            'After Refill: $afterRefillWeight kg';
      }).join('\n\n');

      final deliveryCode = order.deliveryCode ?? 'N/A';

      // Print delivery receipt (printer will handle copies)
      await posProvider.printDeliveryReceipt(
        requestCode: order.requestCode,
        deliveryCode: deliveryCode,
        invoiceNumber: invoiceNumber,
        stationName: authProvider.serviceStationName ?? 'N/A',
        address: authProvider.serviceStationAddress ?? '',
        phone: authProvider.serviceStationPhone ?? '',
        date: dateFormatter.format(now),
        time: timeFormatter.format(now),
        driverName: user.firstName != null && user.lastName != null
            ? '${user.firstName} ${user.lastName}'
            : user.username,
        cylinderCount: selectedItems.length.toString(),
        cylinderDetails: cylinderDetails,
        description: order.description,
        siteName: order.site.name,
        siteCode: order.site.stationCode ?? 'N/A',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery receipt printed'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Print error but don't block the flow
      debugPrint('Delivery receipt printing failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Delivery'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info card
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
                      'Request Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Request Code', widget.order.requestCode),
                    _buildInfoRow('Site', widget.order.site.name),
                    _buildInfoRow('Description', widget.order.description),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Invoice number input
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
                        hintText: 'Enter invoice number',
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

            // Cylinders selection
            const Text(
              'Select Cylinders & Enter Weights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ...widget.order.itemsPreview.map((item) {
              final isSelected = _selectedTanks[item.itemId] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                _selectedTanks[item.itemId] = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.tankName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Type: ${item.cylinderType}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Tracking: ${item.trackingCode}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Capacity',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${item.capacity} kg',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bottom Weight',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${item.bottomWeight} kg',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _weightControllers[item.itemId],
                          decoration: InputDecoration(
                            labelText: 'After Refill Weight (kg)',
                            hintText: 'Enter weight after refilling',
                            prefixIcon: const Icon(Icons.scale),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitDelivery,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 24),
                label: Text(
                  _isSubmitting ? 'Creating...' : 'Create Delivery',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
