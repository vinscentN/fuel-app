import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../services/report_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../common/operator_code_screen.dart';

class BatchAuditScreen extends StatefulWidget {
  const BatchAuditScreen({super.key});

  @override
  State<BatchAuditScreen> createState() => _BatchAuditScreenState();
}

class _BatchAuditScreenState extends State<BatchAuditScreen> {
  final _service = ReportService();
  Map<String, dynamic>? _report;
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
    // Ask for operator code first
    final opCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const OperatorCodeScreen(
          title: 'Operator Code',
          subtitle: 'Enter operator code for batch audit',
        ),
      ),
    );
    if (opCode == null || opCode.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await _service.fetchBatchAudit(serialNumber: serial, operatorCode: opCode);
      setState(() => _report = resp);

      final pos = context.read<PosProvider>();
      final attendant = (_report!['attendant'] as Map?)?.cast<String, dynamic>();
      final device = (_report!['device'] as Map?)?.cast<String, dynamic>();
      final time = (_report!['time'] ?? '').toString();

      final data = (_report!['data'] as List?)?.cast<Map>() ?? const [];
      final items = data.map<Map<String, String>>((m) => {
            'transaction_type_name': (m['transaction_type_name'] ?? '').toString(),
            'currency_name': (m['currency_name'] ?? '').toString(),
            'currency_symbol': (m['currency_symbol'] ?? '').toString(),
            'total_litres': (m['total_litres'] ?? '').toString(),
            'total_value': (m['total_value'] ?? '').toString(),
          }).toList();

      await pos.printBatchAuditReceipt(
        title: 'BATCH AUDIT',
        attendant: attendant,
        device: device,
        time: time,
        items: items,
      );

      if (!mounted) return;
      final success = context.read<PosProvider>().lastError == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Printed batch audit' : 'Printing failed'),
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
        title: const Text('Batch Audit'),
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)));
    if (_report == null) return const Center(child: Text('No audit loaded'));

    final a = (_report!['attendant'] as Map?) ?? const {};
    final d = (_report!['device'] as Map?) ?? const {};
    final time = (_report!['time'] ?? '').toString();
    final rows = (_report!['data'] as List?)?.cast<Map>() ?? const [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BATCH AUDIT', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Station: ${a['service_station_name'] ?? ''}'),
                Text('Operator: ${(a['first_name'] ?? '')} ${(a['last_name'] ?? '')}'),
                Text('SN: ${d['serial_number'] ?? ''}   TID: ${d['terminal_id'] ?? ''}'),
                if (time.isNotEmpty) Text(time),
                const Divider(),
                ...rows.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r['transaction_type_name'] ?? ''} (${r['currency_name'] ?? ''})', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Litres: ${r['total_litres'] ?? ''} L'),
                      Text('Value: ${(r['currency_symbol'] ?? '')}${r['total_value'] ?? ''}'),
                      const Divider(),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
