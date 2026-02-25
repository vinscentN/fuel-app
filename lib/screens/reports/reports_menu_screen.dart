import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import 'batch_cutoff_screen.dart';
import 'batch_audit_screen.dart';
import 'last_sale_screen.dart';
import 'incident_report_screen.dart';
import 'generator_log_screen.dart';

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
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Last Sale Transaction',
            subtitle: 'View the most recent sale',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LastSaleScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.list_alt_outlined,
            title: 'Batch Audit',
            subtitle: 'Audit the current batch totals',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BatchAuditScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.report_problem_outlined,
            title: 'Incident Reports',
            subtitle: 'Report issues at your station',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.power_outlined,
            title: 'Generator Usage',
            subtitle: 'Track generator running times',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GeneratorLogScreen()),
            ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withOpacity(0.08),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
