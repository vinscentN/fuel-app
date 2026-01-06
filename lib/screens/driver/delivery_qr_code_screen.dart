import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/gas_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/gas_order_service.dart';
import '../../utils/colors.dart';
import 'package:intl/intl.dart';

class DeliveryQRCodeScreen extends StatefulWidget {
  final String requestCode;

  const DeliveryQRCodeScreen({
    Key? key,
    required this.requestCode,
  }) : super(key: key);

  @override
  State<DeliveryQRCodeScreen> createState() => _DeliveryQRCodeScreenState();
}

class _DeliveryQRCodeScreenState extends State<DeliveryQRCodeScreen> {
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

      // First try to get by request code, which should have delivery_code
      final order = await _gasOrderService.getOrderByRequestCode(
        widget.requestCode,
        token,
      );

      // If we have a delivery code, fetch full details by delivery code
      if (order.deliveryCode != null) {
        final deliveryOrder = await _gasOrderService.getOrderByDeliveryCode(
          order.deliveryCode!,
          token,
        );
        setState(() {
          _order = deliveryOrder;
          _isLoading = false;
        });
      } else {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _printQRCode() async {
    if (_order == null || _order!.deliveryCode == null) return;

    try {
      final pos = Provider.of<PosProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      // Format the date
      final dateFormatter = DateFormat('dd/MM/yyyy');
      final timeFormatter = DateFormat('HH:mm:ss');
      final date = dateFormatter.format(_order!.requestCreatedAt);
      final time = timeFormatter.format(_order!.requestCreatedAt);

      // Build cylinder details as a string
      final cylinderDetails = _order!.items.map((item) {
        return '${item.gasTank.trackingCode ?? item.gasTank.name}: ${item.afterRefillWeight} ${item.gasTank.unit}';
      }).join('\n');

      // Print using the POS printer with delivery code
      await pos.printQRCodeReceipt(
        title: 'DELIVERY ORDER',
        qrData: _order!.deliveryCode!,
        requestCode: _order!.deliveryCode!,
        stationName: auth.serviceStationName ?? _order!.site.name,
        address: auth.serviceStationAddress ?? '',
        phone: auth.serviceStationPhone ?? '',
        date: date,
        time: time,
        status: _order!.status,
        description: _order!.description,
        cylinderCount: _order!.items.length.toString(),
        cylinderDetails: cylinderDetails,
        createdBy: _order!.deliveryDoneBy ?? 'N/A',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR Code printed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Delivery QR Code'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          if (_order?.deliveryCode != null)
            IconButton(
              icon: const Icon(Icons.print),
              onPressed: _printQRCode,
              tooltip: 'Print QR Code',
            ),
        ],
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _order?.deliveryCode == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No delivery code available',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'This order has not been marked for delivery yet',
                              style: TextStyle(
                                color: Colors.black38,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                QrImageView(
                                  data: _order!.deliveryCode!,
                                  version: QrVersions.auto,
                                  size: 280,
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _order!.deliveryCode!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Delivery Details',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_order!.status).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getStatusColor(_order!.status),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _order!.status,
                                        style: TextStyle(
                                          color: _getStatusColor(_order!.status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow('Request Code', _order!.requestCode),
                                _buildInfoRow('Delivery Code', _order!.deliveryCode!),
                                _buildInfoRow('Site', _order!.site.name),
                                _buildInfoRow('Description', _order!.description),
                                _buildInfoRow('Created by', _order!.requestCreatedBy),
                                _buildInfoRow('Date', _formatDate(_order!.requestCreatedAt)),
                                if (_order!.invoiceNumber != null)
                                  _buildInfoRow('Invoice', _order!.invoiceNumber!),
                                if (_order!.deliveryDoneBy != null)
                                  _buildInfoRow('Driver', _order!.deliveryDoneBy!),
                                const SizedBox(height: 16),
                                Divider(color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                const Text(
                                  'Cylinders',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._order!.items.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
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
                                            // Number badge
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                gradient: AppColors.modernGradient,
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
                                            // Cylinder info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.gasTank.trackingCode ?? item.gasTank.name,
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
                                                    '${item.gasTank.cylinderType?.name ?? "N/A"} • ${item.gasTank.capacity.toStringAsFixed(0)} ${item.gasTank.unit}',
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
                                        // After refill weight section
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.success.withOpacity(0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.scale,
                                                size: 16,
                                                color: AppColors.success,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'After Refill Weight:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${item.afterRefillWeight} ${item.gasTank.unit}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _printQRCode,
                              icon: const Icon(Icons.print, size: 24),
                              label: const Text(
                                'Print QR Code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
