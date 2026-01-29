import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/bobtail_order.dart';
import '../../models/delivery_order.dart';
import '../../providers/auth_provider.dart';
import '../../services/bobtail_order_service.dart';
import '../../services/delivery_order_service.dart';
import '../../utils/colors.dart';
import 'bobtail_order_details_screen.dart';
import 'delivery_order_details_screen.dart';

class BobtailOrdersScreen extends StatefulWidget {
  const BobtailOrdersScreen({super.key});

  @override
  State<BobtailOrdersScreen> createState() => _BobtailOrdersScreenState();
}

class _BobtailOrdersScreenState extends State<BobtailOrdersScreen>
    with SingleTickerProviderStateMixin {
  final BobtailOrderService _service = BobtailOrderService();
  final DeliveryOrderService _deliveryOrderService = DeliveryOrderService();
  final Map<String, List<BobtailOrder>> _ordersByType = {
    'BOBTAIL_PURCHASE': [],
    'REFILL_SITE': [],
  };
  final Map<String, bool> _loadingByType = {
    'BOBTAIL_PURCHASE': true,
    'REFILL_SITE': true,
  };
  final Map<String, String?> _errorByType = {
    'BOBTAIL_PURCHASE': null,
    'REFILL_SITE': null,
  };
  final Map<String, List<DeliveryOrder>> _deliveriesByType = {
    'HOME': [],
    'COMMERCIAL': [],
  };
  final Map<String, bool> _loadingDeliveriesByType = {
    'HOME': true,
    'COMMERCIAL': true,
  };
  final Map<String, String?> _errorDeliveriesByType = {
    'HOME': null,
    'COMMERCIAL': null,
  };
  bool _showAllStatuses = false;

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }

  Future<void> _loadAllOrders() async {
    await Future.wait([
      _loadOrders('BOBTAIL_PURCHASE'),
      _loadOrders('REFILL_SITE'),
      _loadDeliveryOrders('HOME'),
      _loadDeliveryOrders('COMMERCIAL'),
    ]);
  }

  Future<void> _loadOrders(String orderType) async {
    setState(() {
      _loadingByType[orderType] = true;
      _errorByType[orderType] = null;
    });

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

      final orders = await _service.getBobtailOrders(
        token: token,
        status: _showAllStatuses ? null : 'PENDING',
        assignedDriverId: user.id,
        orderType: orderType,
      );

      setState(() {
        _ordersByType[orderType] = orders;
        _loadingByType[orderType] = false;
      });
    } catch (e) {
      setState(() {
        _errorByType[orderType] =
            e.toString().replaceAll('Exception: ', '');
        _loadingByType[orderType] = false;
      });
    }
  }

  Future<void> _loadDeliveryOrders(String type) async {
    setState(() {
      _loadingDeliveriesByType[type] = true;
      _errorDeliveriesByType[type] = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final status = _showAllStatuses ? null : 'PENDING';
      final orders = type == 'HOME'
          ? await _deliveryOrderService.getHomeDeliveryOrders(
              token: token,
              status: status,
            )
          : await _deliveryOrderService.getCommercialDeliveryOrders(
              token: token,
              status: status,
            );

      setState(() {
        _deliveriesByType[type] = orders;
        _loadingDeliveriesByType[type] = false;
      });
    } catch (e) {
      setState(() {
        _errorDeliveriesByType[type] =
            e.toString().replaceAll('Exception: ', '');
        _loadingDeliveriesByType[type] = false;
      });
    }
  }

  Future<void> _openDetails(BobtailOrder order) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BobtailOrderDetailsScreen(order: order),
      ),
    );

    if (result == true) {
      await _loadOrders(order.orderType);
    }
  }

  Future<void> _openDeliveryDetails(DeliveryOrder order) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeliveryOrderDetailsScreen(order: order),
      ),
    );

    if (result == true) {
      await _loadDeliveryOrders('HOME');
      await _loadDeliveryOrders('COMMERCIAL');
    }
  }

  Color _statusColor(String status) {
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

  String _formatDate(DateTime dateTime) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    return dateFormat.format(dateTime);
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList(String orderType) {
    final isLoading = _loadingByType[orderType] ?? false;
    final orders = _ordersByType[orderType] ?? [];

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _errorByType[orderType];
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: const TextStyle(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadOrders(orderType),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showAllStatuses
                  ? 'No bobtail orders found'
                  : 'No pending bobtail orders',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadOrders(orderType),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(orderType),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final statusColor = _statusColor(order.status);
          final subtitle = order.orderType == 'BOBTAIL_PURCHASE'
              ? order.supplier?.name ?? 'Supplier'
              : (order.gasOrder?.site?.name ??
                  order.gasOrder?.requestCode ??
                  'Site refill');
          final plateNumber = order.bobtail?.plateNumber?.trim().isNotEmpty == true
              ? order.bobtail!.plateNumber!
              : (order.bobtail?.name ?? 'Bobtail ${order.bobtailId}');
          final detailsLabel = order.orderType == 'BOBTAIL_PURCHASE'
              ? 'Supplier'
              : 'Gas Order';
          final quantityText = '${order.expectedKg} kg';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _openDetails(order),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.modernGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    plateNumber,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              label: detailsLabel,
                              value: subtitle,
                              icon: order.orderType == 'PURCHASE'
                                  ? Icons.business_rounded
                                  : Icons.local_gas_station_rounded,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              label: 'Quantity',
                              value: quantityText,
                              icon: Icons.scale_outlined,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              label: 'Created',
                              value: _formatDate(order.createdAt),
                              icon: Icons.access_time_rounded,
                            ),
                          ],
                        ),
                      ),
                      if (order.notes != null &&
                          order.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          order.notes!,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeliveryOrdersList(String type) {
    final isLoading = _loadingDeliveriesByType[type] ?? false;
    final orders = _deliveriesByType[type] ?? [];

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _errorDeliveriesByType[type];
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                style: const TextStyle(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadDeliveryOrders(type),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showAllStatuses
                  ? 'No delivery orders found'
                  : 'No pending delivery orders',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadDeliveryOrders(type),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDeliveryOrders(type),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final statusColor = _statusColor(order.status);
          final title = order.customer?.name ?? 'Delivery #${order.id}';
          final subtitle = order.location?.fullAddress ?? 'Delivery Location';
          final dateLabel = order.createdAt != null
              ? _formatDate(order.createdAt!)
              : 'N/A';
          final itemsCount = order.items.length.toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _openDeliveryDetails(order),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: statusColor.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$itemsCount item${itemsCount == '1' ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dateLabel,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.modernGradient,
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'BobTail',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadAllOrders,
                  tooltip: 'Refresh',
                ),
                IconButton(
                  icon: Icon(
                    _showAllStatuses
                        ? Icons.filter_alt_off_rounded
                        : Icons.filter_alt_rounded,
                  ),
                  tooltip:
                      _showAllStatuses ? 'Show pending only' : 'Show all',
                  onPressed: () async {
                    setState(() {
                      _showAllStatuses = !_showAllStatuses;
                    });
                    await _loadAllOrders();
                  },
                ),
              ],
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white,
                labelStyle: TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Purchase Orders'),
                  Tab(text: 'Site Refills'),
                  Tab(text: 'Deliveries'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildOrdersList('BOBTAIL_PURCHASE'),
                  _buildOrdersList('REFILL_SITE'),
                  DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          child: const TabBar(
                            labelColor: AppColors.primary,
                            unselectedLabelColor: Colors.black54,
                            indicatorColor: AppColors.primary,
                            tabs: [
                              Tab(text: 'Home'),
                              Tab(text: 'Commercial'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildDeliveryOrdersList('HOME'),
                              _buildDeliveryOrdersList('COMMERCIAL'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
