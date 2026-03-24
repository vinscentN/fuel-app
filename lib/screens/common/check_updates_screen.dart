import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/update_service.dart';
import '../../utils/colors.dart';

class CheckUpdatesScreen extends StatefulWidget {
  const CheckUpdatesScreen({super.key});

  @override
  State<CheckUpdatesScreen> createState() => _CheckUpdatesScreenState();
}

class _CheckUpdatesScreenState extends State<CheckUpdatesScreen> {
  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _currentVersion = '';
  String _currentBuildNumber = '';
  Map<String, dynamic>? _updateInfo;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _currentVersion = packageInfo.version;
      _currentBuildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _updateInfo = null;
    });

    final updateService = UpdateService();
    final updateInfo = await updateService.checkForUpdates();

    if (!mounted) return;

    setState(() {
      _isChecking = false;
      _updateInfo = updateInfo;
    });

    if (updateInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to check for updates. Please try again later.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_updateInfo == null) return;

    final downloadUrl = _updateInfo!['downloadUrl'] as String? ?? '';
    if (downloadUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Download URL is missing. Please contact support or check for updates again.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final updateService = UpdateService();
    final success = await updateService.downloadAndInstallApk(
      downloadUrl,
      (progress) {
        if (mounted) {
          setState(() => _downloadProgress = progress);
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isDownloading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Update downloaded. Please install the APK.'
              : 'Failed to download update. Check your internet connection and try again.',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          const Text(
            'UPDATES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _navyMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          _buildVersionCard(),
          const SizedBox(height: 10),
          _buildActionTile(),
          if (_updateInfo != null) ...[
            const SizedBox(height: 10),
            _buildUpdateStatusCard(),
          ],
          const SizedBox(height: 10),
          _buildInfoCard(),
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
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  splashRadius: 20,
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check for Updates',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'App version & downloads',
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

  Widget _buildVersionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _valueRow('Current Version', _currentVersion.isEmpty ? 'Loading...' : _currentVersion),
            const SizedBox(height: 10),
            _valueRow(
              'Build Number',
              _currentBuildNumber.isEmpty ? 'Loading...' : _currentBuildNumber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withOpacity(0.08),
          child: _isChecking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.system_update_alt_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
        ),
        title: Text(
          _isChecking ? 'Checking for Updates...' : 'Check for Updates',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: const Text(
          'Check whether a newer app version is available',
          style: TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: _isChecking || _isDownloading ? null : _checkForUpdates,
      ),
    );
  }

  Widget _buildUpdateStatusCard() {
    final updateAvailable = _updateInfo!['updateAvailable'] == true;
    final accent = updateAvailable ? AppColors.success : _navyMuted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accent.withOpacity(0.12),
                  child: Icon(
                    updateAvailable ? Icons.download_done_rounded : Icons.check_circle_rounded,
                    color: accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    updateAvailable ? 'Update Available' : 'You are Up to Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            if (updateAvailable) ...[
              const SizedBox(height: 12),
              _valueRow('Latest Version', (_updateInfo!['latestVersion'] ?? '--').toString()),
              const SizedBox(height: 10),
              const Text(
                'Release Notes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (_updateInfo!['releaseNotes'] ?? 'Bug fixes and improvements').toString(),
                style: const TextStyle(
                  fontSize: 12,
                  color: _navyMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (_isDownloading) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Downloading',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _navy,
                      ),
                    ),
                    Text(
                      '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE8EDF5),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _downloadAndInstall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text(
                      'Download & Install',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0x140D2B55),
              child: Icon(Icons.info_outline_rounded, color: _navy, size: 18),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Updates are downloaded from the secure server. After the download completes, install the APK to finish the update.',
                style: TextStyle(
                  fontSize: 12,
                  color: _navyMuted,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _navyMuted,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _navy,
          ),
        ),
      ],
    );
  }
}
