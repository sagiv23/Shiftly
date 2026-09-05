import 'package:flutter/material.dart';

class AppSettings {
  final double breakThresholdHours;
  final double breakDurationMinutes;
  final ThemeMode themeMode;

  AppSettings({
    this.breakThresholdHours = 9.0,
    this.breakDurationMinutes = 45.0,
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    double? breakThresholdHours,
    double? breakDurationMinutes,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      breakThresholdHours: breakThresholdHours ?? this.breakThresholdHours,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
