import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/coupon_validation.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/pos_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/common/app_bar_widget.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/success_screen.dart';

class CouponConfirmationScreen extends StatefulWidget {
  final CouponInfo coupon;
  const CouponConfirmationScreen({super.key, required this.coupon});

  @override
  State<CouponConfirmationScreen> createState() => _CouponConfirmationScreenState();
}

class _CouponConfirmationScreenState extends State<CouponConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _operatorPin = '';
  bool _submitting = false;

  double get _amount => (widget.coupon.liters * widget.coupon.product.price);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final payments = Provider.of<PaymentProvider>(context, listen: false);
    setState(() => _submitting = true);

    final ok = await payments.processPayment(
      userId: auth.currentUser?.id.toString() ?? '0',
      productId: widget.coupon.product.id.toString(),
      currencyCode: 'USD', // currency_id is forced to 1 in service
      amount: _amount,
      quantity: widget.coupon.liters,
      paymentMethod: PaymentMethod.coupon,
      operatorPin: _operatorPin,
      couponCode: widget.coupon.couponCode,
    );

    // Trigger printing on success
    if (ok) {
      await _printReceiptSafely();
    }

    setState(() => _submitting = false);
    if (!ok) {
      final msg = payments.errorMessage ?? 'Sale failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SuccessScreen(
          title: 'Coupon Sale Complete',
          message: 'Sale processed successfully with coupon.',
          actionText: 'Back to Dashboard',
          onAction: () {
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
        ),
      ),
    );
  }

  Future<void> _printReceiptSafely() async {
    try {
      final posProvider = Provider.of<PosProvider>(context, listen: false);
      final payments = Provider.of<PaymentProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final r = payments.receiptData;
      if (r != null && r.isNotEmpty) {
        final fiscalData = (r['fiscalisation'] as Map?)?['data'] as Map?;
        final receiptNo = (fiscalData?['receiptID'] ?? '').toString();
        final qrData = ((r['fiscalisation'] as Map?)?['qrData'] ?? '').toString();
        await posProvider.printReceiptCopy(
          copyType: 'CUSTOMER COPY',
          stationName: (r['stationName'] ?? auth.serviceStationName ?? 'Fuel Station').toString(),
          address: (r['address'] ?? '').toString(),
          phone: (r['phone'] ?? '').toString(),
          date: (r['date'] ?? '').toString(),
          time: (r['time'] ?? '').toString(),
          pumpNo: (r['pumpNo'] ?? '1').toString(),
          product: (r['product'] ?? widget.coupon.product.name).toString(),
          unit: 'L',
          litres: (r['litres'] ?? widget.coupon.liters.toStringAsFixed(2)).toString(),
          pricePerLitre: (r['pricePerLitre'] ?? widget.coupon.product.price.toStringAsFixed(2)).toString(),
          total: (r['total'] ?? _amount.toStringAsFixed(2)).toString(),
          payment: (r['payment'] ?? 'coupon').toString(),
          cardNo: (r['cardNo'] ?? widget.coupon.couponCode).toString(),
          receiptNo: receiptNo,
          authNo: (r['authNo'] ?? payments.currentTransaction?.referenceNumber ?? payments.currentTransaction?.id ?? '').toString(),
          rrn: (r['rrn'] ?? payments.currentTransaction?.id ?? payments.currentTransaction?.referenceNumber ?? '').toString(),
          qrData: qrData,
          operatorName: (r['attendant'] ?? Provider.of<AuthProvider>(context, listen: false).currentUser?.fullName ?? '').toString(),
        );
        return;
      }

      // Fallback minimal receipt from local data
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final date = '${now.year}-${two(now.month)}-${two(now.day)}';
      final time = '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';

      await posProvider.printReceiptCopy(
        copyType: 'CUSTOMER COPY',
        stationName: auth.serviceStationName ?? 'Fuel Station',
        address: '',
        phone: '',
        date: date,
        time: time,
        pumpNo: '1',
        product: widget.coupon.product.name,
        unit: 'L',
        litres: widget.coupon.liters.toStringAsFixed(2),
        pricePerLitre: widget.coupon.product.price.toStringAsFixed(2),
        total: _amount.toStringAsFixed(2),
        payment: 'coupon',
        cardNo: widget.coupon.couponCode,
        authNo: Provider.of<PaymentProvider>(context, listen: false).currentTransaction?.referenceNumber
            ?? Provider.of<PaymentProvider>(context, listen: false).currentTransaction?.id
            ?? '',
        rrn: Provider.of<PaymentProvider>(context, listen: false).currentTransaction?.id
            ?? Provider.of<PaymentProvider>(context, listen: false).currentTransaction?.referenceNumber
            ?? '',
        operatorName: Provider.of<AuthProvider>(context, listen: false).currentUser?.fullName ?? '',
      );
    } catch (e) {
      debugPrint('Coupon receipt print failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.coupon;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Confirm Coupon',
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coupon ${c.couponCode}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (c.batch?.company?.name != null && c.batch!.company!.name.isNotEmpty)
                      Text(
                        c.batch!.company!.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    _row('Product', c.product.name),
                    _row('Price', c.product.price.toStringAsFixed(2)),
                    _row('Liters', c.liters.toStringAsFixed(2)),
                    _row('Amount', _amount.toStringAsFixed(2)),
                    _row('Expiry', _formatDate(c.expiresAt)),
                    _row('Status', c.isExpired ? 'Expired' : (c.isValid ? 'Active' : 'Invalid')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!c.isExpired && c.isValid)
              Form(
                key: _formKey,
                child: CustomTextField(
                  label: 'Operator Code',
                  hint: 'Enter 4-digit operator PIN',
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  onChanged: (v) => _operatorPin = v,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.length != 4) return 'Enter 4 digits';
                    if (int.tryParse(t) == null) return 'Digits only';
                    return null;
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (!c.isExpired && c.isValid)
              CustomButton(
                onPressed: _submitting ? null : _submit,
                backgroundColor: Colors.green,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Complete Sale'),
              ),
            if (c.isExpired || !c.isValid)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Coupon cannot be used (invalid or expired).', style: TextStyle(color: AppColors.error)),
              ),
            const SizedBox(height: 12),
            CustomButton(
              onPressed: () => Navigator.of(context).pop(),
              isOutlined: true,
              backgroundColor: AppColors.textSecondary,
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
