import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../services/report_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../common/operator_code_screen.dart';

class BatchCutoffScreen extends StatefulWidget {
  const BatchCutoffScreen({super.key});

  @override
  State<BatchCutoffScreen> createState() => _BatchCutoffScreenState();
}

class _BatchCutoffScreenState extends State<BatchCutoffScreen> {
  final _service = ReportService();
  Map<String, dynamic>? _report;
  bool _loading = false;
  String? _error;
  String? _operatorCode;

  @override
  void initState() {
    super.initState();
    // Prompt for operator code immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReport();
    });
  }

  Future<void> _loadReport() async {
    final auth = context.read<AuthProvider>();
    final serial = auth.serialNumber;
    final attendantId = auth.currentUser?.id ?? 0;
    if (serial == null || serial.isEmpty) {
      setState(() => _error = 'Device not activated. Serial number missing.');
      return;
    }
    if (attendantId <= 0) {
      setState(() => _error = 'Logged-in attendant not found. Please login again.');
      return;
    }

    final opCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const OperatorCodeScreen(
          title: 'Operator Code',
          subtitle: 'Enter operator code to view batch',
        ),
      ),
    );
    if (opCode == null || opCode.isEmpty) return;
    _operatorCode = opCode;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _service.fetchBatchCutoff(
        serialNumber: serial,
        operatorCode: opCode,
        attendantId: attendantId,
      );
      setState(() => _report = resp);
      // Auto-print once loaded
      await _printReport();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _printReport() async {
    if (_report == null) return;
    final pos = context.read<PosProvider>();
    final auth = context.read<AuthProvider>();
    final stationName = auth.serviceStationName ?? 'Service Station';

    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final txns = (_report!['data'] as List?)?.cast<Map>() ?? const [];
    final summary = (_report!['summary'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final items = txns.isEmpty
        ? <Map<String, String>>[
            // Keep keys as per API payload names for native handler
            {
              'transaction_number': 'No transactions',
              'transaction_date': '',
              'amount': '',
              'currency_name': '',
              'product_type_name': '',
              'description': '',
              'status': '',
              'quantity_kgs': '',
            },
          ]
        : txns.map<Map<String, String>>((raw) {
            final m = raw.cast<String, dynamic>();
            return {
              'transaction_number': (m['transaction_number'] ?? '').toString(),
              'transaction_date': (m['transaction_date'] ?? '').toString(),
              'amount': (m['amount'] ?? '').toString(),
              'currency_name': (m['currency_name'] ?? m['currency_code'] ?? '').toString(),
              'product_type_name': (m['product_type_name'] ?? '').toString(),
              'description': (m['description'] ?? '').toString(),
              'status': (m['status'] ?? '').toString(),
              'quantity_kgs': (m['quantity_kgs'] ?? '').toString(),
            };
          }).toList();

    await pos.printBatchCutoffReceipt(
      stationName: stationName,
      date: date,
      time: time,
      operatorCode: _operatorCode ?? '-',
      items: items,
      title: 'BATCH CUT OFF',
      attendant: (_report!['attendant'] as Map?)?.cast<String, dynamic>(),
      device: (_report!['device'] as Map?)?.cast<String, dynamic>(),
      summary: summary,
    );

    if (!mounted) return;
    final success = context.read<PosProvider>().lastError == null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Printed batch cutoff' : 'Printing failed'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Cutoff'),
        actions: [
          IconButton(
            onPressed: _report == null || _loading ? null : _printReport,
            icon: const Icon(Icons.print),
            tooltip: 'Print',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _loadReport,
                  icon: const Icon(Icons.refresh),
                  label: Text(_report == null ? 'Load Batch' : 'Reload Batch'),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            Expanded(
              child: _report == null
                  ? const _EmptyState()
                  : _ReportView(report: _report!),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.receipt_long, size: 56, color: AppColors.textLight),
          SizedBox(height: 8),
          Text('No report loaded', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportView({required this.report});

  @override
  Widget build(BuildContext context) {
    final attendant = report['attendant'] as Map? ?? {};
    final device = report['device'] as Map? ?? {};
    final summary = report['summary'] as Map? ?? {};
    final txns = (report['data'] as List?)?.cast<Map>() ?? const [];
    final totalQty = (summary['total_quantity_kgs'] ?? 0).toString();
    final txnCount = (summary['transaction_count'] ?? txns.length).toString();
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _row('Attendant', '${attendant['first_name'] ?? ''} ${attendant['last_name'] ?? ''}'.trim()),
                _row('Station', (attendant['service_station_name'] ?? '-').toString()),
                _row('Serial', (device['serial_number'] ?? '-').toString()),
                _row('Terminal', (device['terminal_id'] ?? '-').toString()),
                _row('Total Qty', '$totalQty Kgs'),
                _row('Txn Count', txnCount),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('Transactions', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 4),
        ...txns.map((m) => _TxnTile(data: m.cast<String, dynamic>())).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(
            child: Text(value, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TxnTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = (data['transaction_number'] ?? '-').toString();
    final subtitle = (data['description'] ?? '').toString();
    final amount = (data['amount'] ?? '0').toString();
    final currency = (data['currency_name'] ?? '').toString();
    final date = (data['transaction_date'] ?? '').toString();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$subtitle\n$date'),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$currency $amount', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text((data['status'] ?? '').toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
