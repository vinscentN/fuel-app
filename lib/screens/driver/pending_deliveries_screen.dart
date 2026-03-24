import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gas_order.dart';
import '../../providers/auth_provider.dart';
import '../../services/gas_order_service.dart';
import '../../utils/colors.dart';
import 'delivery_qr_code_screen.dart';
import 'driver_ui.dart';

class PendingDeliveriesScreen extends StatefulWidget {
  final String? deliveryType;

  const PendingDeliveriesScreen({Key? key, this.deliveryType}) : super(key: key);

  @override
  State<PendingDeliveriesScreen> createState() => _PendingDeliveriesScreenState();
}

class _PendingDeliveriesScreenState extends State<PendingDeliveriesScreen> {
  final GasOrderService _gasOrderService = GasOrderService();

  List<PendingGasOrder> _filteredDeliveries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingDeliveries();
  }

  Future<void> _loadPendingDeliveries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final orders = await _gasOrderService.getPendingDeliveries(token);

      final filtered = widget.deliveryType != null
          ? orders
              .where((o) =>
                  (o.customerType ?? '').toUpperCase() ==
                  widget.deliveryType!.toUpperCase())
              .toList()
          : orders;

      setState(() {
        _filteredDeliveries = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _viewQRCode(PendingGasOrder order) {
    // Navigate to delivery QR code screen
    final deliveryCode = order.deliveryCode ?? order.requestCode;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryQRCodeScreen(deliveryCode: deliveryCode),
      ),
    );
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
      backgroundColor: driverBg,
      appBar: buildDriverAppBar(
        context,
        title: widget.deliveryType != null
            ? '${widget.deliveryType} Deliveries'
            : 'Deliveries',
        subtitle: 'Pending deliveries awaiting action',
        icon: Icons.local_shipping_outlined,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: _loadPendingDeliveries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? DriverErrorState(
                  message: _error!,
                  onRetry: _loadPendingDeliveries,
                )
              : _filteredDeliveries.isEmpty
                  ? DriverEmptyState(
                      icon: Icons.local_shipping_outlined,
                      message: 'No pending deliveries',
                      actionText: 'Refresh',
                      onAction: _loadPendingDeliveries,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPendingDeliveries,
                      color: driverNavy,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                        itemCount: _filteredDeliveries.length,
                        itemBuilder: (context, index) {
                          final order = _filteredDeliveries[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE8EDF5)),
                            ),
                            child: InkWell(
                              onTap: () => _viewQRCode(order),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            order.requestCode,
                                            style: const TextStyle(
                                              color: driverNavy,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(order.status).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _getStatusColor(order.status),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            order.status,
                                            style: TextStyle(
                                              color: _getStatusColor(order.status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      order.description,
                                      style: const TextStyle(
                                        color: driverMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                          Text(
                                            order.site.name,
                                            style: const TextStyle(
                                              color: driverMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.propane_tank,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${order.tanksCount} cylinder${order.tanksCount != 1 ? 's' : ''}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: Colors.grey[600],
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            order.createdBy,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatDateTime(order.createdAt),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (order.itemsPreview.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Divider(color: Colors.grey[300]),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: order.itemsPreview.map((item) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: Text(
                                              '${item.trackingCode} (${item.cylinderType})',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _viewQRCode(order),
                                        icon: const Icon(Icons.qr_code, size: 20),
                                        label: const Text('View QR Code'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
