import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/warehouse_purchase.dart';
import '../../providers/auth_provider.dart';
import '../../services/warehouse_service.dart';
import '../../utils/colors.dart';
import 'record_purchase_screen.dart';

class WarehousePurchasesScreen extends StatefulWidget {
  const WarehousePurchasesScreen({super.key});

  @override
  State<WarehousePurchasesScreen> createState() => _WarehousePurchasesScreenState();
}

class _WarehousePurchasesScreenState extends State<WarehousePurchasesScreen> {
  final WarehouseService _warehouseService = WarehouseService();
  List<WarehousePurchase> _purchases = [];
  double _balance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Purchases'),
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
        child: Column(
          children: [
            // Balance Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Balance',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                    ],
                  ),
                  Text(
                    '${_balance.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Purchases List
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RecordPurchaseScreen(),
            ),
          );

          if (result == true) {
            _loadPurchases();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Purchase',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
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
