import 'package:flutter/material.dart';

class AppSettings {
  final double paidBreakDurationMinutes;
  final double unpaidBreakDurationMinutes;
  final ThemeMode themeMode;

  AppSettings({
    this.paidBreakDurationMinutes = 20.0,
    this.unpaidBreakDurationMinutes = 45.0,
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    double? paidBreakDurationMinutes,
    double? unpaidBreakDurationMinutes,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      paidBreakDurationMinutes:
          paidBreakDurationMinutes ?? this.paidBreakDurationMinutes,
      unpaidBreakDurationMinutes:
          unpaidBreakDurationMinutes ?? this.unpaidBreakDurationMinutes,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
