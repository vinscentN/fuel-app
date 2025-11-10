import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';

class PosTestScreen extends StatelessWidget {
  const PosTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posProvider = Provider.of<PosProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("POS Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => posProvider.readNfcCard(),
              child: const Text("Tap Card (NFC)"),
            ),
            ElevatedButton(
              onPressed: () => posProvider.readChipCard(),
              child: const Text("Insert Chip Card"),
            ),
            ElevatedButton(
              onPressed: () => posProvider.readMagstripeCard(),
              child: const Text("Swipe Magstripe"),
            ),
            ElevatedButton(
              onPressed: () => posProvider.requestPin(),
              child: const Text("Enter PIN"),
            ),
            const SizedBox(height: 20),
            Text("Result: ${posProvider.lastResult ?? 'No result yet'}"),
          ],
        ),
      ),
    );
  }
}
