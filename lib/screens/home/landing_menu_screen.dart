import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/pos_service.dart';
import '../../utils/colors.dart';
import 'dashboard_screen.dart';
import '../coupon/coupon_redemption_screen.dart';
import '../card/card_balance_screen.dart';
import '../card/card_pin_reset_screen.dart';
import '../change/change_topup_screen.dart';
import '../reports/reports_menu_screen.dart';

class LandingMenuScreen extends StatefulWidget {
  const LandingMenuScreen({super.key});

  @override
  State<LandingMenuScreen> createState() => _LandingMenuScreenState();
}

class _LandingMenuScreenState extends State<LandingMenuScreen> {

  Future<void> _handleSale() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isDeviceActive) {
      // Device should have been activated on splash; if not, just inform the user.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device not activated')), 
      );
      return;
    }
    // Always fetch fresh products when SALE is tapped
    print('[LandingMenu] SALE tapped. Fetching latest products...');
    await auth.fetchLatestProducts();
    print('[LandingMenu] Products available after ensure: ${auth.products.length}');
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo on the left
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              clipBehavior: Clip.hardEdge,
              child: Image.asset('images/logo.png', fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            // Station name with reduced font size
            Flexible(
              child: Text(
                (auth.serviceStationName?.isNotEmpty == true
                    ? auth.serviceStationName!
                    : 'Fuel Mate'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16, // reduced size
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Removed header card above SALE per request
              _MenuList(
                onSale: _handleSale,
                onCoupon: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CouponRedemptionScreen()),
                ),
                onReports: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsMenuScreen()),
                ),
                onChange: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangeTopupScreen()),
                  );
                },
                onBalance: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CardBalanceScreen()),
                ),
                onPinReset: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CardPinResetScreen()),
                ),
              ),
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
  final VoidCallback onCoupon;
  final VoidCallback onReports;
  final VoidCallback onChange;
  final VoidCallback onBalance;
  final VoidCallback onPinReset;

  const _MenuList({
    required this.onSale,
    required this.onCoupon,
    required this.onReports,
    required this.onChange,
    required this.onBalance,
    required this.onPinReset,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_MenuItem>[
      _MenuItem(
        title: 'SALE',
        subtitle: 'Start a new fuel sale',
        icon: Icons.shopping_cart,
        color: AppColors.primary,
        onTap: onSale,
      ),
      _MenuItem(
        title: 'COUPON SALE',
        subtitle: 'Redeem a prepaid fuel voucher',
        icon: Icons.card_giftcard,
        color: AppColors.secondary,
        onTap: onCoupon,
      ),
      _MenuItem(
        title: 'BALANCE ENQUIRY',
        subtitle: 'Check card balances',
        icon: Icons.account_balance_wallet,
        color: AppColors.success,
        onTap: onBalance,
      ),
      _MenuItem(
        title: 'CARD PIN RESET',
        subtitle: 'Set a new 4-digit card PIN',
        icon: Icons.pin,
        color: AppColors.error,
        onTap: onPinReset,
      ),
      _MenuItem(
        title: 'REPORTS',
        subtitle: 'Batch cutoff, last sale, audit, reversals',
        icon: Icons.bar_chart,
        color: AppColors.info,
        onTap: onReports,
      ),
      _MenuItem(
        title: 'CHANGE',
        subtitle: 'Float top-up and change requests',
        icon: Icons.swap_horiz,
        color: AppColors.warning,
        onTap: onChange,
      ),
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
