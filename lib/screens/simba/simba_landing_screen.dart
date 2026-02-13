import 'package:flutter/material.dart';
import '../../utils/buffalo_colors.dart';
import 'simba_sale_screen.dart';
import 'simba_balance_screen.dart';
import 'simba_topup_screen.dart';
import 'simba_ticket_screen.dart';

class SimbaLandingScreen extends StatelessWidget {
  const SimbaLandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: BuffaloColors.headerGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Logo/Brand Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    Text(
                      'CLUB MATE',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textOnPrimary,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'POINT OF SALE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BuffaloColors.secondary,
                        letterSpacing: 3.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Menu Options
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: BuffaloColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'What would you like to do?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: BuffaloColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _MenuButton(
                          icon: Icons.shopping_cart,
                          title: 'Make a Sale',
                          description: 'Purchase products',
                          gradient: BuffaloColors.secondaryGradient,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SimbaSaleScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          icon: Icons.account_balance_wallet,
                          title: 'Card Balance Enquiry',
                          description: 'Check card balance',
                          gradient: const LinearGradient(
                            colors: [
                              BuffaloColors.info,
                              BuffaloColors.infoLight
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SimbaBalanceScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          icon: Icons.add_card,
                          title: 'Card Top Up',
                          description: 'Add funds to card',
                          gradient: const LinearGradient(
                            colors: [
                              BuffaloColors.success,
                              BuffaloColors.successLight
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SimbaTopUpScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          icon: Icons.confirmation_number,
                          title: 'Ticket Sale',
                          description: 'Purchase event tickets',
                          gradient: const LinearGradient(
                            colors: [
                              BuffaloColors.tertiary,
                              BuffaloColors.tertiaryLight
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SimbaTicketScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;
  final VoidCallback onTap;

  const _MenuButton({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: BuffaloColors.cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
