import 'dart:async';

import 'package:flutter/material.dart';

import '../services/persistence_service.dart';

class TimerProvider with ChangeNotifier {
  final PersistenceService _persistence;
  Timer? _ticker;

  TimerProvider(this._persistence) {
    _loadState();
  }

  DateTime? _startTime;
  bool _isRunning = false;
  bool _isOnBreak = false;
  DateTime? _breakStartTime;
  double _accumulatedBreakMinutes = 0.0;
  String? _jobTypeId;
  double _tips = 0.0;

  DateTime? get startTime => _startTime;

  bool get isRunning => _isRunning;

  bool get isOnBreak => _isOnBreak;

  double get accumulatedBreakMinutes => _accumulatedBreakMinutes;

  String? get jobTypeId => _jobTypeId;

  double get tips => _tips;

  Duration get elapsed {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  Duration get currentBreakElapsed {
    if (_breakStartTime == null) return Duration.zero;
    return DateTime.now().difference(_breakStartTime!);
  }

  double get netMinutes {
    if (_startTime == null) return 0.0;

    final totalElapsedSeconds = DateTime.now()
        .difference(_startTime!)
        .inSeconds;

    double breakSeconds = _accumulatedBreakMinutes * 60.0;
    if (_isOnBreak && _breakStartTime != null) {
      breakSeconds += DateTime.now().difference(_breakStartTime!).inSeconds;
    }

    double netSec = (totalElapsedSeconds - breakSeconds);
    return netSec < 0 ? 0.0 : netSec / 60.0;
  }

  double calculateLivePay(double hourlyRate) {
    return (netMinutes / 60.0 * hourlyRate) + _tips;
  }

  void _loadState() {
    final box = _persistence.settingsBox;
    final startMillis = box.get('timerStartTime');
    if (startMillis != null) {
      _startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
      _isRunning = true;
      _startTicker();
    }
    _isOnBreak = box.get('timerIsOnBreak', defaultValue: false);
    final breakStartMillis = box.get('timerBreakStartTime');
    if (breakStartMillis != null) {
      _breakStartTime = DateTime.fromMillisecondsSinceEpoch(breakStartMillis);
    }
    _accumulatedBreakMinutes = box.get(
      'timerAccumulatedBreakMinutes',
      defaultValue: 0.0,
    );
    _jobTypeId = box.get('timerJobTypeId');
    _tips = box.get('timerTips', defaultValue: 0.0);
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void setJobType(String id) {
    _jobTypeId = id;
    _persistence.settingsBox.put('timerJobTypeId', id);
    notifyListeners();
  }

  void setTips(double val) {
    _tips = val;
    _persistence.settingsBox.put('timerTips', val);
    notifyListeners();
  }

  Future<void> startShift(String jobTypeId) async {
    _startTime = DateTime.now();
    _isRunning = true;
    _jobTypeId = jobTypeId;
    _accumulatedBreakMinutes = 0.0;
    _tips = 0.0;
    _isOnBreak = false;

    final box = _persistence.settingsBox;
    await box.put('timerStartTime', _startTime!.millisecondsSinceEpoch);
    await box.put('timerJobTypeId', _jobTypeId);
    await box.put('timerAccumulatedBreakMinutes', 0.0);
    await box.put('timerTips', 0.0);
    await box.put('timerIsOnBreak', false);
    await box.delete('timerBreakStartTime');

    _startTicker();
    notifyListeners();
  }

  Future<void> stopShift() async {
    if (_isOnBreak) {
      await toggleBreak();
    }
    _isRunning = false;
    _ticker?.cancel();
    await _persistence.settingsBox.put(
      'timerIsRunning',
      false,
    ); // Optional helper
    notifyListeners();
  }

  Future<void> toggleBreak() async {
    if (!_isRunning) return;

    final box = _persistence.settingsBox;
    if (_isOnBreak) {
      // End break
      if (_breakStartTime != null) {
        final breakDuration = DateTime.now().difference(_breakStartTime!);
        _accumulatedBreakMinutes += breakDuration.inSeconds / 60.0;
      }
      _isOnBreak = false;
      _breakStartTime = null;
      await box.put('timerIsOnBreak', false);
      await box.put('timerAccumulatedBreakMinutes', _accumulatedBreakMinutes);
      await box.delete('timerBreakStartTime');
    } else {
      // Start break
      _isOnBreak = true;
      _breakStartTime = DateTime.now();
      await box.put('timerIsOnBreak', true);
      await box.put(
        'timerBreakStartTime',
        _breakStartTime!.millisecondsSinceEpoch,
      );
    }
    notifyListeners();
  }

  Future<void> resetTimer() async {
    _ticker?.cancel();
    _startTime = null;
    _isRunning = false;
    _isOnBreak = false;
    _breakStartTime = null;
    _accumulatedBreakMinutes = 0.0;
    _tips = 0.0;

    final box = _persistence.settingsBox;
    await box.delete('timerStartTime');
    await box.delete('timerIsOnBreak');
    await box.delete('timerBreakStartTime');
    await box.delete('timerAccumulatedBreakMinutes');
    await box.delete('timerTips');

    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
