import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../services/change_service.dart';
import '../../widgets/common/app_bar_widget.dart';

class ChangeTopupScreen extends StatefulWidget {
  const ChangeTopupScreen({super.key});

  @override
  State<ChangeTopupScreen> createState() => _ChangeTopupScreenState();
}

class _ChangeTopupScreenState extends State<ChangeTopupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = TextEditingController();
  int _currencyId = 1; // 1=USD, 2=ZIG
  String? _pan;
  bool _submitting = false;
  bool _autoReading = false;

  bool get _isAmountValid {
    final d = double.tryParse(_amountCtrl.text);
    return d != null && d > 0;
  }

  @override
  void initState() {
    super.initState();
    // Auto-start NFC read once amount is valid
    _amountCtrl.addListener(_maybeStartAutoRead);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _maybeStartAutoRead() async {
    if (!mounted) return;
    if (_submitting || _autoReading) return;
    if (!_isAmountValid) return;
    if (_pan != null && _pan!.isNotEmpty) return;

    _autoReading = true;
    try {
      final pos = Provider.of<PosProvider>(context, listen: false);
      pos.clearCardData();
      await pos.readNfcCard();
      final data = pos.lastResult;
      final pan = (data?['pan']?.toString() ?? data?['uid_raw']?.toString() ?? '').trim();
      if (pan.isEmpty) {
        // Retry after a short delay if still eligible
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          _autoReading = false;
          _maybeStartAutoRead();
        });
        return;
      }
      setState(() => _pan = pan);
      await _submit(panOverride: pan);
    } finally {
      if (mounted) _autoReading = false;
    }
  }

  Future<void> _tapCard() async {
    // Require valid amount/currency before starting NFC read
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount first')),
      );
      return;
    }

    final pos = Provider.of<PosProvider>(context, listen: false);
    // Ensure no stale PAN from a prior read
    pos.clearCardData();
    await pos.readNfcCard();
    final data = pos.lastResult;
    // Prefer PAN if present, fallback to uid_raw
    final pan = (data?['pan']?.toString() ?? data?['uid_raw']?.toString() ?? '').trim();
    if (pan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No card data read. Please try again.')),
      );
      return;
    }
    setState(() => _pan = pan);
    // Auto-submit immediately after a successful tap
    await _submit(panOverride: pan);
  }

  Future<void> _submit({String? panOverride}) async {
    if (!_formKey.currentState!.validate()) return;
    final effectivePan = (panOverride ?? _pan ?? '').trim();
    if (effectivePan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap card to read PAN first')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final amount = double.parse(_amountCtrl.text);
      final resp = await ChangeService().topupChange(
        pan: effectivePan,
        amount: amount,
        currencyId: _currencyId,
      );
      if (!mounted) return;

      final msg = resp['message']?.toString() ?? 'Change top-up successful';
      final tx = (resp['transaction'] is Map) ? Map<String, dynamic>.from(resp['transaction'] as Map) : <String, dynamic>{};
      final txnNo = tx['transaction_number']?.toString();
      final txnDate = tx['transaction_date']?.toString();

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.green, size: 44),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.green),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (txnNo != null)
                        Text('Transaction #: $txnNo', style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (txnDate != null) ...[
                        const SizedBox(height: 4),
                        Text('Date: $txnDate'),
                      ],
                      const SizedBox(height: 4),
                      Text('Amount: ${_currencySymbol(_currencyId)}${amount.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      Text('Currency ID: $_currencyId'),
                      const SizedBox(height: 4),
                      Text('PAN: ${_maskPan(effectivePan)}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _printReceipt(amount: amount, txnNo: txnNo ?? '-', txnDate: txnDate);
              },
              child: const Text('Print Receipt'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) {
        // Clear cached card data after completing top-up
        Provider.of<PosProvider>(context, listen: false).clearCardData();
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Top-up failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Change Top-up',
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 16),
                _amountField(),
                const SizedBox(height: 12),
                _currencyPicker(),
                const SizedBox(height: 16),
                _cardPanel(),
                const SizedBox(height: 8),
                const Text(
                  'After entering amount and selecting currency, hold the card near the device to top up automatically. No submit needed.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Add change to card balance',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountField() {
    return TextFormField(
      controller: _amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Amount',
        hintText: 'Enter change amount',
        prefixIcon: Icon(Icons.attach_money),
      ),
      onChanged: (_) => setState(() {}),
      validator: (v) {
        final d = double.tryParse(v ?? '');
        if (d == null || d <= 0) return 'Enter a valid amount';
        return null;
      },
    );
  }

  Widget _currencyPicker() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Currency',
        prefixIcon: Icon(Icons.monetization_on_outlined),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _currencyId,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 1, child: Text('USD (1)')),
            DropdownMenuItem(value: 2, child: Text('ZIG (2)')),
          ],
          onChanged: (v) {
            setState(() => _currencyId = v ?? 1);
            _maybeStartAutoRead();
          },
        ),
      ),
    );
  }

  Widget _cardPanel() {
    return Consumer<PosProvider>(
      builder: (context, pos, _) {
        final reading = pos.isLoading;
        final masked = _pan == null || _pan!.isEmpty
            ? 'No card read'
            : _maskPan(_pan!);
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Card PAN', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(masked, style: TextStyle(color: _pan == null ? AppColors.textSecondary : AppColors.textPrimary)),
                const SizedBox(height: 12),
                if (!_isAmountValid) ...[
                  const Text(
                    'Enter a valid amount to start NFC reading automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ] else if (reading || _autoReading || _submitting) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Hold card near the device...'),
                    ],
                  ),
                ] else if (_pan == null || _pan!.isEmpty) ...[
                  const Text(
                    'Ready. Hold card near the device to top-up.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
                if (pos.lastError != null) ...[
                  const SizedBox(height: 8),
                  Text('NFC Error: ${pos.lastError}', style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Removed submit button; top-up happens immediately on successful card tap

  String _maskPan(String pan) {
    final clean = pan.replaceAll(' ', '');
    if (clean.length <= 4) return clean;
    return '${'*' * (clean.length - 4)}${clean.substring(clean.length - 4)}';
  }

  String _currencySymbol(int id) => id == 1 ? '4' : 'ZIG ';

  Future<void> _printReceipt({required double amount, required String txnNo, String? txnDate}) async {
    final pos = Provider.of<PosProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final now = DateTime.now();
    final dt = txnDate ?? now.toIso8601String();
    final date = dt.split('T').first;
    final time = dt.contains('T') ? dt.split('T').last.split('.').first : '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}' ;

    await pos.testPrint(
      stationName: auth.serviceStationName ?? 'Service Station',
      address: '',
      phone: '',
      date: date,
      time: time,
      pumpNo: '-',
      product: 'CHANGE TOP-UP',
      litres: '-',
      pricePerLitre: '-',
      total: amount.toStringAsFixed(2),
      payment: '${_currencySymbol(_currencyId)} Change',
      cardNo: _maskPan(_pan ?? ''),
      authNo: txnNo,
      rrn: txnNo,
    );
  }
}
