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

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final updateService = UpdateService();
    final success = await updateService.downloadAndInstallApk(
      _updateInfo!['downloadUrl'],
      (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isDownloading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update downloaded! Please install the APK.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download update. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Check for Updates',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Version Card
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Version',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'GASMAN',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Version:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          _currentVersion.isEmpty ? 'Loading...' : _currentVersion,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Build Number:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          _currentBuildNumber.isEmpty ? 'Loading...' : _currentBuildNumber,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Check for Updates Button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isChecking || _isDownloading ? null : _checkForUpdates,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.system_update_alt, size: 24),
                  label: Text(
                    _isChecking ? 'Checking...' : 'Check for Updates',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Update Status Card
              if (_updateInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _updateInfo!['updateAvailable'] == true
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : const Color(0xFF6B7280).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _updateInfo!['updateAvailable'] == true
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _updateInfo!['updateAvailable'] == true
                                ? Icons.celebration
                                : Icons.check_circle,
                            color: _updateInfo!['updateAvailable'] == true
                                ? const Color(0xFF10B981)
                                : const Color(0xFF6B7280),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _updateInfo!['updateAvailable'] == true
                                  ? 'Update Available!'
                                  : 'You\'re Up to Date',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _updateInfo!['updateAvailable'] == true
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_updateInfo!['updateAvailable'] == true) ...[
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Latest Version:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              _updateInfo!['latestVersion'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'What\'s New:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _updateInfo!['releaseNotes'] ?? 'Bug fixes and improvements',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isDownloading) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Downloading...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  Text(
                                    '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _downloadProgress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _downloadAndInstall,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.download, size: 20),
                              label: const Text(
                                'Download & Install',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0EA5E9).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF0EA5E9),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Updates will be downloaded from our secure server. After downloading, you\'ll be prompted to install the new version.',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF0EA5E9).withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
