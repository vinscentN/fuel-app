import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

enum ConnectionQuality {
  good,
  fair,
  weak,
  offline,
}

class NetworkDiagnosticsResult {
  final bool internetAvailable;
  final bool apiReachable;
  final int? latencyMs;
  final double? downloadSpeedMbps;
  final ConnectionQuality quality;
  final String statusTitle;
  final String statusMessage;

  const NetworkDiagnosticsResult({
    required this.internetAvailable,
    required this.apiReachable,
    required this.latencyMs,
    required this.downloadSpeedMbps,
    required this.quality,
    required this.statusTitle,
    required this.statusMessage,
  });
}

class NetworkDiagnosticsService {
  static const Duration _dnsTimeout = Duration(seconds: 5);
  static const Duration _apiTimeout = Duration(seconds: 8);
  static const Duration _speedTestTimeout = Duration(seconds: 12);
  static const String _speedTestUrl =
      'https://speed.cloudflare.com/__down?bytes=262144';

  Future<NetworkDiagnosticsResult> runCheck() async {
    final hasInternet = await _hasInternetConnection();
    if (!hasInternet) {
      return const NetworkDiagnosticsResult(
        internetAvailable: false,
        apiReachable: false,
        latencyMs: null,
        downloadSpeedMbps: null,
        quality: ConnectionQuality.offline,
        statusTitle: 'Offline',
        statusMessage:
            'This device does not have internet access right now. Transactions will not go through until the connection is restored.',
      );
    }

    final apiCheck = await _checkApiLatency();
    if (!apiCheck.reachable) {
      return const NetworkDiagnosticsResult(
        internetAvailable: true,
        apiReachable: false,
        latencyMs: null,
        downloadSpeedMbps: null,
        quality: ConnectionQuality.weak,
        statusTitle: 'Connected, But Server Unreachable',
        statusMessage:
            'Internet is available, but the transaction server is not responding. Avoid processing sales until the connection stabilizes.',
      );
    }

    final downloadSpeedMbps = await _measureDownloadSpeedMbps();
    final quality = _classifyQuality(apiCheck.latencyMs!);
    return NetworkDiagnosticsResult(
      internetAvailable: true,
      apiReachable: true,
      latencyMs: apiCheck.latencyMs,
      downloadSpeedMbps: downloadSpeedMbps,
      quality: quality,
      statusTitle: _statusTitleForQuality(quality),
      statusMessage: _statusMessageForQuality(quality, apiCheck.latencyMs!),
    );
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(_dnsTimeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }

  Future<_ApiCheckResult> _checkApiLatency() async {
    final uri = Uri.parse(ApiConstants.baseUrl);
    final watch = Stopwatch()..start();

    try {
      final response = await http.get(uri).timeout(_apiTimeout);
      watch.stop();

      final reachableStatusCodes = {200, 201, 204, 400, 401, 403, 404, 405, 422, 500};
      if (reachableStatusCodes.contains(response.statusCode)) {
        return _ApiCheckResult(reachable: true, latencyMs: watch.elapsedMilliseconds);
      }

      return const _ApiCheckResult(reachable: false, latencyMs: null);
    } on SocketException {
      return const _ApiCheckResult(reachable: false, latencyMs: null);
    } on TimeoutException {
      return const _ApiCheckResult(reachable: false, latencyMs: null);
    } catch (_) {
      return const _ApiCheckResult(reachable: false, latencyMs: null);
    }
  }

  Future<double?> _measureDownloadSpeedMbps() async {
    final uri = Uri.parse(_speedTestUrl);
    final watch = Stopwatch()..start();

    try {
      final response = await http.get(uri).timeout(_speedTestTimeout);
      watch.stop();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final bytes = response.bodyBytes.length;
      final seconds = watch.elapsedMilliseconds / 1000;
      if (bytes <= 0 || seconds <= 0) {
        return null;
      }

      final bitsPerSecond = (bytes * 8) / seconds;
      return bitsPerSecond / 1000000;
    } catch (_) {
      return null;
    }
  }

  ConnectionQuality _classifyQuality(int latencyMs) {
    if (latencyMs <= 700) return ConnectionQuality.good;
    if (latencyMs <= 1500) return ConnectionQuality.fair;
    return ConnectionQuality.weak;
  }

  String _statusTitleForQuality(ConnectionQuality quality) {
    switch (quality) {
      case ConnectionQuality.good:
        return 'Connection Good';
      case ConnectionQuality.fair:
        return 'Connection Fair';
      case ConnectionQuality.weak:
        return 'Connection Weak';
      case ConnectionQuality.offline:
        return 'Offline';
    }
  }

  String _statusMessageForQuality(ConnectionQuality quality, int latencyMs) {
    switch (quality) {
      case ConnectionQuality.good:
        return 'Internet is stable and the server is reachable. Transactions should go through normally.';
      case ConnectionQuality.fair:
        return 'Internet is working, but response time is slower than normal (${latencyMs} ms). Transactions may take longer to complete.';
      case ConnectionQuality.weak:
        return 'Internet is available, but response time is weak (${latencyMs} ms). Transactions may timeout or fail. Check signal before retrying.';
      case ConnectionQuality.offline:
        return 'This device does not have internet access right now.';
    }
  }
}

class _ApiCheckResult {
  final bool reachable;
  final int? latencyMs;

  const _ApiCheckResult({
    required this.reachable,
    required this.latencyMs,
  });
}
