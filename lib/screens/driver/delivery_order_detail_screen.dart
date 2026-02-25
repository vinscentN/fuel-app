import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_order.dart';
import '../../providers/auth_provider.dart';
import '../../services/delivery_order_service.dart';
import '../../utils/colors.dart';

class DeliveryOrderDetailScreen extends StatefulWidget {
  final DeliveryOrder order;

  const DeliveryOrderDetailScreen({super.key, required this.order});

  @override
  State<DeliveryOrderDetailScreen> createState() =>
      _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState
    extends State<DeliveryOrderDetailScreen> {
  final DeliveryOrderService _service = DeliveryOrderService();
  bool _isUpdating = false;
  late DeliveryOrder _order;

  // Status transitions available to driver
  static const List<String> _statusOptions = [
    'PENDING',
    'PROCESSING',
    'DISPATCHED',
    'IN_TRANSIT',
    'DELIVERED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'DISPATCHED':
        return const Color(0xFF6366F1);
      case 'IN_TRANSIT':
        return const Color(0xFF0EA5E9);
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color get _typeColor {
    switch (_order.orderType.toUpperCase()) {
      case 'DELIVERY_HOME':
        return const Color(0xFF8B5CF6);
      case 'DELIVERY_COMMERCIAL':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _updateStatus(String newStatus) async {
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to identify driver')),
      );
      return;
    }

    // Confirm
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Status'),
        content: Text(
            'Change status to "${newStatus.replaceAll('_', ' ')}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _typeColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUpdating = true);

    try {
      final updated = await _service.updateStatus(
        deliveryOrderId: _order.id,
        status: newStatus,
        assignedDriverId: userId,
        token: token,
      );

      setState(() {
        _order = updated;
        _isUpdating = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Status updated to ${newStatus.replaceAll('_', ' ')}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // signal list to refresh
    } catch (e) {
      setState(() => _isUpdating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration:
              const BoxDecoration(gradient: AppColors.modernGradient),
          child: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Order #${_order.id}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(),
                const SizedBox(height: 16),
                _buildInfoCard(),
                const SizedBox(height: 16),
                _buildItemsCard(),
                if (_order.benchmark != null) ...[
                  const SizedBox(height: 16),
                  _buildBenchmarkCard(),
                ],
              ],
            ),
          ),
          // Update status button at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: _isUpdating
                  ? Center(
                      child: CircularProgressIndicator(color: _typeColor))
                  : ElevatedButton.icon(
                      onPressed: _showStatusPicker,
                      icon: const Icon(Icons.update_rounded),
                      label: const Text('UPDATE STATUS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _typeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Sections
  // -------------------------------------------------------------------------

  Widget _buildStatusBanner() {
    final color = _statusColor(_order.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            _order.status.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            _order.typeLabel,
            style: TextStyle(
              fontSize: 13,
              color: _typeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Delivery Info'),
          const SizedBox(height: 14),
          _infoRow(Icons.person_outline, 'Recipient', _order.recipientName),
          if (_order.customer?.phone != null)
            _infoRow(
                Icons.phone_outlined, 'Phone', _order.customer!.phone!),
          if (_order.customer?.customerType != null)
            _infoRow(Icons.badge_outlined, 'Customer Type',
                _order.customer!.customerType!),
          _infoRow(
              Icons.location_on_outlined, 'Address', _order.deliveryAddress),
          if (_order.expectedDeliveryDate != null)
            _infoRow(Icons.calendar_today_outlined, 'Expected Date',
                _order.expectedDeliveryDate!),
          if (_order.expectedDeliveryTime != null)
            _infoRow(Icons.schedule_outlined, 'Expected Time',
                _order.expectedDeliveryTime!),
          _infoRow(Icons.access_time_outlined, 'Created', _order.createdAt),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Items (${_order.items.length})'),
          const SizedBox(height: 14),
          ..._order.items.map((item) => _buildItemRow(item)),
          Divider(color: Colors.grey[100]),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '\$${_order.totalValue.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _typeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(DeliveryOrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.propane_tank_outlined,
                color: _typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.name ?? 'Product #${item.productId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty: ${item.quantity.toStringAsFixed(0)}  ×  \$${item.unitPrice.toStringAsFixed(2)}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _typeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkCard() {
    final b = _order.benchmark!;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Benchmark'),
          const SizedBox(height: 14),
          _infoRow(Icons.flag_outlined, 'Name', b.name),
          if (b.latitude != null && b.longitude != null)
            _infoRow(Icons.my_location_outlined, 'Coordinates',
                '${b.latitude}, ${b.longitude}'),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Status picker bottom sheet
  // -------------------------------------------------------------------------

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select New Status',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ..._statusOptions
                  .where((s) => s != _order.status)
                  .map((status) {
                final color = _statusColor(status);
                return ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  title: Text(
                    status.replaceAll('_', ' '),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _updateStatus(status);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Reusable widgets
  // -------------------------------------------------------------------------

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
