import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/common/loading_widget.dart';
import '../fuel/amount_input_screen.dart';
import '../auth/mobile_login_screen.dart';
import 'landing_menu_screen.dart';
import '../../models/product.dart';
import '../reports/last_sale_screen.dart';
import '../reports/batch_cutoff_screen.dart';
import '../common/network_diagnostics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Navy palette constants
  static const _navy = Color(0xFF0D2B55);
  static const _navyLight = Color(0xFF1A3D6E);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh(BuildContext context) async {
    await Provider.of<AuthProvider>(context, listen: false).loadSession();
  }

  void _navigateToProductSelection(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AmountInputScreen(product: product)),
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
      builder: (context) => Dialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _navy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: _navy, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                    fontSize: 13,
                    color: _navyMuted,
                    height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: _navyMuted,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: _navyMuted.withOpacity(0.3)),
                        ),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Logout',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Container(
        decoration: const BoxDecoration(
          color: _navy,
          border: Border(
            bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Icon badge
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Selection',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Choose a fuel product',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0x99FFFFFF),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.home_rounded,
                      color: Colors.white, size: 20),
                  tooltip: 'Main Menu',
                  splashRadius: 20,
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const LandingMenuScreen()),
                        (route) => false,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 20),
                  tooltip: 'Logout',
                  splashRadius: 20,
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          color: _navy,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // ── Section: Products ──
              _sectionLabel('Available Products'),
              const SizedBox(height: 8),
              ...authProvider.products.map(
                    (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildProductCard(product),
                ),
              ),
              const SizedBox(height: 6),
              // ── Section: Quick Links ──
              _sectionLabel('Quick Links'),
              const SizedBox(height: 8),
              _buildQuickLinksGrid(),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _navyMuted,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildQuickLinksGrid() {
    final links = [
      _QuickLink(
        icon: Icons.receipt_long_rounded,
        title: 'Last Sale',
        subtitle: 'View last transaction',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LastSaleScreen()),
        ),
      ),
      _QuickLink(
        icon: Icons.content_cut_rounded,
        title: 'Batch Cutoff',
        subtitle: 'End-of-day summary',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BatchCutoffScreen()),
        ),
      ),
      _QuickLink(
        icon: Icons.network_check_rounded,
        title: 'Connection',
        subtitle: 'Network diagnostics',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => const NetworkDiagnosticsScreen()),
        ),
      ),
    ];

    return Column(
      children: links
          .map(
            (link) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildQuickLinkRow(link),
        ),
      )
          .toList(),
    );
  }

  Widget _buildQuickLinkRow(_QuickLink link) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: link.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(link.icon, color: _navy, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                    Text(
                      link.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _navyMuted,
                      ),
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

  Widget _buildProductCard(Product product) {
    final unit = _unitShort(product.unitOfMeasure);
    final currencySymbol = _codeWithSymbol(product.currencyCode);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _navigateToProductSelection(product),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _navy.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Name + price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.13),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '$currencySymbol${product.price.toStringAsFixed(2)} / $unit',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 16,
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
        return '\$';
      case 'ZWL':
      case 'ZWG':
        return '${c}\$';
      case 'ZAR':
        return 'R';
      default:
        return c;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _navy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _navy.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.local_fire_department_outlined,
                size: 38,
                color: _navy.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Products Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _navy,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Please contact your administrator',
              style: TextStyle(
                fontSize: 13,
                color: _navyMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton.icon(
                onPressed: () => _handleRefresh(context),
                style: TextButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}