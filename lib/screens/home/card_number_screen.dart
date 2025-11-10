import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/pos_provider.dart';
import '../../utils/colors.dart';

class CardNumberScreen extends StatefulWidget {
  const CardNumberScreen({super.key});

  @override
  State<CardNumberScreen> createState() => _CardNumberScreenState();
}

class _CardNumberScreenState extends State<CardNumberScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pos = Provider.of<PosProvider>(context, listen: false);
      pos.readNfcCard();
    });
  }

  String? _extractUid(Map? data) {
    if (data == null) return null;
    // Android returns uid as hex under 'uid_raw'
    final uid = data['uid_raw']?.toString();
    return uid?.isNotEmpty == true ? uid : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Number'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Consumer<PosProvider>(
        builder: (context, pos, _) {
          final uid = _extractUid(pos.lastResult);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  _WaitingForCardWidget(isLoading: pos.isLoading, hasData: uid != null),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detected Card Number (UID)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              uid ?? 'Waiting for card...',
                              style: TextStyle(
                                fontSize: 16,
                                color: uid != null ? Colors.black87 : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: uid == null
                                      ? null
                                      : () async {
                                          await Clipboard.setData(ClipboardData(text: uid));
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Card number copied')),
                                            );
                                          }
                                        },
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy'),
                                ),
                                const SizedBox(width: 12),
                                if (pos.lastError != null)
                                  OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.error_outline),
                                    label: Text(pos.lastError ?? ''),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
        },
      ),
    );
  }

  Widget _WaitingForCardWidget({required bool isLoading, required bool hasData}) {
    if (hasData) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: const Icon(Icons.credit_card, size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        Text(
          isLoading ? 'Waiting for card...' : 'Please tap or insert card',
          style: const TextStyle(color: AppColors.textSecondary),
        )
      ],
    );
  }
}
