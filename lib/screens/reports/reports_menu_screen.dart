import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import 'batch_cutoff_screen.dart';
import 'batch_audit_screen.dart';
import 'last_sale_screen.dart';

class ReportsMenuScreen extends StatelessWidget {
  const ReportsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            context,
            icon: Icons.content_cut,
            title: 'Batch Cutoff',
            subtitle: 'View current batch transactions',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BatchCutoffScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Last Sale Transaction',
            subtitle: 'View the most recent sale',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LastSaleScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            icon: Icons.list_alt_outlined,
            title: 'Batch Audit',
            subtitle: 'Audit the current batch totals',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BatchAuditScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            icon: Icons.undo_outlined,
            title: 'Reversals',
            subtitle: 'View reversed or voided transactions',
            onTap: () => _comingSoon(context),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
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
        onTap: onTap,
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }
}
