import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../utils/buffalo_colors.dart';
import '../../models/api_event.dart';
import '../../models/api_ticket.dart';
import '../../providers/pos_provider.dart';

class SimbaTicketReceiptScreen extends StatefulWidget {
  final ApiEvent event;
  final TicketType ticketType;
  final TicketPurchaseResponse response;

  const SimbaTicketReceiptScreen({
    Key? key,
    required this.event,
    required this.ticketType,
    required this.response,
  }) : super(key: key);

  @override
  State<SimbaTicketReceiptScreen> createState() => _SimbaTicketReceiptScreenState();
}

class _SimbaTicketReceiptScreenState extends State<SimbaTicketReceiptScreen> {
  bool _hasPrinted = false;

  @override
  void initState() {
    super.initState();
    // Auto-print receipt when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPrintReceipt();
    });
  }

  Future<void> _autoPrintReceipt() async {
    if (_hasPrinted) return;
    _hasPrinted = true;
    await _printReceipt(copyType: 'CUSTOMER COPY');
  }

  Future<void> _printReceipt({String copyType = 'CUSTOMER COPY'}) async {
    final posProvider = context.read<PosProvider>();
    final now = DateTime.now();

    await posProvider.printSimbaTicketReceipt(
      companyName: 'CLUB MATE POS',
      ticketNumber: widget.response.ticket?.ticketNumber ?? 'N/A',
      date: DateFormat('dd/MM/yyyy').format(now),
      time: DateFormat('HH:mm:ss').format(now),
      eventName: widget.event.name,
      venue: widget.event.venue,
      eventDate: widget.event.startDate.split('T')[0],
      ticketType: widget.ticketType.name,
      price: widget.response.ticket?.price ?? widget.ticketType.defaultPrice,
      currency: widget.ticketType.currency?.symbol ?? '',
      paymentMethod: widget.response.ticket?.paymentMethod.toUpperCase() ?? 'N/A',
      cardNo: widget.response.ticket?.paymentMethod == 'card'
          ? 'Card Payment'
          : null,
      balanceBefore: widget.response.transaction?.balanceBefore,
      balanceAfter: widget.response.transaction?.balanceAfter,
      copyType: copyType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuffaloColors.background,
      appBar: AppBar(
        title: const Text('Ticket Purchased'),
        backgroundColor: BuffaloColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Success icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: BuffaloColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.confirmation_number,
                        size: 80,
                        color: BuffaloColors.success,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Ticket Purchase Successful!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Ticket card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              BuffaloColors.tertiary,
                              BuffaloColors.tertiaryLight,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.confirmation_number,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.response.ticket?.ticketNumber ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.event.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.ticketType.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Receipt details
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'TICKET DETAILS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: BuffaloColors.textPrimary,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const Divider(height: 24),
                            _buildReceiptRow('Event', widget.event.name),
                            const SizedBox(height: 12),
                            _buildReceiptRow('Venue', widget.event.venue),
                            const SizedBox(height: 12),
                            _buildReceiptRow(
                              'Date',
                              widget.event.startDate.split('T')[0],
                            ),
                            const SizedBox(height: 12),
                            _buildReceiptRow('Ticket Type', widget.ticketType.name),
                            const Divider(height: 24),
                            if (widget.response.ticket != null) ...[
                              _buildReceiptRow(
                                'Ticket Number',
                                widget.response.ticket!.ticketNumber,
                                isBold: true,
                              ),
                              const SizedBox(height: 12),
                              _buildReceiptRow(
                                'Status',
                                widget.response.ticket!.status.toUpperCase(),
                                valueColor: BuffaloColors.success,
                              ),
                              const SizedBox(height: 12),
                              _buildReceiptRow(
                                'Payment Method',
                                widget.response.ticket!.paymentMethod.toUpperCase(),
                              ),
                              const Divider(height: 24),
                            ],
                            _buildReceiptRow(
                              'Price',
                              '${widget.ticketType.currency?.symbol ?? ''} ${widget.response.ticket?.price ?? widget.ticketType.defaultPrice}',
                              isBold: true,
                              isLarge: true,
                            ),
                            if (widget.response.transaction != null) ...[
                              const Divider(height: 24),
                              _buildReceiptRow(
                                'Transaction #',
                                widget.response.transaction!.transactionNumber,
                              ),
                              const SizedBox(height: 12),
                              _buildReceiptRow(
                                'Transaction Status',
                                widget.response.transaction!.status.toUpperCase(),
                                valueColor: BuffaloColors.success,
                              ),
                              if (widget.response.transaction!.balanceBefore != null) ...[
                                const SizedBox(height: 12),
                                _buildReceiptRow(
                                  'Balance Before',
                                  '${widget.ticketType.currency?.symbol ?? ''} ${widget.response.transaction!.balanceBefore}',
                                ),
                              ],
                              if (widget.response.transaction!.balanceAfter != null) ...[
                                const SizedBox(height: 12),
                                _buildReceiptRow(
                                  'Balance After',
                                  '${widget.ticketType.currency?.symbol ?? ''} ${widget.response.transaction!.balanceAfter}',
                                  isBold: true,
                                ),
                              ],
                            ],
                            if (widget.response.balance != null) ...[
                              const Divider(height: 24),
                              _buildReceiptRow(
                                'Current Balance',
                                '${widget.ticketType.currency?.symbol ?? ''} ${widget.response.balance}',
                                isBold: true,
                                valueColor: BuffaloColors.info,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Important note
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BuffaloColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: BuffaloColors.info.withOpacity(0.3),
                        ),
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
                              'Please present this ticket at the event entrance.',
                              style: TextStyle(
                                fontSize: 14,
                                color: BuffaloColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        backgroundColor: BuffaloColors.tertiary,
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
                      onPressed: () {
                        // Pop until we get back to the landing screen
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Return to Menu'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BuffaloColors.tertiary,
                        side: const BorderSide(color: BuffaloColors.tertiary, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    bool isLarge = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            color: BuffaloColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 20 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? BuffaloColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
