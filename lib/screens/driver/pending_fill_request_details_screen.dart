import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gas_order.dart';
import '../../providers/auth_provider.dart';
import '../../services/gas_order_service.dart';
import '../../utils/colors.dart';

class PendingFillRequestDetailsScreen extends StatefulWidget {
  final String requestCode;

  const PendingFillRequestDetailsScreen({
    super.key,
    required this.requestCode,
  });

  @override
  State<PendingFillRequestDetailsScreen> createState() => _PendingFillRequestDetailsScreenState();
}

class _PendingFillRequestDetailsScreenState extends State<PendingFillRequestDetailsScreen> {
  final GasOrderService _gasOrderService = GasOrderService();

  GasOrder? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
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

      final order = await _gasOrderService.getOrderByRequestCode(
        widget.requestCode,
        token,
      );

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, GasOrderItem item) {
    final tank = item.gasTank;
    final tankLabel = tank.trackingCode?.isNotEmpty == true
        ? tank.trackingCode!
        : tank.name;
    final cylinderType = tank.cylinderType?.name ?? 'N/A';
    final capacity = '${tank.capacity.toStringAsFixed(0)} ${tank.unit}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tankLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$cylinderType • $capacity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Manual bottom edge', '${item.manualBottomEdgeWeight} ${tank.unit}'),
          _buildInfoRow('Calculated bottom edge', '${item.calculatedBottomEdgeWeight} ${tank.unit}'),
          _buildInfoRow('Before refill', '${item.beforeRefillWeight} ${tank.unit}'),
          _buildInfoRow('After refill', '${item.afterRefillWeight} ${tank.unit}'),
        ],
      ),
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
              'Request Details',
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
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadOrderDetails,
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
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                        onPressed: _loadOrderDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.modernGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _order!.site.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pick up cylinders at this site.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Request: ${_order!.requestCode}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
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
                                color: _getStatusColor(_order!.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(_order!.status).withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                _order!.status,
                                style: TextStyle(
                                  color: _getStatusColor(_order!.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Site Information',
                        children: [
                          _buildInfoRow('Site', _order!.site.name),
                          if (_order!.site.stationCode != null && _order!.site.stationCode!.isNotEmpty)
                            _buildInfoRow('Site code', _order!.site.stationCode!),
                          if (_order!.site.address != null && _order!.site.address!.isNotEmpty)
                            _buildInfoRow('Address', _order!.site.address!),
                          if (_order!.site.city != null && _order!.site.city!.isNotEmpty)
                            _buildInfoRow('City', _order!.site.city!),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Request Information',
                        children: [
                          _buildInfoRow('Created by', _order!.requestCreatedBy),
                          _buildInfoRow('Created at', _formatDate(_order!.requestCreatedAt)),
                          if (_order!.deliveryCode != null && _order!.deliveryCode!.isNotEmpty)
                            _buildInfoRow('Delivery code', _order!.deliveryCode!),
                          if (_order!.deliveryDoneBy != null && _order!.deliveryDoneBy!.isNotEmpty)
                            _buildInfoRow('Delivery done by', _order!.deliveryDoneBy!),
                          if (_order!.deliveryDoneAt != null)
                            _buildInfoRow('Delivery done at', _formatDate(_order!.deliveryDoneAt!)),
                          if (_order!.invoiceNumber != null && _order!.invoiceNumber!.isNotEmpty)
                            _buildInfoRow('Invoice number', _order!.invoiceNumber!),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Order Totals',
                        children: [
                          _buildInfoRow('Total manual bottom edge', _order!.totalManualBottomEdgeWeight),
                          _buildInfoRow('Total calculated bottom edge', _order!.totalCalculatedBottomEdgeWeight),
                          _buildInfoRow('Total product weight', _order!.productWeight),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        title: 'Cylinders',
                        children: _order!.items.isEmpty
                            ? [
                                Text(
                                  'No cylinders added.',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                              ]
                            : _order!.items.asMap().entries.map((entry) {
                                return _buildItemCard(entry.key, entry.value);
                              }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }
}
