import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import 'batch_cutoff_screen.dart';
import 'batch_audit_screen.dart';
import 'last_sale_screen.dart';
import 'incident_report_screen.dart';
import 'generator_log_screen.dart';

class ReportsMenuScreen extends StatelessWidget {
  const ReportsMenuScreen({super.key});

  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  @override
  Widget build(BuildContext context) {
    final items = [
      _ReportItem(
        icon: Icons.content_cut_rounded,
        title: 'Batch Cutoff',
        subtitle: 'View current batch transactions',
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BatchCutoffScreen())),
      ),
      _ReportItem(
        icon: Icons.receipt_long_rounded,
        title: 'Last Sale Transaction',
        subtitle: 'View the most recent sale',
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LastSaleScreen())),
      ),
      _ReportItem(
        icon: Icons.list_alt_rounded,
        title: 'Batch Audit',
        subtitle: 'Audit the current batch totals',
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BatchAuditScreen())),
      ),
      _ReportItem(
        icon: Icons.report_problem_rounded,
        title: 'Incident Reports',
        subtitle: 'Report issues at your station',
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IncidentReportScreen())),
      ),
      _ReportItem(
        icon: Icons.power_rounded,
        title: 'Generator Usage',
        subtitle: 'Track generator running times',
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GeneratorLogScreen())),
      ),
    ];

    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          const Text(
            'REPORTS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _navyMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EDF5)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                color: Color(0xFFF0F4FA),
                indent: 14,
                endIndent: 14,
              ),
              itemBuilder: (context, i) => _buildTile(items[i]),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Container(
        decoration: const BoxDecoration(
          color: _navy,
          border: Border(
              bottom: BorderSide(color: Color(0x22FFFFFF), width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white),
                  splashRadius: 20,
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bar_chart_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Station reports & logs',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile(_ReportItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, color: _navy, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: _navyMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _navyMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReportItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}