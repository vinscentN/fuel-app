import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/simba_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/pos_service.dart';

class SimbaBalanceScreen extends StatefulWidget {
  const SimbaBalanceScreen({Key? key}) : super(key: key);

  @override
  State<SimbaBalanceScreen> createState() => _SimbaBalanceScreenState();
}

class _SimbaBalanceScreenState extends State<SimbaBalanceScreen>
    with SingleTickerProviderStateMixin {
  final PosService _posService = PosService();

  bool _isReadingCard = false;
  bool _isLoadingBalance = false;
  bool _hasResult = false;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Auto-start card reading when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readCard();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _readCard() async {
    setState(() {
      _isReadingCard = true;
      _isLoadingBalance = false;
      _hasResult = false;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Starting card read for balance check...');
      final result = await _posService.readNfc();
      print('DEBUG: Card read result: $result');

      if (result != null) {
        // Extract card number from various possible fields
        final extractedCardNumber = result['pan'] ??
            result['card_number'] ??
            result['uid'] ??
            result['cardNumber'];

        print('DEBUG: Extracted card number: $extractedCardNumber');

        if (extractedCardNumber != null &&
            extractedCardNumber.toString().isNotEmpty) {
          final cardNumber = extractedCardNumber.toString();

          setState(() {
            _isReadingCard = false;
            _isLoadingBalance = true;
          });

          if (!mounted) return;

          print('DEBUG: Getting balance for card: $cardNumber');

          // Get card balance
          final provider = context.read<SimbaProvider>();
          final success = await provider.getCardBalance(cardNumber);

          print('DEBUG: Balance check success: $success');

          setState(() {
            _isLoadingBalance = false;
            _hasResult = true;
          });

          if (!success) {
            setState(() {
              _errorMessage = provider.lastBalanceResponse?.message ??
                  'Failed to get card balance';
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_errorMessage!),
                  backgroundColor: BuffaloColors.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        } else {
          setState(() {
            _errorMessage = 'Failed to read card number. Please try again.';
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
      print('DEBUG: Exception during card read: $e');
      setState(() {
        _errorMessage = 'Error reading card: $e';
        _isReadingCard = false;
        _isLoadingBalance = false;
      });
    }
  }

  Future<void> _printReceipt() async {
    final provider = context.read<SimbaProvider>();
    final posProvider = context.read<PosProvider>();
    final balanceResponse = provider.lastBalanceResponse;

    if (balanceResponse == null || !balanceResponse.success) return;

    final now = DateTime.now();

    await posProvider.printSimbaBalanceReceipt(
      companyName: 'CLUB MATE POS',
      date: DateFormat('dd/MM/yyyy').format(now),
      time: DateFormat('HH:mm:ss').format(now),
      cardNo: balanceResponse.cardNumber ?? 'N/A',
      status: balanceResponse.status ?? 'unknown',
      currency: balanceResponse.currency ?? '',
      balance: balanceResponse.balance ?? '0.00',
      expiryDate: balanceResponse.expiryDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuffaloColors.background,
      appBar: AppBar(
        title: const Text('Card Balance Enquiry'),
        backgroundColor: BuffaloColors.primary,
        elevation: 0,
      ),
      body: Consumer<SimbaProvider>(
        builder: (context, provider, child) {
          final balanceResponse = provider.lastBalanceResponse;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated card icon or result
                  if (_isReadingCard)
                    RotationTransition(
                      turns: _animationController,
                      child: const Icon(
                        Icons.contactless,
                        size: 120,
                        color: BuffaloColors.info,
                      ),
                    )
                  else if (_isLoadingBalance)
                    const SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(BuffaloColors.info),
                      ),
                    )
                  else if (_errorMessage != null)
                    const Icon(
                      Icons.error_outline,
                      size: 120,
                      color: BuffaloColors.error,
                    )
                  else if (_hasResult && balanceResponse != null && balanceResponse.success)
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 120,
                      color: BuffaloColors.success,
                    )
                  else
                    const Icon(
                      Icons.contactless,
                      size: 120,
                      color: BuffaloColors.info,
                    ),

                  const SizedBox(height: 40),

                  // Status text
                  if (_isReadingCard)
                    const Text(
                      'Waiting for card tap...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else if (_isLoadingBalance)
                    const Text(
                      'Loading balance...',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    )
                  else if (_errorMessage != null)
                    Column(
                      children: [
                        const Text(
                          'Balance Check Failed',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: BuffaloColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: BuffaloColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  else if (_hasResult && balanceResponse != null && balanceResponse.success)
                    Column(
                      children: [
                        // Balance card
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [BuffaloColors.info, BuffaloColors.infoLight],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'CURRENT BALANCE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${balanceResponse.currency ?? ''} ${balanceResponse.balance ?? '0.00'}',
                                  style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Card details
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  'Card Number',
                                  balanceResponse.cardNumber ?? 'N/A',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  'Status',
                                  (balanceResponse.status ?? 'unknown').toUpperCase(),
                                  valueColor: balanceResponse.status == 'active'
                                      ? BuffaloColors.success
                                      : BuffaloColors.error,
                                ),
                                if (balanceResponse.expiryDate != null) ...[
                                  const Divider(height: 24),
                                  _buildInfoRow(
                                    'Expiry Date',
                                    balanceResponse.expiryDate!,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Please tap your card',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 40),

                  // Action buttons
                  if (_hasResult && balanceResponse != null && balanceResponse.success)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _printReceipt();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Printing receipt...'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: BuffaloColors.success,
                                ),
                              );
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Print Receipt'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BuffaloColors.info,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _readCard,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Check Another Card'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BuffaloColors.info,
                              side: const BorderSide(color: BuffaloColors.info, width: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (_errorMessage != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _readCard,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BuffaloColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: BuffaloColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? BuffaloColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
