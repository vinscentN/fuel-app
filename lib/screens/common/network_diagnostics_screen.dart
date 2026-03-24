import 'package:flutter/material.dart';
import '../../services/network_diagnostics_service.dart';
import '../../utils/colors.dart';

class NetworkDiagnosticsScreen extends StatefulWidget {
  const NetworkDiagnosticsScreen({super.key});

  @override
  State<NetworkDiagnosticsScreen> createState() =>
      _NetworkDiagnosticsScreenState();
}

class _NetworkDiagnosticsScreenState extends State<NetworkDiagnosticsScreen> {
  final _service = NetworkDiagnosticsService();
  NetworkDiagnosticsResult? _result;
  bool _loading = false;

  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDiagnostics());
  }

  Future<void> _runDiagnostics() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final result = await _service.runCheck();
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(),
      body: _loading && result == null
          ? const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _navy,
        ),
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          if (result != null) ...[
            _buildStatusStrip(result),
            const SizedBox(height: 10),
            _sectionLabel('DIAGNOSTICS'),
            const SizedBox(height: 8),
            _buildMetricsCard(result),
            if (_loading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _navy),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────

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
                  child: const Icon(Icons.network_check_rounded,
                      color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connection Status',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Network diagnostics',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _runDiagnostics,
                  icon: _loading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
                  splashRadius: 20,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Status strip ──────────────────────────────────────────

  Widget _buildStatusStrip(NetworkDiagnosticsResult result) {
    final statusColor = _qualityColor(result.quality);
    final statusBg = _qualityBg(result.quality);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status dot + icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.network_check_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.statusTitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  result.statusMessage,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x99FFFFFF),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Quality badge
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _qualityLabel(result.quality),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Metrics card ──────────────────────────────────────────

  Widget _buildMetricsCard(NetworkDiagnosticsResult result) {
    final metrics = [
      _MetricData(
        icon: result.internetAvailable
            ? Icons.wifi_rounded
            : Icons.wifi_off_rounded,
        title: 'Internet',
        value: result.internetAvailable ? 'Connected' : 'Not connected',
        color: result.internetAvailable ? AppColors.success : AppColors.error,
        isOk: result.internetAvailable,
      ),
      _MetricData(
        icon: Icons.cloud_done_rounded,
        title: 'Transaction Server',
        value: result.apiReachable ? 'Reachable' : 'Not reachable',
        color: result.apiReachable ? AppColors.success : AppColors.error,
        isOk: result.apiReachable,
      ),
      _MetricData(
        icon: Icons.speed_rounded,
        title: 'Response Time',
        value: result.latencyMs != null
            ? '${result.latencyMs} ms'
            : 'Unavailable',
        color: _qualityColor(result.quality),
        isOk: result.latencyMs != null,
      ),
      _MetricData(
        icon: Icons.download_rounded,
        title: 'Internet Speed',
        value: result.downloadSpeedMbps != null
            ? '${result.downloadSpeedMbps!.toStringAsFixed(2)} Mbps'
            : 'Unavailable',
        color: result.downloadSpeedMbps != null
            ? AppColors.info
            : _navyMuted,
        isOk: result.downloadSpeedMbps != null,
      ),
      _MetricData(
        icon: Icons.receipt_long_rounded,
        title: 'Transactions',
        value: _transactionGuidance(result),
        color: _qualityColor(result.quality),
        isOk: result.internetAvailable && result.apiReachable,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: metrics.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          color: Color(0xFFF0F4FA),
          indent: 14,
          endIndent: 14,
        ),
        itemBuilder: (context, i) => _buildMetricRow(metrics[i]),
      ),
    );
  }

  Widget _buildMetricRow(_MetricData metric) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: metric.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(metric.icon, color: metric.color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.value,
                  style: TextStyle(
                    fontSize: 11,
                    color: metric.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: metric.isOk
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              metric.isOk ? Icons.check_rounded : Icons.close_rounded,
              size: 13,
              color: metric.isOk ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: _navyMuted,
        letterSpacing: 1.1,
      ),
    );
  }

  Color _qualityColor(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.good:
        return AppColors.success;
      case ConnectionQuality.fair:
        return AppColors.warning;
      case ConnectionQuality.weak:
        return Colors.deepOrange;
      case ConnectionQuality.offline:
        return AppColors.error;
    }
  }

  Color _qualityBg(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.good:
        return const Color(0xFFDFF7EC);
      case ConnectionQuality.fair:
        return const Color(0xFFFFF4DC);
      case ConnectionQuality.weak:
        return const Color(0xFFFFEDE5);
      case ConnectionQuality.offline:
        return const Color(0xFFFFE5E5);
    }
  }

  String _qualityLabel(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.good:
        return 'GOOD';
      case ConnectionQuality.fair:
        return 'FAIR';
      case ConnectionQuality.weak:
        return 'WEAK';
      case ConnectionQuality.offline:
        return 'OFFLINE';
    }
  }

  String _transactionGuidance(NetworkDiagnosticsResult result) {
    if (!result.internetAvailable || !result.apiReachable) {
      return 'Do not process transactions yet';
    }
    switch (result.quality) {
      case ConnectionQuality.good:
        return 'Transactions should go through';
      case ConnectionQuality.fair:
        return 'Transactions can go through, but may be slower';
      case ConnectionQuality.weak:
        return 'Transactions may fail or timeout';
      case ConnectionQuality.offline:
        return 'Transactions cannot go through';
    }
  }
}

class _MetricData {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isOk;

  const _MetricData({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isOk,
  });
}