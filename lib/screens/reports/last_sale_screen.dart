import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/report_service.dart';
import '../../utils/colors.dart';
import '../../utils/error_utils.dart';
import '../../widgets/common/custom_button.dart';

class LastSaleScreen extends StatefulWidget {
  final bool autoPrint;

  const LastSaleScreen({
    super.key,
    this.autoPrint = false,
  });

  @override
  State<LastSaleScreen> createState() => _LastSaleScreenState();
}

class _LastSaleScreenState extends State<LastSaleScreen> {
  final _service = ReportService();
  Map<String, dynamic>? _data;
  bool _loading = false;
  bool _printing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLastSale());
  }

  Future<void> _loadLastSale() async {
    final serial = context.read<AuthProvider>().serialNumber;
    if (serial == null || serial.isEmpty) {
      setState(() => _error = 'Device not activated. Serial number missing.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await _service.fetchLastSale(serialNumber: serial);
      final data = (resp['data'] as Map?)?.cast<String, dynamic>();
      if (data == null) throw Exception('No last sale data found.');
      if (!mounted) return;
      setState(() => _data = data);
      if (widget.autoPrint) await _printLastSale();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _printLastSale() async {
    final data = _data;
    if (data == null || _printing) return;
    setState(() => _printing = true);
    try {
      final pos = context.read<PosProvider>();
      await pos.printLastSaleReceipt(
        title: 'LAST SALE TRANSACTION',
        stationName: (data['stationName'] ?? '').toString(),
        address: (data['address'] ?? '').toString(),
        phone: (data['phone'] ?? '').toString(),
        date: (data['date'] ?? '').toString(),
        time: (data['time'] ?? '').toString(),
        pumpNo: '',
        product: (data['product'] ?? '').toString(),
        unit: 'Kg',
        litres: (data['litres'] ?? '').toString(),
        pricePerLitre: (data['pricePerLitre'] ?? '').toString(),
        total: (data['total'] ?? '').toString(),
        payment: (data['payment'] ?? '').toString(),
        cardNo: (data['cardNo'] ?? '').toString(),
        receiptNo: _receiptNo(data),
        authNo: (data['authNo'] ?? '').toString(),
        rrn: (data['rrn'] ?? '').toString(),
        qrData: _qrData(data),
      );
      if (!mounted) return;
      final success = context.read<PosProvider>().lastError == null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Last sale printed' : 'Printing failed'),
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
                    Icons.receipt_long_rounded,
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
                        'Last Sale',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D2B55),
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Transaction Record',
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
                  onPressed: _loading ? null : _loadLastSale,
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
    if (_loading && _data == null) {
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
              'Fetching last sale...',
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
          child: _ErrorCard(message: _error!, onRetry: _loadLastSale),
        ),
      );
    }

    if (_data == null) {
      return const Center(
        child: Text(
          'No last sale data available.',
          style: TextStyle(color: Color(0xFF888888), fontSize: 13),
        ),
      );
    }

    final data = _data!;

    return RefreshIndicator(
      onRefresh: _loadLastSale,
      color: const Color(0xFF0D2B55),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _SummaryStrip(
            total: _value(data['total']),
            product: _value(data['product']),
            payment: _value(data['payment']),
            date: _value(data['date']),
            time: _value(data['time']),
          ),
          const SizedBox(height: 10),
          _ReceiptCard(
            rows: [
              _RowData('Station', _value(data['stationName'])),
              _RowData('Product', _value(data['product'])),
              _RowData('Quantity', '${_value(data['litres'])} Kg'),
              _RowData('Price / Kg', _value(data['pricePerLitre'])),
              _RowData('Total', _value(data['total']), bold: true),
              _RowData('Payment', _value(data['payment'])),
              _RowData('Receipt No.', _receiptNo(data)),
              _RowData('Auth No.', _value(data['authNo'])),
              _RowData('RRN', _value(data['rrn'])),
            ],
          ),
          const SizedBox(height: 14),
          _PrintButton(
            printing: _printing,
            onPressed: _printing ? null : _printLastSale,
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

  String _receiptNo(Map<String, dynamic> data) {
    final fiscal = data['fiscalisation'] as Map?;
    final fiscalData = fiscal?['data'] as Map?;
    return _value(fiscalData?['receiptID']);
  }

  String _qrData(Map<String, dynamic> data) {
    final fiscal = data['fiscalisation'] as Map?;
    return (fiscal?['qrData'] ?? '').toString();
  }

  String _friendlyErrorMessage(Object error) {
    final message = ErrorUtils.extractErrorMessage(
      error,
      fallback: 'Unable to load the last sale right now.',
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

// ─────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────

class _SummaryStrip extends StatelessWidget {
  final String total;
  final String product;
  final String payment;
  final String date;
  final String time;

  const _SummaryStrip({
    required this.total,
    required this.product,
    required this.payment,
    required this.date,
    required this.time,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL AMOUNT',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  total,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Tag(product),
                    const SizedBox(width: 6),
                    _Tag(payment),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
            ],
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
  final List<_RowData> rows;
  const _ReceiptCard({required this.rows});

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
                const Text(
                  'TRANSACTION SUMMARY',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: Color(0xFF888888),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Completed',
                  style: TextStyle(fontSize: 10, color: Color(0xFF2ECC71)),
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
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      row.value,
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFF0D2B55),
                        fontWeight:
                        row.bold ? FontWeight.w800 : FontWeight.w600,
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

  const _PrintButton({required this.printing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor:
          printing ? const Color(0xFFEEEEEE) : const Color(0xFF0D2B55),
          foregroundColor:
          printing ? const Color(0xFF888888) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              printing ? Icons.hourglass_top_rounded : Icons.print_rounded,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              printing ? 'Printing...' : 'Print Receipt',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
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

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: Color(0xFF888888),
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to Load',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D2B55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0D2B55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
