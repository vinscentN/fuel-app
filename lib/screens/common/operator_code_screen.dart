import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../utils/colors.dart';
import '../../widgets/common/custom_button.dart';

class OperatorCodeScreen extends StatefulWidget {
  final String title;
  final String? subtitle;

  const OperatorCodeScreen({
    super.key,
    this.title = 'Operator Code',
    this.subtitle,
  });

  @override
  State<OperatorCodeScreen> createState() => _OperatorCodeScreenState();
}

class _OperatorCodeScreenState extends State<OperatorCodeScreen> {
  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  String _code = '';
  bool _submitting = false;

  Future<void> _submit() async {
    if (_code.trim().length < 4) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    Navigator.of(context).pop(_code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          const Text(
            'AUTHORIZATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _navyMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EDF5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter 4-digit operator code',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _navyMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  PinCodeTextField(
                    appContext: context,
                    length: 4,
                    obscureText: true,
                    obscuringCharacter: '•',
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    enableActiveFill: true,
                    autoFocus: true,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(10),
                      fieldHeight: 48,
                      fieldWidth: 48,
                      activeFillColor: _navy.withOpacity(0.08),
                      inactiveFillColor: const Color(0xFFF8FAFD),
                      selectedFillColor: _navy.withOpacity(0.12),
                      activeColor: _navy,
                      inactiveColor: const Color(0xFFE8EDF5),
                      selectedColor: _navy,
                    ),
                    onCompleted: (value) {
                      setState(() => _code = value);
                      _submit();
                    },
                    onChanged: (value) {
                      setState(() => _code = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          CustomButton(
            onPressed: _submitting || _code.trim().length < 4 ? null : _submit,
            backgroundColor: AppColors.primary,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Confirm Code',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Container(
        decoration: const BoxDecoration(
          color: _navy,
          border: Border(
            bottom: BorderSide(color: Color(0x22FFFFFF), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  splashRadius: 20,
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Text(
                        'Secure verification',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
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
