import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/buffalo_colors.dart';
import '../../providers/buffalo_provider.dart';
import '../../services/pos_service.dart';
import 'buffalo_receipt_screen.dart';

class BuffaloCardInfoScreen extends StatefulWidget {
  const BuffaloCardInfoScreen({Key? key}) : super(key: key);

  @override
  State<BuffaloCardInfoScreen> createState() => _BuffaloCardInfoScreenState();
}

class _BuffaloCardInfoScreenState extends State<BuffaloCardInfoScreen> {
  final PosService _posService = PosService();
  int _mealQuantity = 1;
  bool _isProcessing = false;

  Future<void> _processSale() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final buffaloProvider = context.read<BuffaloProvider>();
      final prefs = await SharedPreferences.getInstance();
      String? serialNumber = prefs.getString('serial_number')?.trim();
      final lower = serialNumber?.toLowerCase();
      if (serialNumber == null || serialNumber.isEmpty || lower == 'unknown' || lower == 'null') {
        serialNumber = await _posService.readSerialNumber();
      }
      if (serialNumber != null && serialNumber.isNotEmpty) {
        await prefs.setString('serial_number', serialNumber);
      } else {
        throw Exception('Device serial number not available.');
      }
      print('DEBUG: Using device serial number: $serialNumber');

      // Submit sale - backend handles product matching
      final success = await buffaloProvider.submitSale(
        serialNumber: serialNumber,
        mealQuantity: _mealQuantity,
      );

      setState(() {
        _isProcessing = false;
      });

      if (success && mounted) {
        // Navigate to receipt screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const BuffaloReceiptScreen(),
          ),
        );
      } else {
        final errorMessage = buffaloProvider.lastSaleResponse?.error ??
            buffaloProvider.lastSaleResponse?.message ??
            'Sale failed';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: BuffaloColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing sale: $e'),
          backgroundColor: BuffaloColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _incrementQuantity() {
    setState(() {
      _mealQuantity++;
    });
  }

  void _decrementQuantity() {
    if (_mealQuantity > 1) {
      setState(() {
        _mealQuantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BuffaloColors.background,
      appBar: AppBar(
        title: const Text('Card Information'),
        backgroundColor: BuffaloColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<BuffaloProvider>(
        builder: (context, provider, child) {
          final cardInfo = provider.cardInfo;

          if (cardInfo == null) {
            return const Center(
              child: Text(
                'Card information not available',
                style: TextStyle(
                  color: BuffaloColors.error,
                  fontSize: 16,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Card details card
                  Card(
                    color: BuffaloColors.surface,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Name
                          Text(
                            cardInfo.fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: BuffaloColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          // Card Number
                          Text(
                            _maskCardNumber(cardInfo.cardNumber),
                            style: const TextStyle(
                              fontSize: 14,
                              color: BuffaloColors.textSecondary,
                              letterSpacing: 1.5,
                            ),
                          ),

                          const SizedBox(height: 12),
                          Divider(color: BuffaloColors.cardBorder, height: 1),
                          const SizedBox(height: 12),

                          // Card Type
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: BuffaloColors.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              cardInfo.cardType,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: BuffaloColors.secondary,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Card Class
                          Text(
                            cardInfo.cardClass,
                            style: const TextStyle(
                              fontSize: 13,
                              color: BuffaloColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 12),
                          Divider(color: BuffaloColors.cardBorder, height: 1),
                          const SizedBox(height: 12),

                          // Meal Balance
                          Column(
                            children: [
                              const Text(
                                'Meal Balance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: BuffaloColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${cardInfo.mealBalance}',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: BuffaloColors.success,
                                ),
                              ),
                              const Text(
                                'meals remaining',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: BuffaloColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Meal quantity for HOD PROXY CARD
                  if (cardInfo.isHodProxyCard) ...[
                    Card(
                      color: BuffaloColors.surface,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'How many meals?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: BuffaloColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _decrementQuantity,
                                  icon: const Icon(Icons.remove_circle),
                                  color: BuffaloColors.secondary,
                                  iconSize: 40,
                                ),
                                const SizedBox(width: 24),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BuffaloColors.secondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _mealQuantity.toString(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: BuffaloColors.secondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                IconButton(
                                  onPressed: _incrementQuantity,
                                  icon: const Icon(Icons.add_circle),
                                  color: BuffaloColors.secondary,
                                  iconSize: 40,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Proceed button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processSale,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BuffaloColors.secondary,
                        foregroundColor: BuffaloColors.textOnSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  BuffaloColors.textOnSecondary,
                                ),
                              ),
                            )
                          : const Text('Proceed'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _maskCardNumber(String cardNumber) {
    if (cardNumber.length <= 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }
}
