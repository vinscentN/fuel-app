import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/simba_provider.dart';
import '../../providers/pos_provider.dart';
import '../../services/pos_service.dart';

class SimbaTopUpScreen extends StatefulWidget {
  const SimbaTopUpScreen({Key? key}) : super(key: key);

  @override
  State<SimbaTopUpScreen> createState() => _SimbaTopUpScreenState();
}

class _SimbaTopUpScreenState extends State<SimbaTopUpScreen>
    with SingleTickerProviderStateMixin {
  final PosService _posService = PosService();
  final TextEditingController _amountController = TextEditingController();

  String _paymentMethod = 'mobile';
  bool _isReadingCard = false;
  bool _isProcessingTopUp = false;
  bool _hasResult = false;
  String? _errorMessage;
  late AnimationController _animationController;

  // Predefined amounts
  final List<double> _quickAmounts = [10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _startTopUp() {
    final amount = double.tryParse(_amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: BuffaloColors.error,
        ),
      );
      return;
    }

    _readCard();
  }

  Future<void> _readCard() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isReadingCard = true;
      _isProcessingTopUp = false;
      _hasResult = false;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Starting card read for top-up...');
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
            _isProcessingTopUp = true;
          });

          if (!mounted) return;

          print('DEBUG: Processing top-up for card: $cardNumber');
          print('DEBUG: Amount: $amount, Payment method: $_paymentMethod');

          // Process the top-up
          final provider = context.read<SimbaProvider>();
          final success = await provider.topUpCard(
            cardNumber: cardNumber,
            amount: amount,
            paymentMethod: _paymentMethod,
            description: 'Card top-up via POS',
          );

          print('DEBUG: Top-up success: $success');

          setState(() {
            _isProcessingTopUp = false;
            _hasResult = true;
          });

          // Auto-print receipt on success
          if (success && mounted) {
            await _printReceipt(copyType: 'CUSTOMER COPY');
          }

          if (!success) {
            setState(() {
              _errorMessage = provider.lastTopUpResponse?.message ??
                  'Top-up failed. Please try again.';
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
        _isProcessingTopUp = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _amountController.clear();
      _paymentMethod = 'mobile';
      _isReadingCard = false;
      _isProcessingTopUp = false;
      _hasResult = false;
      _errorMessage = null;
    });
  }

  Future<void> _printReceipt({String copyType = 'CUSTOMER COPY'}) async {
    final provider = context.read<SimbaProvider>();
    final posProvider = context.read<PosProvider>();
    final topUpResponse = provider.lastTopUpResponse;

    if (topUpResponse == null || !topUpResponse.success) return;

    final now = DateTime.now();
    final amount = _amountController.text;

    await posProvider.printSimbaTopUpReceipt(
      companyName: 'CLUB MATE POS',
      receiptNumber: topUpResponse.transaction?.transactionNumber ?? 'N/A',
      date: DateFormat('dd/MM/yyyy').format(now),
      time: DateFormat('HH:mm:ss').format(now),
      cardNo: topUpResponse.transaction?.membershipCardId?.toString() ?? 'N/A',
      amount: amount,
      currency: '\$',
      paymentMethod: _paymentMethod.toUpperCase(),
      balanceBefore: topUpResponse.transaction?.balanceBefore,
      balanceAfter: topUpResponse.transaction?.balanceAfter,
      copyType: copyType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuffaloColors.background,
      appBar: AppBar(
        title: const Text('Card Top Up'),
        backgroundColor: BuffaloColors.primary,
        elevation: 0,
      ),
      body: Consumer<SimbaProvider>(
        builder: (context, provider, child) {
          final topUpResponse = provider.lastTopUpResponse;

          // Show input form if not reading card or processing
          if (!_isReadingCard && !_isProcessingTopUp && !_hasResult) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BuffaloColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount input
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: BuffaloColors.secondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: BuffaloColors.secondary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick amount buttons
                  const Text(
                    'Quick Amounts',
                    style: TextStyle(
                      fontSize: 14,
                      color: BuffaloColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickAmounts.map((amount) {
                      return ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _amountController.text = amount.toStringAsFixed(0);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: BuffaloColors.secondary,
                          side: const BorderSide(color: BuffaloColors.secondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('\$${amount.toStringAsFixed(0)}'),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Payment method selection
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BuffaloColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _PaymentMethodCard(
                    icon: Icons.phone_android,
                    title: 'Mobile Money',
                    description: 'Pay via mobile money',
                    value: 'mobile',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _PaymentMethodCard(
                    icon: Icons.money,
                    title: 'Cash',
                    description: 'Pay with cash',
                    value: 'cash',
                    groupValue: _paymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  // Proceed button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startTopUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BuffaloColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Tap Card to Top Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Show card tap / processing / result
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display amount being topped up
                  if (_isReadingCard || _isProcessingTopUp)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Top-Up Amount',
                              style: TextStyle(
                                fontSize: 14,
                                color: BuffaloColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${_amountController.text}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: BuffaloColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Animated icon
                  if (_isReadingCard)
                    RotationTransition(
                      turns: _animationController,
                      child: const Icon(
                        Icons.contactless,
                        size: 120,
                        color: BuffaloColors.success,
                      ),
                    )
                  else if (_isProcessingTopUp)
                    const SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        strokeWidth: 6,
                        valueColor: AlwaysStoppedAnimation<Color>(BuffaloColors.success),
                      ),
                    )
                  else if (_errorMessage != null)
                    const Icon(
                      Icons.error_outline,
                      size: 120,
                      color: BuffaloColors.error,
                    )
                  else if (_hasResult && topUpResponse != null && topUpResponse.success)
                    const Icon(
                      Icons.check_circle,
                      size: 120,
                      color: BuffaloColors.success,
                    )
                  else
                    const Icon(
                      Icons.contactless,
                      size: 120,
                      color: BuffaloColors.success,
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
                  else if (_isProcessingTopUp)
                    const Text(
                      'Processing top-up...',
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
                          'Top-Up Failed',
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
                  else if (_hasResult && topUpResponse != null && topUpResponse.success)
                    Column(
                      children: [
                        const Text(
                          'Top-Up Successful!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: BuffaloColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Success details card
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  'Transaction #',
                                  topUpResponse.transaction?.transactionNumber ?? 'N/A',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  'Amount Added',
                                  '\$${topUpResponse.transaction?.amount ?? _amountController.text}',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  'Previous Balance',
                                  '\$${topUpResponse.transaction?.balanceBefore ?? '0.00'}',
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  'New Balance',
                                  '\$${topUpResponse.balance ?? topUpResponse.transaction?.balanceAfter ?? '0.00'}',
                                  valueColor: BuffaloColors.success,
                                  valueBold: true,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 40),

                  // Action buttons
                  if (_errorMessage != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _readCard,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BuffaloColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                  else if (_hasResult && topUpResponse != null && topUpResponse.success)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _printReceipt(copyType: 'MERCHANT COPY');
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Printing merchant copy...'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: BuffaloColors.success,
                                ),
                              );
                            },
                            icon: const Icon(Icons.print),
                            label: const Text('Print Merchant Copy'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BuffaloColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Top Up Another Card'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BuffaloColors.success,
                              side: const BorderSide(color: BuffaloColors.success, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text(
                              'Back to Menu',
                              style: TextStyle(
                                fontSize: 16,
                                color: BuffaloColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool valueBold = false,
  }) {
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
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? BuffaloColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? BuffaloColors.success : BuffaloColors.cardBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: BuffaloColors.success,
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 32,
                color: isSelected ? BuffaloColors.success : BuffaloColors.textSecondary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? BuffaloColors.textPrimary
                            : BuffaloColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: BuffaloColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
