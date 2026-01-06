import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/common/loading_widget.dart';
import '../fuel/amount_input_screen.dart';
import '../coupon/coupon_redemption_screen.dart';
import '../auth/mobile_login_screen.dart';
import '../auth/login_settings_screen.dart';
import 'landing_menu_screen.dart';
import '../../models/product.dart';
import 'card_number_screen.dart';
import '../../providers/payment_provider.dart';
import '../../providers/fuel_provider.dart'; // âœ… Import FuelProvider
import '../reports/last_sale_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _handleRefresh(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadSession(); // re-fetch products + user
  }

  // âœ… UPDATED METHOD TO PASS THE PRODUCT DIRECTLY
  void _navigateToProductSelection(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AmountInputScreen(product: product)),
    );
  }


  void _navigateToCouponRedemption() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CouponRedemptionScreen()),
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await _showLogoutConfirmation();

    if (shouldLogout && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
              (route) => false,
        );
      }
    }
  }

  Future<bool> _showLogoutConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary.withOpacity(0.7),
            ),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.modernGradient,
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            title: const Text(
              'GASMAN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
                fontFamily: 'Sans-serif',
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Logout',
                onPressed: _handleLogout,
              ),
              IconButton(
                icon: const Icon(Icons.home_rounded),
                tooltip: 'Main Menu',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LandingMenuScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginSettingsScreen()),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _buildBody() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Center(
            child: LoadingWidget(message: 'Loading fuel products...'),
          );
        }

        if (authProvider.products.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => _handleRefresh(context),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            itemCount: authProvider.products.length,
            itemBuilder: (context, index) {
              final product = authProvider.products[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                child: _buildModernProductCard(product),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModernProductCard(Product product) {
    final primary = AppColors.primary;
    final unit = _unitShort(product.unitOfMeasure);
    return InkWell(
      onTap: () => _navigateToProductSelection(product),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF5722), size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Station name removed per request
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_codeWithSymbol(product.currencyCode)}${product.price.toStringAsFixed(2)}/$unit',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _unitShort(String? uom) {
    final code = (uom ?? 'L').trim().toUpperCase();
    switch (code) {
      case 'L':
      case 'LT':
      case 'LTR':
      case 'LITRE':
      case 'LITER':
        return 'L';
      case 'KG':
      case 'KGS':
      case 'KILOGRAM':
      case 'KILOGRAMS':
        return 'KG';
      default:
        return code;
    }
  }

  String _codeWithSymbol(String code) {
    final c = code.toUpperCase();
    switch (c) {
      case 'USD':
        return 'USD\$';
      case 'ZWL':
      case 'ZWG':
        return '${c}\$';
      case 'ZAR':
        return 'ZARR';
      default:
        return c;
    }
  }

  Widget _buildFooterActions() {
    final primary = AppColors.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;

        final batchBtn = OutlinedButton.icon(
          onPressed: _handleBatchCutoff,
          icon: Icon(Icons.cut, color: primary),
          label: Text('Batch CutOff', style: TextStyle(color: primary)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: primary.withOpacity(0.25)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            minimumSize: const Size(0, 48),
          ),
        );

        final lastTxnBtn = OutlinedButton.icon(
          onPressed: _openLastTransaction,
          icon: const Icon(Icons.receipt_long, color: AppColors.textSecondary),
          label: const Text('Last Sale', style: TextStyle(color: AppColors.textSecondary)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            minimumSize: const Size(0, 48),
          ),
        );

        final redeemBtn = ElevatedButton.icon(
          onPressed: _navigateToCouponRedemption,
          icon: const Icon(Icons.card_giftcard_rounded, color: Colors.white),
          label: const Text('Redeem Coupon', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            minimumSize: const Size(0, 48),
          ),
        );

        if (wide) {
          return Row(
            children: [
              Expanded(child: batchBtn),
              const SizedBox(width: 12),
              Expanded(child: lastTxnBtn),
              const SizedBox(width: 12),
              Expanded(child: redeemBtn),
            ],
          );
        }

        // Compact layout: two buttons on first row, primary action full-width below
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: batchBtn),
                const SizedBox(width: 12),
                Expanded(child: lastTxnBtn),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: redeemBtn),
          ],
        );
      },
    );
  }

  void _handleBatchCutoff() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batch CutOff'),
        content: const Text('Are you sure you want to perform batch cutoff?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch cutoff requested')),
      );
      // TODO: Wire to backend when ready
    }
  }

  void _openLastTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LastSaleScreen()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 80, color: Color(0xFFFF5722)),
          const SizedBox(height: 16),
          const Text('No Products Available',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          const SizedBox(height: 8),
          Text('Please contact your administrator',
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary.withOpacity(0.6))),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _handleRefresh(context),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
