import 'package:flutter/material.dart';
import '../services/pos_service.dart';

class PosProvider extends ChangeNotifier {
  final PosService _posService = PosService();

  String? _lastResult;
  String? get lastResult => _lastResult;

  Future<void> readNfcCard() async {
    _lastResult = await _posService.startNfcTransaction();
    notifyListeners();
  }

  Future<void> readChipCard() async {
    _lastResult = await _posService.startChipTransaction();
    notifyListeners();
  }

  Future<void> readMagstripeCard() async {
    _lastResult = await _posService.startMagstripeTransaction();
    notifyListeners();
  }

  Future<void> requestPin() async {
    _lastResult = await _posService.requestPin();
    notifyListeners();
  }
}
