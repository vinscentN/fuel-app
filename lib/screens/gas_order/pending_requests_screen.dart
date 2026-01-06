import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gas_order.dart';
import '../../providers/auth_provider.dart';
import '../../services/gas_order_service.dart';
import '../../utils/colors.dart';
import 'qr_code_screen.dart';
import 'edit_cylinders_screen.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({Key? key}) : super(key: key);

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  final GasOrderService _gasOrderService = GasOrderService();

  List<PendingGasOrder> _pendingOrders = [];
  bool _isLoading = true;
  String? _error;

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

      final orders = await _gasOrderService.getPendingOrders(user.serviceStationId, token);

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

  void _viewQRCode(PendingGasOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeScreen(requestCode: order.requestCode),
      ),
    );
  }

  void _editRequest(PendingGasOrder order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCylindersScreen(order: order),
      ),
    );

    // Reload pending orders when returning from edit
    _loadPendingOrders();
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
                                      Icon(Icons.refresh_rounded, color: Colors.white),
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
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingOrders.length,
                        itemBuilder: (context, index) {
                          final order = _pendingOrders[index];

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
                                            color: _getStatusColor(order.status).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getStatusColor(order.status).withOpacity(0.5),
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
                                    const SizedBox(height: 12),
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
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
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
                                    const SizedBox(height: 16),
                                    // Show Edit button for pending requests, and View QR if cylinders exist
                                    if (order.tanksCount == 0)
                                      // No cylinders - show only Edit button
                                      Container(
                                        width: double.infinity,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Colors.orange, Color(0xFFE65100)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _editRequest(order),
                                            borderRadius: BorderRadius.circular(12),
                                            child: const Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Add Cylinders',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    else
                                      // Has cylinders - show both Edit and View QR Code buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 48,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: AppColors.primary, width: 2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () => _editRequest(order),
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: const Center(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          'Edit',
                                                          style: TextStyle(
                                                            color: AppColors.primary,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 2,
                                            child: Container(
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
                                                  onTap: () => _viewQRCode(order),
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: const Center(
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          'View QR Code',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
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
