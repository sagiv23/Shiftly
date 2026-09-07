import 'package:flutter/material.dart';
import 'package:shiftly/services/persistence_service.dart';

class SettingsProvider with ChangeNotifier {
  final PersistenceService _persistence;

  SettingsProvider(this._persistence) {
    _loadSettings();
  }

  ThemeMode _themeMode = ThemeMode.system;
  double _paidBreakDurationMinutes = 20.0;
  double _unpaidBreakDurationMinutes = 45.0;
  bool _hasCompletedOnboarding = false;
  bool _shiftRemindersEnabled = true;

  ThemeMode get themeMode => _themeMode;

  double get paidBreakDurationMinutes => _paidBreakDurationMinutes;

  double get unpaidBreakDurationMinutes => _unpaidBreakDurationMinutes;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  bool get shiftRemindersEnabled => _shiftRemindersEnabled;

  void _loadSettings() {
    final box = _persistence.settingsBox;
    _themeMode = ThemeMode
        .values[box.get('themeMode', defaultValue: ThemeMode.system.index)];
    _paidBreakDurationMinutes = box.get(
      'paidBreakDurationMinutes',
      defaultValue: 20.0,
    );
    _unpaidBreakDurationMinutes = box.get(
      'unpaidBreakDurationMinutes',
      defaultValue: 45.0,
    );
    _hasCompletedOnboarding = box.get(
      'hasCompletedOnboarding',
      defaultValue: false,
    );
    _shiftRemindersEnabled = box.get(
      'shiftRemindersEnabled',
      defaultValue: true,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _persistence.settingsBox.put('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setShiftRemindersEnabled(bool enabled) async {
    _shiftRemindersEnabled = enabled;
    await _persistence.settingsBox.put('shiftRemindersEnabled', enabled);
    notifyListeners();
  }

  Future<void> setBreakDurations(double paid, double unpaid) async {
    _paidBreakDurationMinutes = paid;
    _unpaidBreakDurationMinutes = unpaid;
    await _persistence.settingsBox.put('paidBreakDurationMinutes', paid);
    await _persistence.settingsBox.put('unpaidBreakDurationMinutes', unpaid);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    await _persistence.settingsBox.put('hasCompletedOnboarding', true);
    notifyListeners();
  }
}
