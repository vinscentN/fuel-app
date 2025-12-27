import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

class ExternalPaymentService {
  static Future<void> launchExternalPaymentApp({
    required double amount,
    required String currency,
    required String method,
    required BuildContext context,
  }) async {
    try {
      final explicitIntent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        package: 'zw.co.poscloud.checkout',
        componentName: 'zw.co.poscloud.a90.activity.MainActivity',
        arguments: {
          'reference': 'REF${DateTime.now().millisecondsSinceEpoch}',
          'amount': amount,
          'currency': currency,
          'method': method,
          'transaction_type': 'SALE',
        },
      );

      bool launched = await explicitIntent
          .launch()
          .then((_) => true)
          .catchError((_) => false);

      if (!launched) {
        final implicitIntent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          package: 'zw.co.poscloud.checkout',
          arguments: {
            'reference': 'REF${DateTime.now().millisecondsSinceEpoch}',
            'amount': amount,
            'currency': currency,
            'method': method,
            'transaction_type': 'SALE',
          },
        );
        await implicitIntent.launch();
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => launchExternalPaymentApp(
              amount: amount,
              currency: currency,
              method: method,
              context: context,
            ),
          ),
        ),
      );
    }
  }
}
