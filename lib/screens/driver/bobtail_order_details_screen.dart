import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/bobtail_order.dart';
import '../../utils/colors.dart';
import 'bobtail_order_completion_screen.dart';

class BobtailOrderDetailsScreen extends StatelessWidget {
  final BobtailOrder order;

  const BobtailOrderDetailsScreen({
    super.key,
    required this.order,
  });

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

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    final isPending = order.status.toUpperCase() == 'PENDING';
    final normalizedOrderType =
        order.orderType.toUpperCase().replaceAll(' ', '_');
    final isPurchase =
        normalizedOrderType == 'BOBTAIL_PURCHASE' ||
        normalizedOrderType == 'PURCHASE';
    final plateNumber = order.bobtail?.plateNumber?.trim().isNotEmpty == true
        ? order.bobtail!.plateNumber!
        : (order.bobtail?.name ?? 'Bobtail ${order.bobtailId}');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('BobTail Order'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.modernGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          plateNumber,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
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
                  const SizedBox(height: 16),
                  _InfoRow(label: 'Order Type', value: order.orderType),
                  _InfoRow(
                    label: 'Expected (kg)',
                    value: order.expectedKg,
                  ),
                  if (order.actualKg != null && order.actualKg!.isNotEmpty)
                    _InfoRow(label: 'Actual (kg)', value: order.actualKg!),
                  if (order.unitCost != null && order.unitCost!.isNotEmpty)
                    _InfoRow(label: 'Unit Cost', value: order.unitCost!),
                  _InfoRow(
                    label: 'Created',
                    value: _formatDate(order.createdAt),
                  ),
                  if (order.notes != null && order.notes!.trim().isNotEmpty)
                    _InfoRow(label: 'Notes', value: order.notes!),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailsCard(
              title: 'Assignment',
              icon: Icons.badge_rounded,
              rows: [
                _InfoRow(
                  label: 'Driver',
                  value: order.assignedDriver?.fullName ??
                      order.assignedDriverId.toString(),
                ),
                if (order.createdBy != null && order.createdBy!.isNotEmpty)
                  _InfoRow(label: 'Created By', value: order.createdBy!),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailsCard(
              title: isPurchase ? 'Supplier' : 'Site Refill',
              icon: isPurchase
                  ? Icons.business_rounded
                  : Icons.local_gas_station_rounded,
              rows: [
                if (isPurchase)
                  _InfoRow(
                    label: 'Supplier',
                    value: order.supplier?.name ??
                        (order.supplierId?.toString() ?? 'N/A'),
                  ),
                if (!isPurchase)
                  _InfoRow(
                    label: 'Site',
                    value: order.gasOrder?.site?.name ??
                        order.gasOrder?.requestCode ??
                        (order.gasOrderId?.toString() ?? 'N/A'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (isPending && !isPurchase)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BobtailOrderCompletionScreen(
                          order: order,
                        ),
                      ),
                    );

                    if (result == true && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: Text(
                    isPurchase
                        ? 'Record Supplier Purchase'
                        : 'Complete Site Refill',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
