import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gas_order.dart';
import '../../providers/auth_provider.dart';
import '../../services/gas_order_service.dart';
import '../../utils/colors.dart';
import '../gas_order/qr_code_screen.dart';
import 'pending_fill_request_details_screen.dart';

class PendingFillRequestsScreen extends StatefulWidget {
  const PendingFillRequestsScreen({super.key});

  @override
  State<PendingFillRequestsScreen> createState() =>
      _PendingFillRequestsScreenState();
}

class _PendingFillRequestsScreenState
    extends State<PendingFillRequestsScreen> {
  final GasOrderService _gasOrderService = GasOrderService();
  List<PendingGasOrder> _pendingOrders = [];
  bool _isLoading = true;
  String? _error;
  bool _isGroupedView = true;

  @override
  void initState() {
    super.initState();
    _loadPendingOrders();
  }

  Future<void> _loadPendingOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final user = authProvider.currentUser;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      if (user == null || user.serviceStationId == 0) {
        throw Exception('Service station not found');
      }

      final orders = await _gasOrderService.getPendingOrders(
          user.serviceStationId, token);

      setState(() {
        _pendingOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Group orders by site
  Map<String, List<PendingGasOrder>> _groupOrdersBySite() {
    final Map<String, List<PendingGasOrder>> grouped = {};

    for (var order in _pendingOrders) {
      final siteKey = '${order.site.name}_${order.site.id}';
      if (!grouped.containsKey(siteKey)) {
        grouped[siteKey] = [];
      }
      grouped[siteKey]!.add(order);
    }

    return grouped;
  }

  void _viewDetails(PendingGasOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PendingFillRequestDetailsScreen(
          requestCode: order.requestCode,
        ),
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

  Widget _buildGroupedView() {
    final groupedOrders = _groupOrdersBySite();
    final sortedSites = groupedOrders.keys.toList()
      ..sort((a, b) {
        final ordersA = groupedOrders[a]!;
        final ordersB = groupedOrders[b]!;
        return ordersB.length.compareTo(ordersA.length);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSites.length,
      itemBuilder: (context, index) {
        final siteKey = sortedSites[index];
        final orders = groupedOrders[siteKey]!;
        final site = orders.first.site;

        final totalCylinders = orders.fold<int>(
          0,
              (sum, order) => sum + order.tanksCount,
        );

        return _buildSiteCard(site, orders, totalCylinders);
      },
    );
  }

  Widget _buildSiteCard(
      dynamic site,
      List<PendingGasOrder> orders,
      int totalCylinders,
      ) {
    final siteDetails = [
      if (site.stationCode != null && site.stationCode!.isNotEmpty)
        'Code: ${site.stationCode}',
      if (site.address != null && site.address!.isNotEmpty) site.address!,
      if (site.city != null && site.city!.isNotEmpty) site.city!,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Site Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.modernGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (siteDetails.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              siteDetails,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSiteStatChip(
                      icon: Icons.receipt_long_rounded,
                      label: '${orders.length} Request${orders.length != 1 ? 's' : ''}',
                    ),
                    const SizedBox(width: 12),
                    _buildSiteStatChip(
                      icon: Icons.propane_tank,
                      label: '$totalCylinders Cylinder${totalCylinders != 1 ? 's' : ''}',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Orders List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey[200],
              height: 24,
            ),
            itemBuilder: (context, index) {
              return _buildOrderItem(orders[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSiteStatChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(PendingGasOrder order) {
    return InkWell(
      onTap: () => _viewDetails(order),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.receipt_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.requestCode,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _getStatusColor(order.status).withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.description,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.propane_tank, color: Colors.grey[600], size: 14),
                const SizedBox(width: 4),
                Text(
                  '${order.tanksCount} cylinder${order.tanksCount != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(Icons.person, color: Colors.grey[600], size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.createdBy,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDateTime(order.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (order.itemsPreview.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: order.itemsPreview.take(3).map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      '${item.trackingCode} • ${item.cylinderType}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList()
                  ..addAll(order.itemsPreview.length > 3
                      ? [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${order.itemsPreview.length - 3} more',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ]
                      : []),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingOrders.length,
      itemBuilder: (context, index) {
        final order = _pendingOrders[index];
        final site = order.site;
        final siteDetails = [
          if (site.stationCode != null && site.stationCode!.isNotEmpty)
            'Code: ${site.stationCode}',
          if (site.address != null && site.address!.isNotEmpty) site.address!,
          if (site.city != null && site.city!.isNotEmpty) site.city!,
        ].join(' • ');

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
              onTap: () => _viewDetails(order),
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
                                  Icons.receipt_long_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  order.requestCode,
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
                            color:
                            _getStatusColor(order.status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                              _getStatusColor(order.status).withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            order.status,
                            style: TextStyle(
                              color: _getStatusColor(order.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      order.description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: AppColors.primary, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  site.name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (siteDetails.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 22),
                              child: Text(
                                siteDetails,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
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
                        const SizedBox(width: 16),
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
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.trackingCode,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.cylinderType} • ${item.capacity}kg',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Bottom: ${item.bottomWeight}kg',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 11,
                                  ),
                                ),
                                if (item.tankName.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.tankName,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Text(
                        'No cylinders added yet.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.modernGradient,
          ),
          child: AppBar(
            title: const Text(
              'Pending Fill Requests',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _isGroupedView ? Icons.list_rounded : Icons.grid_view_rounded,
                ),
                onPressed: () {
                  setState(() {
                    _isGroupedView = !_isGroupedView;
                  });
                },
                tooltip: _isGroupedView ? 'List View' : 'Group by Site',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadPendingOrders,
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPendingOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _pendingOrders.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No pending requests',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.modernGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loadPendingOrders,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Refresh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadPendingOrders,
        color: AppColors.primary,
        child: _isGroupedView
            ? _buildGroupedView()
            : _buildListView(),
      ),
    );
  }
}