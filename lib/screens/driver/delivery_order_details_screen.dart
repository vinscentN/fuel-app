import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/delivery_order_service.dart';
import '../../utils/colors.dart';

class DeliveryOrderDetailsScreen extends StatefulWidget {
  final DeliveryOrder order;

  const DeliveryOrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<DeliveryOrderDetailsScreen> createState() =>
      _DeliveryOrderDetailsScreenState();
}

class _DeliveryOrderDetailsScreenState
    extends State<DeliveryOrderDetailsScreen> {
  final DeliveryOrderService _service = DeliveryOrderService();
  bool _isSubmitting = false;

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'DISPATCHED':
        return Colors.indigo;
      case 'IN_TRANSIT':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    return dateFormat.format(dateTime);
  }

  Future<void> _confirmDelivery() async {
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

      final updatedOrder = await _service.updateDeliveryStatus(
        deliveryOrderId: widget.order.id,
        status: 'DELIVERED',
        assignedDriverId: user.id,
        token: token,
      );

      if (mounted) {
        await _printReceipt(updatedOrder);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _printReceipt(DeliveryOrder order) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final posProvider = Provider.of<PosProvider>(context, listen: false);
      final now = DateTime.now();
      final dateFormatter = DateFormat('dd/MM/yyyy');
      final timeFormatter = DateFormat('HH:mm:ss');

      final customerName = order.customer?.name ?? 'Customer';
      final customerPhone = order.customer?.phone ?? '';
      final address = order.location?.fullAddress ?? '';
      final items = order.items
          .map((item) {
            final name = item.product?.name ?? 'Item';
            final quantity = item.quantity;
            final unit = item.product?.unitOfMeasure ?? '';
            return '$name: $quantity $unit';
          })
          .join('\n');

      await posProvider.printDeliveryReceipt(
        requestCode: 'ORDER-${order.id}',
        deliveryCode: 'DELIVERY-${order.id}',
        invoiceNumber: 'N/A',
        stationName: customerName,
        address: address,
        phone: customerPhone,
        date: dateFormatter.format(now),
        time: timeFormatter.format(now),
        driverName: authProvider.currentUser?.fullName ?? 'N/A',
        cylinderCount: order.items.length.toString(),
        cylinderDetails: items,
        description: order.notes ?? '',
        siteName: customerName,
        siteCode: order.location?.label ?? 'N/A',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(widget.order.status);
    final customerName = widget.order.customer?.name ?? 'Customer';
    final address = widget.order.location?.fullAddress ?? 'N/A';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Delivery Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: statusColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.order.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Customer', customerName),
                    _buildInfoRow('Address', address),
                    _buildInfoRow('Order Type', widget.order.orderType),
                    _buildInfoRow('Created At', _formatDate(widget.order.createdAt)),
                    if (widget.order.expectedDeliveryDate != null)
                      _buildInfoRow(
                        'Expected Date',
                        widget.order.expectedDeliveryDate!,
                      ),
                    if (widget.order.expectedDeliveryTime != null)
                      _buildInfoRow(
                        'Expected Time',
                        widget.order.expectedDeliveryTime!,
                      ),
                    if (widget.order.notes != null &&
                        widget.order.notes!.trim().isNotEmpty)
                      _buildInfoRow('Notes', widget.order.notes!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.order.items.map((item) {
              final name = item.product?.name ?? 'Item';
              final quantity = item.quantity;
              final unit = item.product?.unitOfMeasure ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.local_shipping_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$quantity $unit',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _confirmDelivery,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: Text(
                  _isSubmitting ? 'Confirming...' : 'Confirm Delivery',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
            width: 120,
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
