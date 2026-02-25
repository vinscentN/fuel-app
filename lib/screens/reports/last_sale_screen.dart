import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../services/report_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';

class LastSaleScreen extends StatefulWidget {
  const LastSaleScreen({super.key});

  @override
  State<LastSaleScreen> createState() => _LastSaleScreenState();
}

class _LastSaleScreenState extends State<LastSaleScreen> {
  final _service = ReportService();
  Map<String, dynamic>? _data;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndPrint());
  }

  Future<void> _loadAndPrint() async {
    final serial = context.read<AuthProvider>().serialNumber;
    if (serial == null || serial.isEmpty) {
      setState(() => _error = 'Device not activated. Serial number missing.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await _service.fetchLastSale(serialNumber: serial);
      final d = (resp['data'] as Map?)?.cast<String, dynamic>();
      if (d == null) throw Exception('No last sale data');
      setState(() => _data = d);

      final pos = context.read<PosProvider>();
      await pos.printLastSaleReceipt(
        title: 'LAST SALE TRANSACTION',
        stationName: (d['stationName'] ?? '').toString(),
        address: (d['address'] ?? '').toString(),
        phone: (d['phone'] ?? '').toString(),
        date: (d['date'] ?? '').toString(),
        time: (d['time'] ?? '').toString(),
        pumpNo: (d['pumpNo'] ?? '').toString(),
        product: (d['product'] ?? '').toString(),
        unit: 'Kg',
        litres: (d['litres'] ?? '').toString(),
        pricePerLitre: (d['pricePerLitre'] ?? '').toString(),
        total: (d['total'] ?? '').toString(),
        payment: (d['payment'] ?? '').toString(),
        cardNo: (d['cardNo'] ?? '').toString(),
        authNo: (d['authNo'] ?? '').toString(),
        rrn: (d['rrn'] ?? '').toString(),
      );

      if (!mounted) return;
      final success = context.read<PosProvider>().lastError == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Printed last sale' : 'Printing failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Last Sale'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadAndPrint,
            icon: const Icon(Icons.print),
            tooltip: 'Reprint',
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)));
    }
    if (_data == null) {
      return const Center(child: Text('No last sale data'));
    }
    final d = _data!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LAST SALE TRANSACTION', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _row('Station', (d['stationName'] ?? '').toString()),
                _row('Date', (d['date'] ?? '').toString()),
                _row('Time', (d['time'] ?? '').toString()),
                _row('Serial Number', (d['pumpNo'] ?? '').toString()),
                _row('Product', (d['product'] ?? '').toString()),
                _row('Kgs', (d['litres'] ?? '').toString()),
                _row('Price/Kg', (d['pricePerLitre'] ?? '').toString()),
                _row('Total', (d['total'] ?? '').toString()),
                _row('Payment', (d['payment'] ?? '').toString()),
                _row('Card', (d['cardNo'] ?? '').toString()),
                _row('AuthNo', (d['authNo'] ?? '').toString()),
                _row('RRN', (d['rrn'] ?? '').toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(a, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(child: Text(b, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
