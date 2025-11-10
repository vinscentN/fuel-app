import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/auth_provider.dart';
import '../home/landing_menu_screen.dart';
import '../../utils/colors.dart';
import '../../services/card_service.dart';

class CardBalanceScreen extends StatefulWidget {
  const CardBalanceScreen({super.key});

  @override
  State<CardBalanceScreen> createState() => _CardBalanceScreenState();
}

class _CardBalanceScreenState extends State<CardBalanceScreen> {
  final TextEditingController _pinCtrl = TextEditingController();
  bool _checking = false;
  Map<String, dynamic>? _result; // keep last successful response

  @override
  void initState() {
    super.initState();
    // Start waiting for card immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pos = Provider.of<PosProvider>(context, listen: false);
      // Ensure previous card data (PAN/UID) is not reused
      pos.clearCardData();
      pos.readNfcCard();
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  String? _panFrom(Map? data) {
    final pan = data == null ? null : (data['pan']?.toString() ?? data['uid_raw']?.toString());
    return (pan != null && pan.isNotEmpty) ? pan : null;
  }

  Future<void> _checkBalance(String pan) async {
    if (_pinCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 4-digit PIN')),
      );
      return;
    }
    setState(() { _checking = true; _result = null; });
    try {
      final resp = await CardService().getBalances(cardPan: pan, pvv: _pinCtrl.text);
      setState(() { _result = resp; });

      // Auto-print receipt and return to Landing when successful
      await _autoPrintAndReturn(resp);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to retrieve balance: $e')),
      );
    } finally {
      if (mounted) setState(() { _checking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Card Balance Enquiry'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Consumer<PosProvider>(
        builder: (context, pos, child) {
          final pan = _panFrom(pos.lastResult);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WaitingForCardWidget(isLoading: pos.isLoading, hasPan: pan != null),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Card PAN', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        SelectableText(pan ?? 'Waiting for card...',
                            style: TextStyle(color: pan != null ? AppColors.textPrimary : AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        const Text('Enter PIN (PVV)', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        PinCodeTextField(
                          appContext: context,
                          length: 4,
                          controller: _pinCtrl,
                          obscureText: true,
                          obscuringCharacter: '•',
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.fade,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(10),
                            fieldHeight: 52,
                            fieldWidth: 52,
                            activeFillColor: AppColors.primary.withOpacity(0.08),
                            inactiveFillColor: AppColors.surfaceVariant,
                            selectedFillColor: AppColors.primary.withOpacity(0.12),
                            activeColor: AppColors.primary,
                            inactiveColor: AppColors.border,
                            selectedColor: AppColors.primary,
                          ),
                          enableActiveFill: true,
                          onCompleted: (_) {
                            final p = _panFrom(pos.lastResult);
                            if (p != null) _checkBalance(p);
                          },
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: (pan == null || _checking) ? null : () => _checkBalance(pan),
                            icon: _checking
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.search),
                            label: Text(_checking ? 'Checking...' : 'Check Balance'),
                          ),
                        ),
                        if (pos.lastError != null) ...[
                          const SizedBox(height: 10),
                          Text('NFC Error: ${pos.lastError}', style: const TextStyle(color: Colors.red)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_result != null) _buildResultCard(_result!),
              ],
            ),
          );
        },
      ),
    );
  }

  // Simple waiting widget matching card sale vibe
  Widget _WaitingForCardWidget({required bool isLoading, required bool hasPan}) {
    if (hasPan) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(Icons.credit_card, size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          isLoading ? 'Waiting for card...' : 'Please tap or insert card',
          style: const TextStyle(color: AppColors.textSecondary),
        )
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> resp) {
    final raw = resp['data'];
    List<dynamic> balances;
    String cardNo = '';

    if (raw is List) {
      // New API shape: data is a list of currency balances
      balances = raw;
      // Try to show the card no from the last read card as a fallback context
      final pos = Provider.of<PosProvider>(context, listen: false);
      cardNo = _panFrom(pos.lastResult) ?? '';
    } else if (raw is Map<String, dynamic>) {
      // Old/alternative shape: { data: { cardNo, balances: [] } }
      cardNo = raw['cardNo']?.toString() ?? '';
      balances = (raw['balances'] as List?)?.cast<dynamic>() ?? const [];
    } else {
      balances = const [];
      final pos = Provider.of<PosProvider>(context, listen: false);
      cardNo = _panFrom(pos.lastResult) ?? '';
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Balances', style: TextStyle(fontWeight: FontWeight.w700)),
            if (cardNo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(cardNo, style: const TextStyle(color: AppColors.textSecondary)),
            ],
            const Divider(height: 24),
            if (balances.isEmpty)
              const Text('--', style: TextStyle(color: AppColors.textSecondary))
            else ...[
              for (final b in balances)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${b['currency_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${b['balance'] ?? ''}', style: const TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _printBalances(cardNo: cardNo, balances: balances),
                  icon: const Icon(Icons.print),
                  label: const Text('Print Balance Receipt'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _printBalances({required String cardNo, required List balances}) async {
    try {
      final pos = Provider.of<PosProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final now = DateTime.now();
      final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final items = balances.map<Map<String, String>>((b) => {
            'currency': (b['currency_name'] ?? b['currency_code'] ?? '').toString(),
            'balance': (b['balance'] ?? '').toString(),
          }).toList();

      await pos.printBalanceEnquiryReceipt(
        stationName: auth.serviceStationName ?? 'Service Station',
        address: auth.serviceStationAddress ?? '',
        phone: auth.serviceStationPhone ?? '',
        date: date,
        time: time,
        cardNo: _maskPan(cardNo),
        items: items,
        title: 'CARD BALANCE ENQUIRY',
      );

      // Do not show a UI toast; native SDK handles printing UX
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  Future<void> _autoPrintAndReturn(Map<String, dynamic> resp) async {
    try {
      // Extract balances list and card number similar to the renderer
      final raw = resp['data'];
      List<dynamic> balances;
      String cardNo = '';

      if (raw is List) {
        balances = raw;
        final pos = Provider.of<PosProvider>(context, listen: false);
        cardNo = _panFrom(pos.lastResult) ?? '';
      } else if (raw is Map<String, dynamic>) {
        cardNo = raw['cardNo']?.toString() ?? '';
        balances = (raw['balances'] as List?)?.cast<dynamic>() ?? const [];
      } else {
        balances = const [];
        final pos = Provider.of<PosProvider>(context, listen: false);
        cardNo = _panFrom(pos.lastResult) ?? '';
      }

      await _printBalances(cardNo: cardNo, balances: balances);

      if (!mounted) return;
      // Clear any cached card data once the transaction is done
      Provider.of<PosProvider>(context, listen: false).clearCardData();
      // Navigate back to Landing screen after printing
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingMenuScreen()),
        (route) => false,
      );
    } catch (_) {
      // If printing/navigation fails, stay on screen; errors already surfaced
    }
  }

  String _maskPan(String pan) {
    if (pan.isEmpty) return '';
    final clean = pan.replaceAll(' ', '');
    if (clean.length <= 4) return clean;
    final masked = '*' * (clean.length - 4) + clean.substring(clean.length - 4);
    final buf = StringBuffer();
    for (int i = 0; i < masked.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(masked[i]);
    }
    return buf.toString();
  }
}
