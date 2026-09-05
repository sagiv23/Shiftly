import 'package:flutter/material.dart';

import '../services/persistence_service.dart';

class SettingsProvider with ChangeNotifier {
  final PersistenceService _persistence;

  SettingsProvider(this._persistence) {
    _loadSettings();
  }

  ThemeMode _themeMode = ThemeMode.system;
  double _breakThresholdHours = 9.0;
  double _breakDurationMinutes = 45.0;

  ThemeMode get themeMode => _themeMode;

  double get breakThresholdHours => _breakThresholdHours;

  double get breakDurationMinutes => _breakDurationMinutes;

  void _loadSettings() {
    final box = _persistence.settingsBox;
    _themeMode = ThemeMode
        .values[box.get('themeMode', defaultValue: ThemeMode.system.index)];
    _breakThresholdHours = box.get('breakThresholdHours', defaultValue: 9.0);
    _breakDurationMinutes = box.get('breakDurationMinutes', defaultValue: 45.0);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _persistence.settingsBox.put('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setBreakRules(double threshold, double duration) async {
    _breakThresholdHours = threshold;
    _breakDurationMinutes = duration;
    await _persistence.settingsBox.put('breakThresholdHours', threshold);
    await _persistence.settingsBox.put('breakDurationMinutes', duration);
    notifyListeners();
  }
}
