import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  // Update this URL to point to your version.json on your server or Google Drive
  static const String versionCheckUrl = 'https://gasman.poscloud.co.zw/api/pos/app-version';

  // Direct download link from Google Drive (use the direct download format)
  // Format: https://drive.google.com/uc?export=download&id=FILE_ID
  static String apkDownloadUrl = '';

  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      final String currentBuildNumber = packageInfo.buildNumber;

      debugPrint('Current Version: $currentVersion ($currentBuildNumber)');
      debugPrint('Checking for updates at: $versionCheckUrl');

      // Fetch latest version info from server
      final response = await _dio.get(versionCheckUrl);

      debugPrint('Update check response status: ${response.statusCode}');
      debugPrint('Update check response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        final String latestVersion = data['version'] ?? currentVersion;
        final String latestBuildNumber = data['build_number'] ?? currentBuildNumber;
        final String downloadUrl = data['download_url'] ?? '';
        final String releaseNotes = data['release_notes'] ?? 'Bug fixes and improvements';

        debugPrint('Latest Version: $latestVersion ($latestBuildNumber)');

        apkDownloadUrl = downloadUrl;

        // Compare versions
        if (_isNewerVersion(currentVersion, currentBuildNumber, latestVersion, latestBuildNumber)) {
          return {
            'updateAvailable': true,
            'currentVersion': currentVersion,
            'latestVersion': latestVersion,
            'downloadUrl': downloadUrl,
            'releaseNotes': releaseNotes,
          };
        } else {
          return {
            'updateAvailable': false,
            'currentVersion': currentVersion,
            'latestVersion': latestVersion,
          };
        }
      } else {
        debugPrint('Non-200 response: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('DioException checking for updates: ${e.type}');
      debugPrint('Error message: ${e.message}');
      debugPrint('Error response: ${e.response?.data}');
      if (e.type == DioExceptionType.connectionTimeout) {
        debugPrint('Connection timeout - server not responding');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        debugPrint('Receive timeout - server took too long to respond');
      } else if (e.type == DioExceptionType.connectionError) {
        debugPrint('Connection error - check network connection');
      }
    } catch (e, stackTrace) {
      debugPrint('Error checking for updates: $e');
      debugPrint('Stack trace: $stackTrace');
    }

    return null;
  }

  bool _isNewerVersion(String currentVersion, String currentBuild, String latestVersion, String latestBuild) {
    try {
      // Compare build numbers first (more reliable)
      final int currentBuildInt = int.tryParse(currentBuild) ?? 0;
      final int latestBuildInt = int.tryParse(latestBuild) ?? 0;

      return latestBuildInt > currentBuildInt;
    } catch (e) {
      return false;
    }
  }

  Future<bool> downloadAndInstallApk(
    String downloadUrl,
    Function(double) onProgress,
  ) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // Try with manage external storage for Android 11+
        final manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          debugPrint('Storage permission denied');
          return false;
        }
      }

      // Get download directory
      final Directory? directory = await getExternalStorageDirectory();
      if (directory == null) {
        debugPrint('Could not get download directory');
        return false;
      }

      final String savePath = '${directory.path}/gasman_update.apk';

      // Delete old APK if exists
      final File file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      debugPrint('Downloading APK to: $savePath');

      // Download APK
      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
            debugPrint('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
          }
        },
      );

      debugPrint('Download completed. Installing APK...');

      // Install APK
      return await _installApk(savePath);
    } catch (e) {
      debugPrint('Error downloading/installing APK: $e');
      return false;
    }
  }

  Future<bool> _installApk(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        debugPrint('APK file does not exist');
        return false;
      }

      // Launch the APK file for installation
      final Uri uri = Uri.parse('file://$filePath');

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        debugPrint('Cannot launch APK installer');
        return false;
      }
    } catch (e) {
      debugPrint('Error installing APK: $e');
      return false;
    }
  }

  Future<void> openGoogleDriveLink(String driveUrl) async {
    try {
      final Uri uri = Uri.parse(driveUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error opening Google Drive: $e');
    }
  }
}
