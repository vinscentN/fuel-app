import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/driver_order.dart';
import '../../models/warehouse_purchase.dart';
import '../../providers/auth_provider.dart';
import '../../services/warehouse_service.dart';
import '../../utils/colors.dart';
import 'fulfill_driver_order_screen.dart';

class WarehousePurchasesScreen extends StatefulWidget {
  const WarehousePurchasesScreen({super.key});

  @override
  State<WarehousePurchasesScreen> createState() => _WarehousePurchasesScreenState();
}

class _WarehousePurchasesScreenState extends State<WarehousePurchasesScreen> {
  final WarehouseService _warehouseService = WarehouseService();
  List<WarehousePurchase> _purchases = [];
  final Map<String, List<DriverOrder>> _ordersByType = {
    'GAS_REFILL': [],
    'BOBTAIL_ORDER': [],
  };
  double _balance = 0.0;
  bool _isLoading = true;
  bool _isLoadingOrders = true;
  String? _ordersError;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
    _loadDriverOrders();
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final result = await _warehouseService.getWarehousePurchases(
        token: token,
        limit: 20,
      );

      if (result['success'] == true) {
        setState(() {
          _purchases = result['purchases'] as List<WarehousePurchase>;

          // Parse balance safely
          final balanceValue = result['balance'];
          if (balanceValue is String) {
            _balance = double.tryParse(balanceValue) ?? 0.0;
          } else if (balanceValue is int) {
            _balance = balanceValue.toDouble();
          } else if (balanceValue is double) {
            _balance = balanceValue;
          } else {
            _balance = 0.0;
          }

          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load purchases');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load purchases: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadDriverOrders() async {
    setState(() {
      _isLoadingOrders = true;
      _ordersError = null;
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

      final result = await _warehouseService.getDriverOrders(
        driverId: user.id,
        token: token,
      );

      if (result['success'] == true) {
        final orders = result['orders'] as List<DriverOrder>;
        setState(() {
          _ordersByType['GAS_REFILL'] =
              orders.where((order) => order.type.toUpperCase() == 'GAS_REFILL').toList();
          _ordersByType['BOBTAIL_ORDER'] =
              orders.where((order) => order.type.toUpperCase() == 'BOBTAIL_ORDER').toList();
          _isLoadingOrders = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      setState(() {
        _isLoadingOrders = false;
        _ordersError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  bool _isFulfillable(DriverOrder order) {
    final status = order.status.toUpperCase();
    final type = order.type.toUpperCase();

    if (type == 'GAS_REFILL') {
      return status != 'DELIVERED';
    }

    if (type == 'BOBTAIL_ORDER') {
      return status != 'COMPLETED' && status != 'CANCELLED';
    }

    return true;
  }

  String _formatOrderTypeLabel(DriverOrder order) {
    final normalizedType = order.type.toUpperCase();
    if (normalizedType == 'GAS_REFILL') {
      return 'Cylinder Refill';
    }
    if (normalizedType == 'BOBTAIL_ORDER') {
      final orderType = (order.orderType ?? '').toUpperCase();
      if (orderType == 'BOBTAIL_REFILL_SITE') {
        return 'Bobtail Refill';
      }
      if (orderType == 'BOBTAIL_PURCHASE') {
        return 'Bobtail Purchase';
      }
      return 'Bobtail Order';
    }
    return order.type;
  }

  String _formatOrderTitle(DriverOrder order) {
    if (order.type.toUpperCase() == 'GAS_REFILL') {
      return order.requestCode ?? 'Gas Refill #${order.id}';
    }
    return order.bobtail?.name ?? 'Bobtail #${order.id}';
  }

  String _formatOrderSubtitle(DriverOrder order) {
    if (order.type.toUpperCase() == 'GAS_REFILL') {
      return order.site?.name ?? 'Site';
    }
    if (order.supplier?.name != null && order.supplier!.name.isNotEmpty) {
      return order.supplier!.name;
    }
    return order.site?.name ?? 'Supplier';
  }

  String _formatQuantity(DriverOrder order) {
    final quantity = order.productWeight ?? order.actualKg;
    if (quantity == null || quantity.isEmpty) return 'N/A';
    return '$quantity kg';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supplier Purchases'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(text: 'PENDING'),
              Tab(text: 'COMPLETED'),
            ],
          ),
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
          child: TabBarView(
            children: [
              _buildFulfillmentTab(),
              _buildProcessedTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFulfillmentTab() {
    return DefaultTabController(
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
                Tab(text: 'Cylinder Refills'),
                Tab(text: 'Bobtail Refills'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrdersList('GAS_REFILL'),
                _buildOrdersList('BOBTAIL_ORDER'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String orderType) {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ordersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _ordersError!,
                style: const TextStyle(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDriverOrders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final orders = (_ordersByType[orderType] ?? [])
        .where(_isFulfillable)
        .toList();

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
              'No orders to fulfill',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDriverOrders,
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
      onRefresh: _loadDriverOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final statusColor = _statusColor(order.status);
          final createdAt = order.createdAt ?? order.requestCreatedAt;
          final dateLabel = createdAt != null ? _formatDate(createdAt) : 'N/A';

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
                onTap: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FulfillDriverOrderScreen(order: order),
                    ),
                  );

                  if (result == true && mounted) {
                    await _loadDriverOrders();
                    await _loadPurchases();
                  }
                },
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
                              _formatOrderTitle(order),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _formatOrderTypeLabel(order),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatOrderSubtitle(order),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.scale_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatQuantity(order),
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

  Widget _buildProcessedTab() {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _purchases.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No purchases recorded yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPurchases,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _purchases.length,
                        itemBuilder: (context, index) {
                          return _buildPurchaseCard(_purchases[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'IN_TRANSIT':
        return Colors.blue;
      case 'COMPLETED':
      case 'DELIVERED':
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

  Widget _buildPurchaseCard(WarehousePurchase purchase) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final createdDate = DateTime.parse(purchase.createdAt);

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    purchase.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: purchase.status == 'IN'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    purchase.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: purchase.status == 'IN'
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            if (purchase.description != null) ...[
              const SizedBox(height: 8),
              Text(
                purchase.description!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Quantity',
                    '${purchase.quantity} kg',
                    Icons.scale_outlined,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Unit Price',
                    '\$${purchase.unitPrice}',
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Total',
                    '\$${purchase.totalAmount.toStringAsFixed(2)}',
                    Icons.receipt_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(createdDate),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
