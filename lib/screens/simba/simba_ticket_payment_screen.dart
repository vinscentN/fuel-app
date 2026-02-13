import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/simba_provider.dart';
import '../../services/pos_service.dart';
import '../../models/api_event.dart';
import '../../models/api_ticket.dart';
import 'simba_ticket_receipt_screen.dart';

class SimbaTicketPaymentScreen extends StatefulWidget {
  final ApiEvent event;
  final TicketType ticketType;

  const SimbaTicketPaymentScreen({
    Key? key,
    required this.event,
    required this.ticketType,
  }) : super(key: key);

  @override
  State<SimbaTicketPaymentScreen> createState() =>
      _SimbaTicketPaymentScreenState();
}

class _SimbaTicketPaymentScreenState extends State<SimbaTicketPaymentScreen>
    with SingleTickerProviderStateMixin {
  final PosService _posService = PosService();

  String _paymentMethod = 'card';
  bool _isReadingCard = false;
  bool _isProcessingPayment = false;
  String? _errorMessage;
  late AnimationController _animationController;

  // For cash/mobile payments (no card required, but need user_id)
  final int _userId = 1; // Placeholder user ID

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
    super.dispose();
  }

  void _processCashOrMobilePayment() async {
    setState(() {
      _isProcessingPayment = true;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Processing $_paymentMethod payment');

      final provider = context.read<SimbaProvider>();
      final success = await provider.purchaseTicket(
        eventId: widget.event.id,
        ticketTypeId: widget.ticketType.id,
        userId: _userId,
        paymentMethod: _paymentMethod,
      );

      print('DEBUG: Ticket purchase success: $success');

      setState(() {
        _isProcessingPayment = false;
      });

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SimbaTicketReceiptScreen(
              event: widget.event,
              ticketType: widget.ticketType,
              response: provider.lastTicketPurchase!,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = provider.lastTicketPurchase?.message ??
              'Payment failed. Please try again.';
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
    } catch (e) {
      print('DEBUG: Exception during payment: $e');
      setState(() {
        _errorMessage = 'Error processing payment: $e';
        _isProcessingPayment = false;
      });
    }
  }

  Future<void> _readCardAndPurchase() async {
    setState(() {
      _isReadingCard = true;
      _isProcessingPayment = false;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Starting card read for ticket purchase...');
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
            _isProcessingPayment = true;
          });

          if (!mounted) return;

          print('DEBUG: Processing ticket purchase for card: $cardNumber');

          // Process the purchase
          final provider = context.read<SimbaProvider>();
          final success = await provider.purchaseTicket(
            eventId: widget.event.id,
            ticketTypeId: widget.ticketType.id,
            cardNumber: cardNumber,
            paymentMethod: 'card',
          );

          print('DEBUG: Ticket purchase success: $success');

          setState(() {
            _isProcessingPayment = false;
          });

          if (success && mounted) {
            // Navigate to receipt screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SimbaTicketReceiptScreen(
                  event: widget.event,
                  ticketType: widget.ticketType,
                  response: provider.lastTicketPurchase!,
                ),
              ),
            );
          } else {
            setState(() {
              _errorMessage = provider.lastTicketPurchase?.message ??
                  'Purchase failed. Please try again.';
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
        _isProcessingPayment = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuffaloColors.background,
      appBar: AppBar(
        title: const Text('Payment Method'),
        backgroundColor: BuffaloColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Purchase summary
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Purchase Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BuffaloColors.textPrimary,
                            ),
                          ),
                          const Divider(height: 20),
                          _buildSummaryRow('Event', widget.event.name),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Ticket Type', widget.ticketType.name),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Venue', widget.event.venue),
                          const SizedBox(height: 8),
                          _buildSummaryRow(
                            'Date',
                            widget.event.startDate.split('T')[0],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: BuffaloColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${widget.ticketType.currency?.symbol ?? ''} ${widget.ticketType.defaultPrice}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: BuffaloColors.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment method selection
                  if (!_isReadingCard && !_isProcessingPayment) ...[
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _PaymentMethodCard(
                      icon: Icons.credit_card,
                      title: 'Card Payment',
                      description: 'Tap your membership card',
                      value: 'card',
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
                    const SizedBox(height: 12),
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
                  ],

                  // Card tap / processing UI
                  if (_isReadingCard || _isProcessingPayment) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          if (_isReadingCard)
                            RotationTransition(
                              turns: _animationController,
                              child: const Icon(
                                Icons.contactless,
                                size: 120,
                                color: BuffaloColors.tertiary,
                              ),
                            )
                          else
                            const SizedBox(
                              width: 96,
                              height: 96,
                              child: CircularProgressIndicator(
                                strokeWidth: 6,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  BuffaloColors.tertiary,
                                ),
                              ),
                            ),
                          const SizedBox(height: 32),
                          Text(
                            _isReadingCard
                                ? 'Waiting for card tap...'
                                : 'Processing payment...',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: BuffaloColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      color: BuffaloColors.error.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: BuffaloColors.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: BuffaloColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom button
          if (!_isReadingCard && !_isProcessingPayment)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: BuffaloColors.cardShadow,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _paymentMethod == 'card'
                        ? _readCardAndPurchase
                        : _processCashOrMobilePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BuffaloColors.tertiary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _paymentMethod == 'card'
                          ? 'Tap Card to Purchase'
                          : 'Complete Purchase',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: BuffaloColors.textPrimary,
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
          color: isSelected ? BuffaloColors.tertiary : BuffaloColors.cardBorder,
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
                activeColor: BuffaloColors.tertiary,
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? BuffaloColors.tertiary
                    : BuffaloColors.textSecondary,
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
