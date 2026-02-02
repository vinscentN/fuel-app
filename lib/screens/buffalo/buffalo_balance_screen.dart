import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/buffalo_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/pos_service.dart';

class BuffaloBalanceScreen extends StatefulWidget {
  const BuffaloBalanceScreen({Key? key}) : super(key: key);

  @override
  State<BuffaloBalanceScreen> createState() => _BuffaloBalanceScreenState();
}

class _BuffaloBalanceScreenState extends State<BuffaloBalanceScreen> {
  final PosService _posService = PosService();

  bool _isReadingCard = false;
  bool _isChecking = false;
  String? _cardNumber;
  String? _errorMessage;
  bool _balanceChecked = false;
  bool _hasPrinted = false;

  @override
  void initState() {
    super.initState();
    // Auto-start card reading when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readCard();
    });
  }

  Future<void> _autoPrintBalance() async {
    if (_hasPrinted) return;
    _hasPrinted = true;

    final buffaloProvider = context.read<BuffaloProvider>();
    final posProvider = context.read<PosProvider>();
    final balanceResponse = buffaloProvider.lastBalanceResponse;

    if (balanceResponse == null || balanceResponse.data == null) return;

    final now = DateTime.now();
    final balances = balanceResponse.data!.balances.map((b) => {
      'currency': b.currencyCode,
      'balance': b.formatted,
    }).toList();

    await posProvider.printBuffaloBalanceReceipt(
      companyName: 'The Buffalo Brewing Company',
      date: DateFormat('dd/MM/yyyy').format(now),
      time: DateFormat('HH:mm:ss').format(now),
      cardNo: _maskCardNumber(_cardNumber ?? ''),
      balances: balances,
    );
  }

  Future<void> _readCard() async {
    setState(() {
      _isReadingCard = true;
      _errorMessage = null;
      _cardNumber = null;
      _balanceChecked = false;
    });

    try {
      final result = await _posService.readNfc();

      if (result != null) {
        // Extract card number from various possible fields
        final extractedCardNumber = result['pan'] ??
                                    result['card_number'] ??
                                    result['uid'] ??
                                    result['cardNumber'];

        if (extractedCardNumber != null && extractedCardNumber.toString().isNotEmpty) {
          setState(() {
            _cardNumber = extractedCardNumber.toString();
            _isReadingCard = false;
          });

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card read successfully - Checking balance...'),
              backgroundColor: BuffaloColors.success,
              duration: Duration(seconds: 2),
            ),
          );

          // Auto-check balance after card read (no PIN required)
          await _checkBalance();
        } else {
          setState(() {
            _errorMessage = 'Failed to read card. Please try again.';
            _isReadingCard = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to read card. Please try again.';
          _isReadingCard = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error reading card: $e';
        _isReadingCard = false;
      });
    }
  }

  Future<void> _checkBalance() async {
    if (_cardNumber == null || _cardNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap your card first'),
          backgroundColor: BuffaloColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<BuffaloProvider>();
      // No PIN required for balance check
      final success = await provider.checkBalance(_cardNumber!);

      setState(() {
        _isChecking = false;
        _balanceChecked = success;
        if (!success) {
          _errorMessage = provider.lastBalanceResponse?.error ??
              'Failed to check balance';
        }
      });

      // Auto-print balance after successful check
      if (success && mounted) {
        await _autoPrintBalance();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking balance: $e';
        _isChecking = false;
        _balanceChecked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Balance'),
        backgroundColor: BuffaloColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BuffaloColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BuffaloColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: BuffaloColors.info,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tap your card to check your balance',
                      style: TextStyle(
                        fontSize: 14,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Card Reading Section
            Text(
              'Tap Your Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BuffaloColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            if (_cardNumber == null)
              InkWell(
                onTap: _isReadingCard ? null : _readCard,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: BuffaloColors.info,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: BuffaloColors.info.withOpacity(0.05),
                  ),
                  child: Column(
                    children: [
                      if (_isReadingCard)
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              BuffaloColors.info),
                        )
                      else
                        Icon(
                          Icons.contactless,
                          size: 80,
                          color: BuffaloColors.info,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _isReadingCard
                            ? 'Reading card...'
                            : 'Tap here to read card',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: BuffaloColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BuffaloColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BuffaloColors.success),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: BuffaloColors.success,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card Read Successfully',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BuffaloColors.success,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _maskCardNumber(_cardNumber!),
                            style: TextStyle(
                              fontSize: 14,
                              color: BuffaloColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _cardNumber = null;
                          _balanceChecked = false;
                        });
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: BuffaloColors.info,
                      ),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null && !_balanceChecked) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BuffaloColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BuffaloColors.error),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: BuffaloColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: BuffaloColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isChecking) ...[
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(BuffaloColors.info),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Checking balance...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Balance Display
            if (_balanceChecked) ...[
              const SizedBox(height: 24),
              Consumer<BuffaloProvider>(
                builder: (context, provider, _) {
                  final balanceResponse = provider.lastBalanceResponse;
                  if (balanceResponse?.data == null) {
                    return const SizedBox.shrink();
                  }

                  final balanceData = balanceResponse!.data!;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: BuffaloColors.surface,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: BuffaloColors.secondary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  size: 32,
                                  color: BuffaloColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Card Balance',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: BuffaloColors.textSecondary,
                                      ),
                                    ),
                                    if (balanceData.cardholderName != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        balanceData.cardholderName!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: BuffaloColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Divider(color: BuffaloColors.cardBorder),
                          const SizedBox(height: 16),
                          ...balanceData.balances.map((balance) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    balance.currencyCode,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: BuffaloColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    balance.formatted,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: BuffaloColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          if (balanceData.cardStatus != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: BuffaloColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: BuffaloColors.success,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Status: ${balanceData.cardStatus}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: BuffaloColors.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Menu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BuffaloColors.primary,
                    side: BorderSide(color: BuffaloColors.primary, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    final last4 = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $last4';
  }
}
