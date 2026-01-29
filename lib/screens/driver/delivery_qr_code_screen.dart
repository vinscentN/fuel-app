import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/gas_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/gas_order_service.dart';

class DeliveryQRCodeScreen extends StatefulWidget {
  final String deliveryCode;

  const DeliveryQRCodeScreen({
    super.key,
    required this.deliveryCode,
  });

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
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      GasOrder order;
      try {
        order = await _gasOrderService.getOrderByDeliveryCode(
          widget.deliveryCode,
          token,
        );
      } catch (_) {
        order = await _gasOrderService.getOrderByRequestCode(
          widget.deliveryCode,
          token,
        );
      }

      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _printQRCode() async {
    if (_order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error ?? 'Order details not loaded'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final pos = Provider.of<PosProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final dateFormatter = DateFormat('dd/MM/yyyy');
      final timeFormatter = DateFormat('HH:mm:ss');
      final date = dateFormatter.format(_order!.requestCreatedAt);
      final time = timeFormatter.format(_order!.requestCreatedAt);

      final cylinderDetails = _order!.items.map((item) {
        return '${item.gasTank.trackingCode ?? item.gasTank.name}: ${item.manualBottomEdgeWeight} ${item.gasTank.unit}';
      }).join('\n');

      await pos.printQRCodeReceipt(
        title: 'FILL ORDER REQUEST',
        qrData: _order!.deliveryCode ?? widget.deliveryCode,
        requestCode: _order!.deliveryCode ?? widget.deliveryCode,
        stationName: auth.serviceStationName ?? _order!.site.name,
        address: auth.serviceStationAddress ?? '',
        phone: auth.serviceStationPhone ?? '',
        date: date,
        time: time,
        status: _order!.status,
        description: _order!.description,
        cylinderCount: _order!.items.length.toString(),
        cylinderDetails: cylinderDetails,
        createdBy: _order!.requestCreatedBy,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Delivery QR Code'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _isLoading ? null : _printQRCode,
            tooltip: 'Print QR Code',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: widget.deliveryCode,
              version: QrVersions.auto,
              size: 280,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              widget.deliveryCode,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
