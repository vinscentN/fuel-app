import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../providers/auth_provider.dart';
import '../home/landing_menu_screen.dart';
import '../../utils/colors.dart';
import '../../services/card_service.dart';
import 'package:gasman/aisino_pos_sdk.dart';

enum BalanceEnquiryState {
  waitingForCard,
  cardDetected,
  enteringPin,
  processing,
  success,
  error
}

class CardBalanceScreen extends StatefulWidget {
  const CardBalanceScreen({super.key});

  @override
  State<CardBalanceScreen> createState() => _CardBalanceScreenState();
}

class _CardBalanceScreenState extends State<CardBalanceScreen> with TickerProviderStateMixin {
  final TextEditingController _pinCtrl = TextEditingController();
  bool _checking = false;
  Map<String, dynamic>? _result; // keep last successful response

  BalanceEnquiryState _currentState = BalanceEnquiryState.waitingForCard;
  String? _cardPan;
  String? _errorMessage;

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();

    // Start NFC reading
    _beginNfcRead();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _beginNfcRead() async {
    try {
      final result = await AisinoPosSdk.startNfcTransaction();

      if (!mounted) return;

      if (result != null && result is Map) {
        // Beep on successful card detection
        try {
          await AisinoPosSdk.beep();
        } catch (e) {
          print('Beep failed: $e');
        }

        final pan = result['pan']?.toString() ?? result['uid_raw']?.toString() ?? '';

        if (pan.isNotEmpty) {
          setState(() {
            _cardPan = pan;
            _currentState = BalanceEnquiryState.enteringPin;
          });
        } else {
          setState(() {
            _errorMessage = 'Card read but no PAN found';
            _currentState = BalanceEnquiryState.error;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No card detected';
          _currentState = BalanceEnquiryState.error;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Card reading failed: $e';
        _currentState = BalanceEnquiryState.error;
      });
    }
  }


  Future<void> _checkBalance() async {
    if (_pinCtrl.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter 4-digit PIN')),
      );
      return;
    }

    if (_cardPan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No card detected')),
      );
      return;
    }

    setState(() {
      _checking = true;
      _result = null;
      _currentState = BalanceEnquiryState.processing;
    });

    try {
      final resp = await CardService().getBalances(cardPan: _cardPan!, pvv: _pinCtrl.text);
      setState(() {
        _result = resp;
        _currentState = BalanceEnquiryState.success;
      });

      // Auto-print receipt and return to Landing when successful
      await _autoPrintAndReturn(resp);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to retrieve balance: $e';
        _currentState = BalanceEnquiryState.error;
      });
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case BalanceEnquiryState.waitingForCard:
        return _buildWaitingForCard();
      case BalanceEnquiryState.cardDetected:
      case BalanceEnquiryState.enteringPin:
        return _buildPinEntry();
      case BalanceEnquiryState.processing:
        return _buildProcessing();
      case BalanceEnquiryState.success:
        return _buildSuccess();
      case BalanceEnquiryState.error:
        return _buildError();
    }
  }

  Widget _buildWaitingForCard() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 200,
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: const Icon(
                  Icons.credit_card,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tap your card',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Place card near reader',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      const Text('Card Detected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Card PAN', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SelectableText(
                    _maskPan(_cardPan ?? ''),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Enter PIN', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 16),
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
                      fieldHeight: 56,
                      fieldWidth: 56,
                      activeFillColor: AppColors.primary.withOpacity(0.08),
                      inactiveFillColor: AppColors.surfaceVariant,
                      selectedFillColor: AppColors.primary.withOpacity(0.12),
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.border,
                      selectedColor: AppColors.primary,
                    ),
                    enableActiveFill: true,
                    onCompleted: (_) => _checkBalance(),
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _checking ? null : _checkBalance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _checking ? 'Checking...' : 'Check Balance',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessing() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 4,
            color: AppColors.primary,
          ),
          SizedBox(height: 24),
          Text(
            'Checking balance...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_result != null) _buildResultCard(_result!),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> resp) {
    final raw = resp['data'];
    List<dynamic> balances;
    String cardNo = '';

    if (raw is List) {
      // New API shape: data is a list of currency balances
      balances = raw;
      // Use the stored card PAN
      cardNo = _cardPan ?? '';
    } else if (raw is Map<String, dynamic>) {
      // Old/alternative shape: { data: { cardNo, balances: [] } }
      cardNo = raw['cardNo']?.toString() ?? '';
      balances = (raw['balances'] as List?)?.cast<dynamic>() ?? const [];
    } else {
      balances = const [];
      cardNo = _cardPan ?? '';
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
        cardNo = _cardPan ?? '';
      } else if (raw is Map<String, dynamic>) {
        cardNo = raw['cardNo']?.toString() ?? '';
        balances = (raw['balances'] as List?)?.cast<dynamic>() ?? const [];
      } else {
        balances = const [];
        cardNo = _cardPan ?? '';
      }

      await _printBalances(cardNo: cardNo, balances: balances);

      if (!mounted) return;
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
