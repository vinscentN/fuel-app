import 'package:flutter/material.dart';
import '../../utils/buffalo_colors.dart';
import '../../services/buffalo_api_service.dart';

class BuffaloTestConnectionScreen extends StatefulWidget {
  const BuffaloTestConnectionScreen({Key? key}) : super(key: key);

  @override
  State<BuffaloTestConnectionScreen> createState() =>
      _BuffaloTestConnectionScreenState();
}

class _BuffaloTestConnectionScreenState
    extends State<BuffaloTestConnectionScreen> {
  bool _isTesting = false;
  String? _result;

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _result = null;
    });

    try {
      print('Testing connection...');
      final canConnect = await BuffaloApiService.testConnection();

      setState(() {
        _isTesting = false;
        _result = canConnect
            ? '✅ SUCCESS!\nServer is reachable at:\nhttp://192.168.188.240:8001'
            : '❌ FAILED\nCannot reach server.\nCheck:\n- WiFi connection\n- Same network\n- Windows Firewall';
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _result = '❌ ERROR\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Server Connection'),
        backgroundColor: BuffaloColors.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.network_check,
                size: 100,
                color: BuffaloColors.secondary,
              ),
              const SizedBox(height: 32),
              const Text(
                'Test API Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: BuffaloColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Server: http://192.168.188.240:8001',
                style: TextStyle(
                  fontSize: 14,
                  color: BuffaloColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BuffaloColors.secondary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _result!.contains('SUCCESS')
                        ? BuffaloColors.success.withOpacity(0.1)
                        : BuffaloColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _result!.contains('SUCCESS')
                          ? BuffaloColors.success
                          : BuffaloColors.error,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _result!,
                    style: TextStyle(
                      fontSize: 16,
                      color: _result!.contains('SUCCESS')
                          ? BuffaloColors.success
                          : BuffaloColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
