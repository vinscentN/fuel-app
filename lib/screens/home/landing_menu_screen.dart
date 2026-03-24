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

  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

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
      _showSnack('Device not activated');
      return;
    }
    if (user == null || user.serviceStationId == 0) {
      _showSnack('Service station not found');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
            strokeWidth: 2, color: _navy),
      ),
    );

    await auth.fetchProductsByStation();
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  const Text('Logout',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _navy)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Are you sure you want to logout?',
                  style: TextStyle(
                      fontSize: 13, color: _navyMuted, height: 1.4)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: _navyMuted,
                        padding:
                        const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: _navyMuted.withOpacity(0.3)),
                        ),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Logout',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider =
      Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MobileLoginScreen()),
            (route) => false,
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(onLogout: _handleLogout),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(auth, user),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            // ── Menu section label ──
            const Text(
              'MENU',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _navyMuted,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),

            // ── Menu tiles ──
            _buildMenuTile(
              icon: Icons.shopping_cart_rounded,
              title: 'Sale',
              subtitle: 'Start a new fuel sale',
              onTap: _handleSale,
              isPrimary: true,
            ),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.propane_tank_rounded,
              title: 'Cylinder Collections',
              subtitle: 'Prepare cylinders for collection',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CylinderCollectionsScreen())),
            ),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.bar_chart_rounded,
              title: 'Reports',
              subtitle: 'Batch cutoff, last sale, audit, incidents',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ReportsMenuScreen())),
            ),
            const SizedBox(height: 8),
            _buildMenuTile(
              icon: Icons.system_update_alt_rounded,
              title: 'Check for Updates',
              subtitle: 'Update to the latest version',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const CheckUpdatesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(AuthProvider auth, user) {
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // App icon badge
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_gas_station_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GASMAN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Service Station Management',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white, size: 20),
                  tooltip: 'Logout',
                  splashRadius: 20,
                  onPressed: _handleLogout,
                ),
                IconButton(
                  icon: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 20),
                  tooltip: 'Profile',
                  splashRadius: 20,
                  onPressed: _showProfileSheet,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Station strip ─────────────────────────────────────────

  Widget _buildStationStrip(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _navy.withOpacity(0.07),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.store_rounded, color: _navy, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.serviceStationName ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (auth.serviceStationAddress != null &&
                    auth.serviceStationAddress!.isNotEmpty)
                  Text(
                    auth.serviceStationAddress!,
                    style: const TextStyle(
                        fontSize: 11, color: _navyMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Device status badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: auth.isDeviceActive
                  ? const Color(0xFFDFF7EC)
                  : const Color(0xFFFFF4DC),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              auth.isDeviceActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: auth.isDeviceActive
                    ? const Color(0xFF1A7A40)
                    : const Color(0xFF7A5500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu tile ─────────────────────────────────────────────

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? _navy : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withOpacity(0.12)
                      : _navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: isPrimary ? Colors.white : _navy, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isPrimary ? Colors.white : _navy,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isPrimary
                            ? Colors.white.withOpacity(0.65)
                            : _navyMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isPrimary
                    ? Colors.white.withOpacity(0.5)
                    : _navyMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Profile bottom sheet
// ─────────────────────────────────────────

class _ProfileSheet extends StatefulWidget {
  final VoidCallback onLogout;
  const _ProfileSheet({required this.onLogout});

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  String _version = '';

  static const _navy = Color(0xFF0D2B55);
  static const _navyMuted = Color(0xFF6B80A0);

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() =>
    _version = '${info.version}+${info.buildNumber}');
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isLocal = ApiConstants.baseUrl.contains('localhost') ||
        ApiConstants.baseUrl.contains('10.') ||
        ApiConstants.baseUrl.contains('192.168');

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE4EE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                const EdgeInsets.fromLTRB(16, 6, 8, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                          Icons.local_gas_station_rounded,
                          color: Colors.white,
                          size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GASMAN',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _navy,
                                  letterSpacing: 1.0)),
                          Text('Service Station Management',
                              style: TextStyle(
                                  fontSize: 11, color: _navyMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: _navyMuted, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F4FA)),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Service station
                    _sheetSection('SERVICE STATION'),
                    const SizedBox(height: 8),
                    _infoTile(
                      icon: Icons.store_rounded,
                      title: auth.serviceStationName ?? 'Not Available',
                      subtitle: auth.serviceStationAddress ?? '',
                      extra: auth.serviceStationPhone,
                      extraIcon: Icons.phone_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Attendant
                    if (user != null) ...[
                      _sheetSection('ATTENDANT'),
                      const SizedBox(height: 8),
                      _infoTile(
                        icon: Icons.person_rounded,
                        title: user.fullName,
                        subtitle: user.designation ?? 'Attendant',
                        extra: '@${user.username}',
                        extraIcon: Icons.badge_rounded,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Device
                    if (auth.serialNumber != null &&
                        auth.serialNumber!.isNotEmpty) ...[
                      _sheetSection('DEVICE'),
                      const SizedBox(height: 8),
                      _infoTile(
                        icon: Icons.devices_rounded,
                        title: 'Serial Number',
                        subtitle: auth.serialNumber ?? '',
                        badgeLabel:
                        auth.isDeviceActive ? 'Active' : 'Inactive',
                        badgeOk: auth.isDeviceActive,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // API
                    _sheetSection('API ENDPOINT'),
                    const SizedBox(height: 8),
                    _infoTile(
                      icon: Icons.dns_rounded,
                      title: 'Base URL',
                      subtitle: ApiConstants.baseUrl
                          .split('/api/')
                          .first,
                      badgeLabel: isLocal ? 'Local' : 'Production',
                      badgeOk: !isLocal,
                    ),
                    const SizedBox(height: 16),

                    // About
                    _sheetSection('ABOUT'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE8EDF5)),
                      ),
                      child: Column(
                        children: [
                          _aboutRow(Icons.info_outline_rounded,
                              'Version $_version'),
                          const Divider(
                              height: 20, color: Color(0xFFEEF2F8)),
                          _aboutRow(
                              Icons.developer_mode_rounded,
                              'Poscloud Private Ltd',
                              subtitle:
                              'Developed and maintained by'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onLogout();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                          const Color(0xFFCC3333),
                          backgroundColor:
                          const Color(0xFFFFF5F5),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10),
                            side: const BorderSide(
                                color: Color(0xFFEEC0C0)),
                          ),
                        ),
                        icon: const Icon(
                            Icons.logout_rounded,
                            size: 17),
                        label: const Text('Logout',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetSection(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: _navyMuted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    String? extra,
    IconData? extraIcon,
    String? badgeLabel,
    bool? badgeOk,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _navy, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _navy),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 11, color: _navyMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (badgeLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeOk ?? false)
                        ? const Color(0xFFDFF7EC)
                        : const Color(0xFFFFF4DC),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: (badgeOk ?? false)
                          ? const Color(0xFF1A7A40)
                          : const Color(0xFF7A5500),
                    ),
                  ),
                ),
            ],
          ),
          if (extra != null && extra.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(extraIcon ?? Icons.info_outline_rounded,
                    size: 13, color: _navyMuted),
                const SizedBox(width: 6),
                Text(extra,
                    style: const TextStyle(
                        fontSize: 11, color: _navyMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String text, {String? subtitle}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _navyMuted),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null)
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 10, color: _navyMuted)),
            Text(text,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _navy)),
          ],
        ),
      ],
    );
  }
}