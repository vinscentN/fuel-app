import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
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
        debugPrint('Download URL: $downloadUrl');

        if (downloadUrl.isEmpty) {
          debugPrint('⚠️ WARNING: API did not provide a download_url!');
          debugPrint('The API response should include a "download_url" field with a valid APK download link.');
        }

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
      // Validate download URL first
      if (downloadUrl.isEmpty) {
        debugPrint('❌ ERROR: Download URL is empty!');
        debugPrint('The server did not provide a valid download URL.');
        debugPrint('Please check the API response for "download_url" field.');
        return false;
      }

      debugPrint('🔗 Download URL: $downloadUrl');

      // Validate URL format
      try {
        final uri = Uri.parse(downloadUrl);
        if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
          debugPrint('❌ ERROR: Invalid URL format: $downloadUrl');
          return false;
        }
      } catch (e) {
        debugPrint('❌ ERROR: Failed to parse URL: $e');
        return false;
      }

      // Request storage permission
      debugPrint('📂 Requesting storage permissions...');
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // Try with manage external storage for Android 11+
        final manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          debugPrint('❌ ERROR: Storage permission denied');
          return false;
        }
      }
      debugPrint('✅ Storage permissions granted');

      // Get download directory
      final Directory? directory = await getExternalStorageDirectory();
      if (directory == null) {
        debugPrint('❌ ERROR: Could not get download directory');
        return false;
      }

      final String savePath = '${directory.path}/gasman_update.apk';

      // Delete old APK if exists
      final File file = File(savePath);
      if (await file.exists()) {
        debugPrint('🗑️ Deleting old APK file...');
        await file.delete();
      }

      debugPrint('📥 Starting download to: $savePath');

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

      debugPrint('✅ Download completed. Installing APK...');

      // Install APK
      return await _installApk(savePath);
    } on DioException catch (e) {
      debugPrint('❌ DIO ERROR downloading APK:');
      debugPrint('Error type: ${e.type}');
      debugPrint('Error message: ${e.message}');
      debugPrint('Response: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionTimeout) {
        debugPrint('Connection timeout - server not responding');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        debugPrint('Receive timeout - download took too long');
      } else if (e.type == DioExceptionType.connectionError) {
        debugPrint('Connection error - check network connection');
      } else if (e.type == DioExceptionType.badResponse) {
        debugPrint('Bad response - URL may be invalid or file not found');
        debugPrint('Status code: ${e.response?.statusCode}');
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ UNEXPECTED ERROR downloading/installing APK: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> _installApk(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ ERROR: APK file does not exist at: $filePath');
        return false;
      }

      debugPrint('📦 APK file exists, size: ${await file.length()} bytes');
      debugPrint('🚀 Launching APK installer...');

      // Use open_filex to install APK - handles FileProvider automatically
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
        uti: 'application/vnd.android.package-archive',
      );

      debugPrint('Installation result: ${result.type}');
      debugPrint('Installation message: ${result.message}');

      if (result.type == ResultType.done) {
        debugPrint('✅ APK installer launched successfully');
        return true;
      } else if (result.type == ResultType.fileNotFound) {
        debugPrint('❌ ERROR: File not found');
        return false;
      } else if (result.type == ResultType.noAppToOpen) {
        debugPrint('❌ ERROR: No app to open APK file');
        return false;
      } else if (result.type == ResultType.permissionDenied) {
        debugPrint('❌ ERROR: Permission denied to install');
        return false;
      } else {
        debugPrint('⚠️ WARNING: Unexpected result type: ${result.type}');
        // Still return true as the installer might have been launched
        return true;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERROR installing APK: $e');
      debugPrint('Stack trace: $stackTrace');
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
