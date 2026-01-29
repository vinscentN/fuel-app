import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/gas_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/gas_order_service.dart';

class ReceiveDeliveryScreen extends StatefulWidget {
  final GasOrder order;

  const ReceiveDeliveryScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<ReceiveDeliveryScreen> createState() => _ReceiveDeliveryScreenState();
}

class _ReceiveDeliveryScreenState extends State<ReceiveDeliveryScreen> {
  final GasOrderService _gasOrderService = GasOrderService();
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, bool> _selectedTanks = {};

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and selection for each tank
    for (var item in widget.order.items) {
      _weightControllers[item.id] = TextEditingController();
      _selectedTanks[item.id] = true; // Select all by default
    }
  }

  @override
  void dispose() {
    for (var controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReceive() async {
    // Get selected tanks
    final selectedItems = widget.order.items.where((item) {
      return _selectedTanks[item.id] == true;
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
      final weightText = _weightControllers[item.id]?.text.trim() ?? '';

      if (weightText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter received weight for ${item.gasTank.trackingCode ?? item.gasTank.name}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final weight = double.tryParse(weightText);
      if (weight == null || weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid weight for ${item.gasTank.trackingCode ?? item.gasTank.name}'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final cylinderId = item.gasTankId != 0 ? item.gasTankId : item.gasTank.id;

      tanks.add({
        'item_id': item.id,
        'cylinder_id': cylinderId,
        'received_weight': weight,
      });
    }

    // Confirm submission
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Receipt'),
        content: Text(
          'Confirm receipt of ${tanks.length} cylinder${tanks.length != 1 ? 's' : ''}?',
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
              backgroundColor: Colors.blue,
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

      if (widget.order.deliveryCode == null) {
        throw Exception('Delivery code not found');
      }

      await _gasOrderService.receiveDelivery(
        deliveryCode: widget.order.deliveryCode!,
        receivedByAttendantId: user.id,
        tanks: tanks,
        token: token,
      );

      if (mounted) {
        // Print delivery receipt
        await _printDeliveryReceipt(authProvider, user, tanks);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Delivery received successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back to landing menu
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

  Future<void> _printDeliveryReceipt(
    AuthProvider authProvider,
    dynamic user,
    List<Map<String, dynamic>> receivedTanks,
  ) async {
    try {
      final posProvider = Provider.of<PosProvider>(context, listen: false);
      final now = DateTime.now();
      final dateFormatter = DateFormat('dd/MM/yyyy');
      final timeFormatter = DateFormat('HH:mm:ss');

      // Get selected items with their received weights
      final selectedItems = widget.order.items.where((item) {
        return receivedTanks.any((tank) => tank['item_id'] == item.id);
      }).toList();

      // Format cylinder details with received weights
      final cylinderDetails = selectedItems.map((item) {
        final receivedTank = receivedTanks.firstWhere(
          (tank) => tank['item_id'] == item.id,
        );
        final receivedWeight = receivedTank['received_weight'];
        final trackingCode = item.gasTank.trackingCode ?? item.gasTank.name;
        final cylinderType = item.gasTank.cylinderType?.name ?? 'N/A';

        return '$trackingCode ($cylinderType)\n'
            'Capacity: ${item.gasTank.capacity.toStringAsFixed(0)} kg\n'
            'After Refill: ${item.afterRefillWeight} kg\n'
            'Received Weight: $receivedWeight kg';
      }).join('\n\n');

      final deliveryCode = widget.order.deliveryCode ?? 'N/A';
      final driverName = widget.order.deliveryDoneBy ?? 'N/A';
      final attendantName = user.fullName;

      // Print delivery receipt
      await posProvider.printDeliveryReceipt(
        requestCode: widget.order.requestCode,
        deliveryCode: deliveryCode,
        invoiceNumber: widget.order.invoiceNumber ?? 'N/A',
        stationName: authProvider.serviceStationName ?? 'N/A',
        address: authProvider.serviceStationAddress ?? '',
        phone: authProvider.serviceStationPhone ?? '',
        date: dateFormatter.format(now),
        time: timeFormatter.format(now),
        driverName: driverName,
        cylinderCount: selectedItems.length.toString(),
        cylinderDetails: cylinderDetails,
        description: 'Received by: $attendantName\n${widget.order.description}',
        siteName: widget.order.site.name,
        siteCode: widget.order.site.stationCode ?? 'N/A',
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'IN_TRANSIT':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Receive Delivery'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery info card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.order.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(widget.order.status),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.order.status,
                            style: TextStyle(
                              color: _getStatusColor(widget.order.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Request Code', widget.order.requestCode),
                    if (widget.order.deliveryCode != null)
                      _buildInfoRow('Delivery Code', widget.order.deliveryCode!),
                    _buildInfoRow('Site', widget.order.site.name),
                    _buildInfoRow('Description', widget.order.description),
                    if (widget.order.invoiceNumber != null)
                      _buildInfoRow('Invoice', widget.order.invoiceNumber!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Cylinders selection
            const Text(
              'Select Cylinders & Enter Received Weights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            ...widget.order.items.map((item) {
              final isSelected = _selectedTanks[item.id] ?? false;

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
                                _selectedTanks[item.id] = value ?? false;
                              });
                            },
                            activeColor: Colors.blue,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.gasTank.trackingCode ?? item.gasTank.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Type: ${item.gasTank.cylinderType?.name ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  'Tracking: ${item.gasTank.trackingCode}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
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
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    '${item.gasTank.capacity.toStringAsFixed(0)} ${item.gasTank.unit}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
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
                                    'After Refill',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    '${item.afterRefillWeight} ${item.gasTank.unit}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _weightControllers[item.id],
                          decoration: InputDecoration(
                            labelText: 'Received Weight (kg)',
                            hintText: 'Enter actual received weight',
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
                onPressed: _isSubmitting ? null : _submitReceive,
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
                  _isSubmitting ? 'Processing...' : 'Confirm Receipt',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
