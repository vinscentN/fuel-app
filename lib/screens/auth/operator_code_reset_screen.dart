import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../services/auth_service.dart';

class OperatorCodeResetScreen extends StatefulWidget {
  const OperatorCodeResetScreen({super.key});

  @override
  State<OperatorCodeResetScreen> createState() => _OperatorCodeResetScreenState();
}

class _OperatorCodeResetScreenState extends State<OperatorCodeResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _authService = AuthService();
  bool _submitting = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final res = await _authService.requestAttendantResetCode(_contactController.text);
      final message = (res['message'] ?? 'If an account exists, a reset code has been sent.').toString();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator Code Reset'),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter email or mobile number',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email or Phone',
                      hintText: 'e.g. user@example.com or +263771234567',
                      prefixIcon: Icon(Icons.contact_mail_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter email or phone number';
                      if (v.trim().length < 5) return 'Please enter a valid value';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                            )
                          : const Text('Send Reset Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We will send a reset code to your email or phone if it matches an attendant account.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

