import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/generator_log_service.dart';
import '../../utils/colors.dart';
import '../../widgets/common/custom_button.dart';

class GeneratorLogScreen extends StatefulWidget {
  const GeneratorLogScreen({super.key});

  @override
  State<GeneratorLogScreen> createState() => _GeneratorLogScreenState();
}

class _GeneratorLogScreenState extends State<GeneratorLogScreen> {
  static const _navy = Color(0xFF0D2B55);
  static const _navyBg = Color(0xFFF0F4FA);
  static const _navyMuted = Color(0xFF6B80A0);

  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _generatorLogService = GeneratorLogService();

  DateTime? _startTime;
  DateTime? _endTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startTime ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startTime ?? now),
    );
    if (selectedTime == null) return;

    setState(() {
      _startTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _selectEndTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime ?? now,
      firstDate: _startTime ?? DateTime(now.year - 1),
      lastDate: now,
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime ?? now),
    );
    if (selectedTime == null) return;

    setState(() {
      _endTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Select date & time';
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
  }

  String _calculateDuration() {
    if (_startTime == null || _endTime == null) return '';
    final duration = _endTime!.difference(_startTime!);
    if (duration.isNegative) return 'Invalid duration';
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }

  Future<void> _submitLog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Not authenticated');

      await _generatorLogService.submitGeneratorLog(
        startTime: _startTime!,
        endTime: _endTime!,
        notes: _notesController.text.trim(),
        token: token,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generator usage log submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      _notesController.clear();
      setState(() {
        _startTime = null;
        _endTime = null;
      });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navyBg,
      appBar: _buildAppBar(context),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            const Text(
              'GENERATOR LOG',
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
                  children: [
                    _timeTile('Start Time', _formatDateTime(_startTime), _selectStartTime),
                    const SizedBox(height: 8),
                    _timeTile('End Time', _formatDateTime(_endTime), _selectEndTime),
                    if (_startTime != null && _endTime != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _navy.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_rounded, size: 16, color: _navy),
                            const SizedBox(width: 8),
                            Text(
                              'Duration: ${_calculateDuration()}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        labelStyle: const TextStyle(fontSize: 12, color: _navyMuted),
                        hintText: 'Add any relevant notes...',
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE8EDF5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _navy, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            CustomButton(
              onPressed: _isSubmitting ? null : _submitLog,
              backgroundColor: AppColors.primary,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Log',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Container(
        decoration: const BoxDecoration(
          color: _navy,
          border: Border(bottom: BorderSide(color: Color(0x22FFFFFF), width: 1)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                  splashRadius: 20,
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.power_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Generator Usage',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Log generator running times',
                        style: TextStyle(fontSize: 10, color: Color(0x99FFFFFF)),
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

  Widget _timeTile(String title, String value, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFD),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8EDF5)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.access_time_rounded, size: 16, color: _navy),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11, color: _navyMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: _navyMuted),
            ],
          ),
        ),
      ),
    );
  }
}
