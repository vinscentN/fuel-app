import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_order.dart';
import '../../providers/auth_provider.dart';
import '../../services/delivery_order_service.dart';
import '../../utils/colors.dart';
import 'delivery_order_details_screen.dart';
import 'driver_ui.dart';

/// Delivery type constants
class DeliveryType {
  static const String retail = 'RETAIL';
  static const String home = 'HOME';
  static const String commercial = 'COMMERCIAL';
}

class DeliveryOrdersScreen extends StatefulWidget {
  final String deliveryType; // DeliveryType.retail / home / commercial

  const DeliveryOrdersScreen({super.key, required this.deliveryType});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> {
  final DeliveryOrderService _service = DeliveryOrderService();

  List<DeliveryOrder> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token =
          Provider.of<AuthProvider>(context, listen: false).token ?? '';

      List<DeliveryOrder> orders;
      switch (widget.deliveryType) {
        case DeliveryType.home:
          orders = await _service.getHomeDeliveries(token: token);
          break;
        case DeliveryType.commercial:
          orders = await _service.getCommercialDeliveries(token: token);
          break;
        case DeliveryType.retail:
        default:
          orders = await _service.getRetailDeliveries(token: token);
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Color get _typeColor {
    switch (widget.deliveryType) {
      case DeliveryType.home:
        return const Color(0xFF0F274F);
      case DeliveryType.commercial:
        return const Color(0xFFC96B00);
      default:
        return const Color(0xFF005F8F);
    }
  }

  IconData get _typeIcon {
    switch (widget.deliveryType) {
      case DeliveryType.home:
        return Icons.home_outlined;
      case DeliveryType.commercial:
        return Icons.business_outlined;
      default:
        return Icons.storefront_outlined;
    }
  }

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

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildDriverAppBar(
        context,
        title: '${widget.deliveryType} Deliveries',
        subtitle: 'Assigned delivery orders',
        icon: _typeIcon,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      backgroundColor: driverBg,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _typeColor),
      );
    }

    if (_error != null) {
      return DriverErrorState(message: _error!, onRetry: _load);
    }

    if (_orders.isEmpty) {
      return DriverEmptyState(
        icon: _typeIcon,
        message: 'No ${widget.deliveryType.toLowerCase()} deliveries',
        actionText: 'Refresh',
        onAction: _load,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: driverNavy,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(DeliveryOrder order) {
    final statusColor = _statusColor(order.status);
    final isRetail = widget.deliveryType == DeliveryType.retail;

    if (isRetail) return _buildRetailCard(order, statusColor);

    // Clean white card with navy top line
    final totalKg = order.totalKgsLoaded;
    final isHome = widget.deliveryType == DeliveryType.home;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => DeliveryOrderDetailsScreen(order: order),
              ),
            );
            if (updated == true) _load();
          },
          child: Column(
            children: [
              // Navy top line
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: _typeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Header row
                    Row(
                      children: [
                        Icon(_typeIcon, color: _typeColor, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.recipientName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Order #${order.id}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(0xFF5B6B84),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.status.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.deliveryAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF4B5565),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.propane_tank,
                                    size: 14, color: _typeColor),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${order.cylinderCount}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _typeColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.scale,
                                    size: 14, color: const Color(0xFF445166)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${totalKg.toStringAsFixed(1)}kg',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF445166),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isHome) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '\$${order.totalValue.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildRetailCard(DeliveryOrder order, Color statusColor) {
    final count = order.cylinderCount;
    final totalKg = order.hasBobtail
        ? (order.expectedKg ?? order.totalKg ?? order.totalKgsLoaded)
        : order.totalKgsLoaded;
    final date = (order.expectedDeliveryDate ?? '').split(RegExp(r'[ T]')).first;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => DeliveryOrderDetailsScreen(order: order),
              ),
            );
            if (updated == true) _load();
          },
          child: Container(
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _typeColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    order.recipientName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (order.hasBobtail) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9800),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_shipping_outlined,
                                            size: 10, color: Colors.white),
                                        SizedBox(width: 3),
                                        Text(
                                          'BOBTAIL',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 11, color: Colors.grey[400]),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    order.deliveryAddress,
                                    style: TextStyle(
                                        fontSize: 11, color: const Color(0xFF4B5565)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (date.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined,
                                      size: 11, color: Colors.grey[400]),
                                  const SizedBox(width: 3),
                                  Text(
                                    date,
                                    style: TextStyle(
                                        fontSize: 11, color: const Color(0xFF5B6B84)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _typeColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.propane_tank_outlined,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${totalKg.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element - kept for potential future use
  Widget _statChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
