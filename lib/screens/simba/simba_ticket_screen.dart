import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/simba_provider.dart';
import '../../models/api_event.dart';
import '../../models/api_ticket.dart';
import 'simba_ticket_payment_screen.dart';

class SimbaTicketScreen extends StatefulWidget {
  const SimbaTicketScreen({Key? key}) : super(key: key);

  @override
  State<SimbaTicketScreen> createState() => _SimbaTicketScreenState();
}

class _SimbaTicketScreenState extends State<SimbaTicketScreen> {
  ApiEvent? _selectedEvent;
  TicketType? _selectedTicketType;
  bool _loadingTicketTypes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SimbaProvider>().fetchActiveEvents();
    });
  }

  Future<void> _selectEvent(ApiEvent event) async {
    setState(() {
      _selectedEvent = event;
      _selectedTicketType = null;
      _loadingTicketTypes = true;
    });

    final provider = context.read<SimbaProvider>();
    await provider.fetchTicketTypes(event.id);

    setState(() {
      _loadingTicketTypes = false;
    });
  }

  void _proceedToPayment() {
    if (_selectedEvent == null || _selectedTicketType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event and ticket type'),
          backgroundColor: BuffaloColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimbaTicketPaymentScreen(
          event: _selectedEvent!,
          ticketType: _selectedTicketType!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuffaloColors.background,
      appBar: AppBar(
        title: const Text('Ticket Sale'),
        backgroundColor: BuffaloColors.primary,
        elevation: 0,
      ),
      body: Consumer<SimbaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingEvents) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(BuffaloColors.tertiary),
              ),
            );
          }

          if (provider.eventsError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: BuffaloColors.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load events',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.eventsError!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: BuffaloColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        provider.fetchActiveEvents();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BuffaloColors.tertiary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.events.isEmpty) {
            return const Center(
              child: Text(
                'No active events',
                style: TextStyle(
                  fontSize: 18,
                  color: BuffaloColors.textSecondary,
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Events section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Event',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: BuffaloColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...provider.events.map((event) {
                              final isSelected = _selectedEvent?.id == event.id;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Card(
                                  elevation: isSelected ? 4 : 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? BuffaloColors.tertiary
                                          : BuffaloColors.cardBorder,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => _selectEvent(event),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  event.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: BuffaloColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: BuffaloColors.tertiary,
                                                  size: 28,
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: BuffaloColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                event.venue,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: BuffaloColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: BuffaloColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                event.startDate.split('T')[0],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: BuffaloColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: event.status == 'upcoming'
                                                      ? BuffaloColors.info.withOpacity(0.2)
                                                      : BuffaloColors.success.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  event.status.toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: event.status == 'upcoming'
                                                        ? BuffaloColors.info
                                                        : BuffaloColors.success,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '${event.ticketsAvailable} tickets left',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: event.ticketsAvailable > 0
                                                      ? BuffaloColors.success
                                                      : BuffaloColors.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      // Ticket types section
                      if (_selectedEvent != null) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Ticket Type',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: BuffaloColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_loadingTicketTypes)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        BuffaloColors.tertiary,
                                      ),
                                    ),
                                  ),
                                )
                              else if (provider.ticketTypesError != null)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      provider.ticketTypesError!,
                                      style: const TextStyle(
                                        color: BuffaloColors.error,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                )
                              else if (provider.ticketTypes.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No ticket types available',
                                      style: TextStyle(
                                        color: BuffaloColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...provider.ticketTypes.map((ticketType) {
                                  final isSelected =
                                      _selectedTicketType?.id == ticketType.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Card(
                                      elevation: isSelected ? 4 : 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: isSelected
                                              ? BuffaloColors.tertiary
                                              : BuffaloColors.cardBorder,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedTicketType = ticketType;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      ticketType.name,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: BuffaloColors.textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '${ticketType.currency?.symbol ?? ''} ${ticketType.defaultPrice}',
                                                      style: const TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                        color: BuffaloColors.tertiary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                const Icon(
                                                  Icons.check_circle,
                                                  color: BuffaloColors.tertiary,
                                                  size: 28,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom button
              if (_selectedEvent != null && _selectedTicketType != null)
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
                        onPressed: _proceedToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BuffaloColors.tertiary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Proceed to Payment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
