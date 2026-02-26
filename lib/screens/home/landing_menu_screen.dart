import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';
import '../../constants/api_constants.dart';
import '../auth/mobile_login_screen.dart';
import '../gas_order/select_cylinders_screen.dart';
import '../collections/cylinder_collections_screen.dart';
import '../gas_order/delivery_scan_screen.dart';
import '../reports/reports_menu_screen.dart';
import '../common/check_updates_screen.dart';
import 'dashboard_screen.dart';

class LandingMenuScreen extends StatefulWidget {
  const LandingMenuScreen({super.key});

  @override
  State<LandingMenuScreen> createState() => _LandingMenuScreenState();
}

class _LandingMenuScreenState extends State<LandingMenuScreen> {
  bool _checkedAuth = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoggedIn());
  }

  void _ensureLoggedIn() {
    if (_checkedAuth) return;
    _checkedAuth = true;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated || auth.currentUser == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
        (route) => false,
      );
    }
  }

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

  void _showProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfileBottomSheet(onLogout: _handleLogout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
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
              'GASMATE',
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
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menu',
                onPressed: () => _showProfileBottomSheet(context),
              ),
            ],
          ),
        ),
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
        subtitle: 'Start a New Sale',
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
        title: 'CYLINDER COLLECTIONS',
        subtitle: 'Prepare cylinders for collection',
        icon: Icons.propane_tank_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CylinderCollectionsScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'REPORTS',
        subtitle: 'Batch cutoff, last sale, audit, incident, generator',
        icon: Icons.bar_chart,
        color: const Color(0xFF0EA5E9),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReportsMenuScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'CHECK FOR UPDATES',
        subtitle: 'Update to the latest version',
        icon: Icons.system_update_alt,
        color: const Color(0xFFE91E63),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CheckUpdatesScreen()),
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
          const SizedBox(height: 9),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Modern icon container with color
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.color.withOpacity(0.9),
                        item.color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBottomSheet extends StatefulWidget {
  final VoidCallback onLogout;

  const _ProfileBottomSheet({required this.onLogout});

  @override
  State<_ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<_ProfileBottomSheet> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.modernGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_gas_station_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GASMATE',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Service Station Management',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: const Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Service Station Section
                    _buildSection(
                      title: 'SERVICE STATION',
                      child: _InfoCard(
                        icon: Icons.store_rounded,
                        title: auth.serviceStationName ?? 'Not Available',
                        subtitle: auth.serviceStationAddress ?? '',
                        color: AppColors.primary,
                        trailing: auth.serviceStationPhone != null &&
                                auth.serviceStationPhone!.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.phone_rounded,
                                      size: 16,
                                      color: Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      auth.serviceStationPhone!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Attendant Section
                    if (user != null)
                      _buildSection(
                        title: 'ATTENDANT DETAILS',
                        child: _InfoCard(
                          icon: Icons.person_rounded,
                          title: user.fullName,
                          subtitle: user.designation ?? 'Attendant',
                          color: AppColors.indigo,
                          trailing: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.badge_rounded,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '@${user.username}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Device Details Section
                    if (auth.serialNumber != null && auth.serialNumber!.isNotEmpty)
                      _buildSection(
                        title: 'DEVICE DETAILS',
                        child: _InfoCard(
                          icon: Icons.devices_rounded,
                          title: 'Serial Number',
                          subtitle: auth.serialNumber ?? 'Not Available',
                          color: const Color(0xFF10B981),
                          trailing: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: auth.isDeviceActive
                                        ? const Color(0xFF10B981).withOpacity(0.15)
                                        : const Color(0xFFF59E0B).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        auth.isDeviceActive
                                            ? Icons.check_circle_rounded
                                            : Icons.info_rounded,
                                        size: 14,
                                        color: auth.isDeviceActive
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        auth.isDeviceActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: auth.isDeviceActive
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFF59E0B),
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

                    if (auth.serialNumber != null && auth.serialNumber!.isNotEmpty)
                      const SizedBox(height: 24),

                    // API Endpoint Section
                    _buildSection(
                      title: 'API ENDPOINT',
                      child: _InfoCard(
                        icon: Icons.dns_rounded,
                        title: 'Base URL',
                        subtitle: ApiConstants.baseUrl.split('/api/').first,
                        color: const Color(0xFF0EA5E9),
                        trailing: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: ApiConstants.baseUrl.contains('localhost') ||
                                         ApiConstants.baseUrl.contains('10.') ||
                                         ApiConstants.baseUrl.contains('192.168')
                                      ? const Color(0xFFF59E0B).withOpacity(0.15)
                                      : const Color(0xFF10B981).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      ApiConstants.baseUrl.contains('localhost') ||
                                      ApiConstants.baseUrl.contains('10.') ||
                                      ApiConstants.baseUrl.contains('192.168')
                                          ? Icons.computer_rounded
                                          : Icons.cloud_done_rounded,
                                      size: 14,
                                      color: ApiConstants.baseUrl.contains('localhost') ||
                                             ApiConstants.baseUrl.contains('10.') ||
                                             ApiConstants.baseUrl.contains('192.168')
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      ApiConstants.baseUrl.contains('localhost') ||
                                      ApiConstants.baseUrl.contains('10.') ||
                                      ApiConstants.baseUrl.contains('192.168')
                                          ? 'Local'
                                          : 'Production',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ApiConstants.baseUrl.contains('localhost') ||
                                               ApiConstants.baseUrl.contains('10.') ||
                                               ApiConstants.baseUrl.contains('192.168')
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF10B981),
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

                    const SizedBox(height: 24),

                    // About Section
                    _buildSection(
                      title: 'ABOUT',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Version $_version',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.developer_mode_rounded,
                                  size: 18,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Developed and Maintained by',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Poscloud Private Ltd',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF1A1A1A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onLogout();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3B30),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? trailing;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
