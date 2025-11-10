import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pos_provider.dart';

class PosTestScreen extends StatelessWidget {
  const PosTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posProvider = Provider.of<PosProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("POS Device Test"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Buttons
            ElevatedButton.icon(
              onPressed: () => posProvider.readNfcCard(),
              icon: const Icon(Icons.nfc),
              label: const Text("Tap Card (NFC)"),
            ),
            const SizedBox(height: 16),
            //
            // ElevatedButton.icon(
            //   onPressed: () => posProvider.readChipCard(),
            //   icon: const Icon(Icons.credit_card),
            //   label: const Text("Insert Chip Card"),
            // ),
            // const SizedBox(height: 16),
            //
            // ElevatedButton.icon(
            //   onPressed: () => posProvider.readMagstripeCard(),
            //   icon: const Icon(Icons.swipe),
            //   label: const Text("Swipe Magstripe"),
            // ),
            // const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () {
                posProvider.testPrint(
                  stationName: "Sunshine Petrol",
                  address: "Main Road, Harare",
                  phone: "+263 123 456 789",
                  date: "2025-09-13",
                  time: "14:32",
                  pumpNo: "03",
                  product: "Petrol",
                  unit: 'L',
                  litres: "20.00",
                  pricePerLitre: "1.50 USD",
                  total: "30.00 USD",
                  payment: "CARD",
                  cardNo: "1234 **** **** 5678",
                  authNo: "987654",
                  rrn: "123456789012",
                );
              },
              icon: const Icon(Icons.print),
              label: const Text("Test Print"),
            ),


            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => posProvider.readImei(),
              icon: const Icon(Icons.phone_android),
              label: const Text("Read IMEI"),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => posProvider.readSerialNumber(),
              icon: const Icon(Icons.confirmation_number),
              label: const Text("Read Serial Number"),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: () => posProvider.readPosType(),
              icon: const Icon(Icons.devices),
              label: const Text("Read POS Type"),
            ),
            const SizedBox(height: 16),


            // Loading state
            if (posProvider.isLoading) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text("Waiting for user action..."),
                  ],
                ),
              ),
            ],

            // Results & Errors
            if (!posProvider.isLoading) Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: posProvider.lastError != null
                        ? Text(
                      "Error: ${posProvider.lastError}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : Text(
                      posProvider.lastResult?.toString() ??
                          "No result yet",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
