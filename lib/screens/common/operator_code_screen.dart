import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../widgets/common/custom_button.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OperatorCodeScreen extends StatefulWidget {
  final String title;
  final String? subtitle;

  const OperatorCodeScreen({super.key, this.title = 'Operator Code', this.subtitle});

  @override
  State<OperatorCodeScreen> createState() => _OperatorCodeScreenState();
}

class _OperatorCodeScreenState extends State<OperatorCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  String _code = '';
  bool _submitting = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _submit() async {
    if (_code.trim().length < 4) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    Navigator.of(context).pop(_code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.subtitle != null) ...[
                  Text(
                    widget.subtitle!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                PinCodeTextField(
                  appContext: context,
                  length: 4,
                  obscureText: true,
                  obscuringCharacter: '•',
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(10),
                    fieldHeight: 52,
                    fieldWidth: 52,
                    activeFillColor: AppColors.primary.withOpacity(0.08),
                    inactiveFillColor: AppColors.surfaceVariant,
                    selectedFillColor: AppColors.primary.withOpacity(0.12),
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    selectedColor: AppColors.primary,
                  ),
                  enableActiveFill: true,
                  onCompleted: (v) { setState(() { _code = v; }); _submit(); },
                  onChanged: (v) { setState(() { _code = v; }); },
                ),
                const SizedBox(height: 20),
                CustomButton(
                  onPressed: _submitting || _code.trim().length < 4 ? null : _submit,
                  backgroundColor: AppColors.primary,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


