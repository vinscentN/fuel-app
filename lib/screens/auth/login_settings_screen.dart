import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../card/card_balance_screen.dart';
import '../card/card_pin_reset_screen.dart';
import '../home/card_number_screen.dart';
import '../reports/reports_menu_screen.dart';
import './operator_code_reset_screen.dart';

class LoginSettingsScreen extends StatelessWidget {
  const LoginSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            context,
            icon: Icons.account_balance_wallet,
            title: 'Card Balance Enquiry',
            subtitle: 'Read card and check current balance',
            builder: (_) => const CardBalanceScreen(),
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            icon: Icons.lock_reset,
            title: 'Card PIN Reset',
            subtitle: 'Set a new 4-digit card PIN',
            builder: (_) => const CardPinResetScreen(),
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            icon: Icons.password_outlined,
            title: 'Reset Operator Code',
            subtitle: 'Request reset code via email or SMS',
            builder: (_) => const OperatorCodeResetScreen(),
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            icon: Icons.assessment_outlined,
            title: 'Reports',
            subtitle: 'Batch cutoff, last sale, audit, reversals',
            builder: (_) => const ReportsMenuScreen(),
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            icon: Icons.contactless,
            title: 'Read Card (UID)',
            subtitle: 'Tap card to view UID number',
            builder: (_) => const CardNumberScreen(),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required WidgetBuilder builder,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.08),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: builder)),
      ),
    );
  }
}
