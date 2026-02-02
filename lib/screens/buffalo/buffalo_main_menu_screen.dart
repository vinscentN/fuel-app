import 'package:flutter/material.dart';
import '../../utils/buffalo_colors.dart';
import 'buffalo_card_tap_screen.dart';
import 'buffalo_balance_screen.dart';
import 'buffalo_pin_reset_screen.dart';
import 'buffalo_test_connection_screen.dart';

class BuffaloMainMenuScreen extends StatelessWidget {
  const BuffaloMainMenuScreen({Key? key}) : super(key: key);

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
                      'The Buffalo Brewing',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: BuffaloColors.textOnPrimary,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'COMPANY',
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
                          title: 'Make a Purchase',
                          description: 'Tap card to continue',
                          gradient: BuffaloColors.secondaryGradient,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BuffaloCardTapScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          icon: Icons.account_balance_wallet,
                          title: 'Check Balance',
                          description: 'View card balance',
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
                                builder: (context) =>
                                    const BuffaloBalanceScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _MenuButton(
                          icon: Icons.network_check,
                          title: 'Test Connection',
                          description: 'Test server connectivity',
                          gradient: const LinearGradient(
                            colors: [
                              Colors.purple,
                              Colors.purpleAccent,
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BuffaloTestConnectionScreen(),
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
