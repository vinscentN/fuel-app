import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../auth/mobile_login_screen.dart';
import '../gas_order/select_cylinders_screen.dart';
import '../gas_order/pending_requests_screen.dart';
import '../gas_order/delivery_scan_screen.dart';
import '../reports/incident_report_screen.dart';
import '../reports/generator_log_screen.dart';
import '../reports/reports_menu_screen.dart';
import 'dashboard_screen.dart';

class LandingMenuScreen extends StatefulWidget {
  const LandingMenuScreen({super.key});

  @override
  State<LandingMenuScreen> createState() => _LandingMenuScreenState();
}

class _LandingMenuScreenState extends State<LandingMenuScreen> {
  Future<void> _handleSale() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (!auth.isDeviceActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device not activated')),
      );
      return;
    }

    if (user == null || user.serviceStationId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service station not found')),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Fetch products by service station ID
    print('[LandingMenu] SALE tapped. Fetching products for station: ${user.serviceStationId}');
    await auth.fetchProductsByStation();
    print('[LandingMenu] Products available after fetch: ${auth.products.length}');

    if (!mounted) return;

    // Close loading indicator
    Navigator.of(context).pop();

    // Navigate to dashboard
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await authProvider.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        title: Row(
          children: [
            const Text(
              'GASMAN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
                fontFamily: 'Sans-serif',
              ),
            ),
            const SizedBox(width: 12),
            if (user?.fullName != null) ...[
              Container(
                height: 24,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user!.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Menu list for attendants
              _MenuList(onSale: _handleSale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(String title, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Text(title),
        ),
        onPressed: onPressed,
      ),
    );
  }
}


class _MenuList extends StatelessWidget {
  final VoidCallback onSale;

  const _MenuList({required this.onSale});

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      // SALE menu item
      _MenuItem(
        title: 'SALE',
        subtitle: 'Start a new fuel sale',
        icon: Icons.shopping_cart,
        color: AppColors.primary,
        onTap: onSale,
      ),

      // New menu items for attendants
      // Commented out for now - may be needed later
      // _MenuItem(
      //   title: 'FILL ORDER REQUEST',
      //   subtitle: 'Create cylinder refill requests',
      //   icon: Icons.propane_tank,
      //   color: const Color(0xFF6366F1),
      //   onTap: () {
      //     Navigator.of(context).push(
      //       MaterialPageRoute(builder: (_) => const SelectCylindersScreen()),
      //     );
      //   },
      // ),
      _MenuItem(
        title: 'PENDING REQUESTS',
        subtitle: 'Add cylinders and view QR codes',
        icon: Icons.qr_code_2,
        color: const Color(0xFF8B5CF6),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PendingRequestsScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'RECEIVE DELIVERY',
        subtitle: 'Scan QR to receive cylinder deliveries',
        icon: Icons.qr_code_scanner,
        color: const Color(0xFF10B981),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DeliveryScanScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'INCIDENT REPORTS',
        subtitle: 'Report issues at your station',
        icon: Icons.report_problem,
        color: const Color(0xFFFF9800),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'GENERATOR USAGE',
        subtitle: 'Track generator running times',
        icon: Icons.power,
        color: const Color(0xFFE91E63),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const GeneratorLogScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'REPORTS',
        subtitle: 'Batch cutoff, last sale, audit, reversals',
        icon: Icons.bar_chart,
        color: const Color(0xFF0EA5E9),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReportsMenuScreen()),
          );
        },
      ),

      // Commented out old menu items (can be re-enabled if needed)
      // _MenuItem(
      //   title: 'COUPON SALE',
      //   subtitle: 'Redeem a prepaid fuel voucher',
      //   icon: Icons.card_giftcard,
      //   color: AppColors.secondary,
      //   onTap: onCoupon,
      // ),
      // _MenuItem(
      //   title: 'BALANCE ENQUIRY',
      //   subtitle: 'Check card balances',
      //   icon: Icons.account_balance_wallet,
      //   color: AppColors.success,
      //   onTap: onBalance,
      // ),
      // _MenuItem(
      //   title: 'CARD PIN RESET',
      //   subtitle: 'Set a new 4-digit card PIN',
      //   icon: Icons.pin,
      //   color: AppColors.error,
      //   onTap: onPinReset,
      // ),
      // _MenuItem(
      //   title: 'REPORTS',
      //   subtitle: 'Batch cutoff, last sale, audit, reversals',
      //   icon: Icons.bar_chart,
      //   color: AppColors.info,
      //   onTap: onReports,
      // ),
      // _MenuItem(
      //   title: 'CHANGE',
      //   subtitle: 'Float top-up and change requests',
      //   icon: Icons.swap_horiz,
      //   color: AppColors.warning,
      //   onTap: onChange,
      // ),
    ];
    return Column(
      children: [
        for (final it in items) ...[
          _MenuTile(item: it),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _MenuItem({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;
  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Builder(
                    builder: (context) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                      child: Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: item.onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.08),
          child: Icon(item.icon, color: AppColors.primary),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(item.subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
