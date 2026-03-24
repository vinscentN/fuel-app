import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/report_service.dart';
import '../../utils/colors.dart';
import '../../utils/error_utils.dart';
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
  bool _printing = false;
  String? _error;
  String? _operatorCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
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
    if (opCode == null || opCode.isEmpty || !mounted) return;
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
      if (!mounted) return;
      setState(() => _report = resp);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _printReport() async {
    final report = _report;
    if (report == null || _printing) return;

    setState(() => _printing = true);
    try {
      final pos = context.read<PosProvider>();
      final auth = context.read<AuthProvider>();
      final stationName = auth.serviceStationName ?? 'Service Station';

      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(now);
      final time = DateFormat('HH:mm').format(now);

      final txns = (report['data'] as List?)?.cast<Map>() ?? const [];
      final rawSummary = (report['summary'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final summary = <String, dynamic>{
        ...rawSummary,
        'total_quantity_kgs': _formatNumber(rawSummary['total_quantity_kgs']),
      };

      final items = txns.isEmpty
          ? <Map<String, String>>[
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
                'amount': _formatNumber(m['amount']),
                'currency_name': (m['currency_name'] ?? m['currency_code'] ?? '').toString(),
                'product_type_name': (m['product_type_name'] ?? '').toString(),
                'description': _formatNumber(m['unit_price']),
                'status': (m['status'] ?? '').toString(),
                'quantity_kgs': _formatNumber(m['quantity_kgs']),
              };
            }).toList();

      await pos.printBatchCutoffReceipt(
        stationName: stationName,
        date: date,
        time: time,
        operatorCode: _operatorCode ?? '-',
        items: items,
        title: 'BATCH CUT OFF',
        attendant: (report['attendant'] as Map?)?.cast<String, dynamic>(),
        device: (report['device'] as Map?)?.cast<String, dynamic>(),
        summary: summary,
      );

      if (!mounted) return;
      final success = context.read<PosProvider>().lastError == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Printed batch cutoff' : 'Printing failed'),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(12),
        ),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFF0D2B55),
                  ),
                  splashRadius: 20,
                  tooltip: 'Back',
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2B55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.content_cut_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Batch Cutoff',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D2B55),
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Batch Transaction Summary',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _loadReport,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0D2B55),
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: Color(0xFF0D2B55),
                        ),
                  splashRadius: 20,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _report == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF0D2B55),
            ),
            SizedBox(height: 12),
            Text(
              'Fetching batch cutoff...',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _ErrorCard(message: _error!, onRetry: _loadReport),
        ),
      );
    }

    if (_report == null) {
      return const Center(
        child: Text(
          'No batch cutoff data available.',
          style: TextStyle(color: Color(0xFF888888), fontSize: 13),
        ),
      );
    }

    final report = _report!;
    final attendant = report['attendant'] as Map? ?? {};
    final device = report['device'] as Map? ?? {};
    final summary = report['summary'] as Map? ?? {};
    final txns = (report['data'] as List?)?.cast<Map>() ?? const [];

    return RefreshIndicator(
      onRefresh: _loadReport,
      color: const Color(0xFF0D2B55),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _CutoffSummaryStrip(
            totalQty: '${_formatNumber(summary['total_quantity_kgs'])} Kg',
            recordCount: '${summary['transaction_count'] ?? txns.length} transactions',
            station: _value(attendant['service_station_name']),
          ),
          const SizedBox(height: 10),
          _ReceiptCard(
            title: 'BATCH OVERVIEW',
            status: 'Loaded',
            statusColor: const Color(0xFF2ECC71),
            rows: [
              _RowData(
                'Attendant',
                '${_value(attendant['first_name'])} ${_value(attendant['last_name'])}'.trim(),
              ),
              _RowData('Operator Code', _operatorCode ?? '--'),
              _RowData('Serial Number', _value(device['serial_number'])),
              _RowData('Terminal ID', _value(device['terminal_id'])),
              _RowData(
                'Total Quantity',
                '${_formatNumber(summary['total_quantity_kgs'])} Kg',
                bold: true,
              ),
              _RowData(
                'Transaction Count',
                '${summary['transaction_count'] ?? txns.length}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...txns.map(
            (txn) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ReceiptCard(
                title: _value(txn['transaction_number']),
                status: _value(txn['status']),
                statusColor: const Color(0xFF0D2B55),
                rows: [
                  _RowData('Date', _compactDate(_value(txn['transaction_date']))),
                  _RowData('Product', _value(txn['product_type_name'])),
                  _RowData('Quantity', '${_formatNumber(txn['quantity_kgs'])} Kg'),
                  _RowData(
                    'Amount',
                    '\$${_formatNumber(txn['amount'])}',
                    bold: true,
                  ),
                  _RowData('Unit Price', _formatNumber(txn['unit_price'])),
                ],
              ),
            ),
          ),
          _PrintButton(
            printing: _printing,
            onPressed: _printing ? null : _printReport,
          ),
          const SizedBox(height: 8),
          const Text(
            'Verify details before printing.',
            style: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _value(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '--' : text;
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0.00';
    if (value is num) return value.toDouble().toStringAsFixed(2);
    final parsed = double.tryParse(value.toString().trim());
    if (parsed == null) return '0.00';
    return parsed.toStringAsFixed(2);
  }

  String _compactDate(String value) {
    if (value == '--') return value;
    try {
      return DateFormat('dd MMM, HH:mm').format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  String _friendlyErrorMessage(Object error) {
    final message = ErrorUtils.extractErrorMessage(
      error,
      fallback: 'Unable to load the batch cutoff right now.',
    );
    final normalized = message.toLowerCase();
    if (normalized.contains('lost internet connection') ||
        normalized.contains('failed to finish the process') ||
        normalized.contains('timeout')) {
      return 'Please check your network connection and try again.';
    }
    return message;
  }
}

class _CutoffSummaryStrip extends StatelessWidget {
  final String totalQty;
  final String recordCount;
  final String station;

  const _CutoffSummaryStrip({
    required this.totalQty,
    required this.recordCount,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2B55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL QUANTITY',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: Color(0xFFB7C3D6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  totalQty,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(recordCount),
                    _Tag(station),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFFCCCCCC),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _RowData {
  final String label;
  final String value;
  final bool bold;
  const _RowData(this.label, this.value, {this.bold = false});
}

class _ReceiptCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final List<_RowData> rows;

  const _ReceiptCard({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.0,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    status,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Color(0xFFF5F5F5),
              indent: 14,
              endIndent: 14,
            ),
            itemBuilder: (context, i) {
              final row = rows[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF0D2B55),
                          fontWeight:
                              row.bold ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PrintButton extends StatelessWidget {
  final bool printing;
  final VoidCallback? onPressed;

  const _PrintButton({
    required this.printing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D2B55),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: printing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.print_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Print Batch Cutoff',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 28,
          ),
          const SizedBox(height: 10),
          const Text(
            'Unable to Load Batch Cutoff',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D2B55),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2B55),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
