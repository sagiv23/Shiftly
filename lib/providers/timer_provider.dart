import 'dart:async';

import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/persistence_service.dart';

class TimerProvider with ChangeNotifier {
  final PersistenceService _persistence;
  Timer? _ticker;

  TimerProvider(this._persistence) {
    _loadState();
    NotificationService.onActionReceived = (actionId) {
      if (actionId == 'toggle_break') {
        toggleBreak();
      } else if (actionId == 'stop_shift') {
        // Just stop the timer, navigation is handled in NotificationService
        stopShift();
      }
    };
  }

  DateTime? _startTime;
  DateTime? _reviewEndTime;
  bool _isRunning = false;
  bool _isOnBreak = false;
  DateTime? _breakStartTime;
  double _accumulatedBreakMinutes = 0.0;
  String? _jobTypeId;
  double _tips = 0.0;

  DateTime? get startTime => _startTime;
  DateTime? get reviewEndTime => _reviewEndTime;
  bool get isRunning => _isRunning;
  bool get isOnBreak => _isOnBreak;
  double get accumulatedBreakMinutes => _accumulatedBreakMinutes;
  String? get jobTypeId => _jobTypeId;
  double get tips => _tips;

  Duration get elapsed {
    if (_startTime == null) return Duration.zero;
    final end = _isRunning
        ? DateTime.now()
        : (_reviewEndTime ?? DateTime.now());
    return end.difference(_startTime!);
  }

  Duration get currentBreakElapsed {
    if (_breakStartTime == null) return Duration.zero;
    return DateTime.now().difference(_breakStartTime!);
  }

  double get netMinutes {
    if (_startTime == null) return 0.0;

    final end = _isRunning
        ? DateTime.now()
        : (_reviewEndTime ?? DateTime.now());
    final totalElapsedSeconds = end.difference(_startTime!).inSeconds;

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
      _isRunning = box.get('timerIsRunning', defaultValue: true);
      if (_isRunning) _startTicker();
    }

    final reviewEndMillis = box.get('timerReviewEndTime');
    if (reviewEndMillis != null) {
      _reviewEndTime = DateTime.fromMillisecondsSinceEpoch(reviewEndMillis);
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
    _reviewEndTime = null;
    _isRunning = true;
    _jobTypeId = jobTypeId;
    _accumulatedBreakMinutes = 0.0;
    _tips = 0.0;
    _isOnBreak = false;

    final box = _persistence.settingsBox;
    await box.put('timerStartTime', _startTime!.millisecondsSinceEpoch);
    await box.put('timerIsRunning', true);
    await box.delete('timerReviewEndTime');
    await box.put('timerJobTypeId', _jobTypeId);
    await box.put('timerAccumulatedBreakMinutes', 0.0);
    await box.put('timerTips', 0.0);
    await box.put('timerIsOnBreak', false);
    await box.delete('timerBreakStartTime');

    _updateNotification();
    _startTicker();
    notifyListeners();
  }

  Future<void> stopShift() async {
    if (_isOnBreak) {
      await toggleBreak();
    }
    _isRunning = false;
    _reviewEndTime = DateTime.now();
    _ticker?.cancel();

    final box = _persistence.settingsBox;
    await box.put('timerIsRunning', false);
    await box.put('timerReviewEndTime', _reviewEndTime!.millisecondsSinceEpoch);

    NotificationService.cancelNotification(100);
    notifyListeners();
  }

  Future<void> resumeShift() async {
    if (_startTime != null && _reviewEndTime != null) {
      final pauseDuration = DateTime.now().difference(_reviewEndTime!);
      _startTime = _startTime!.add(pauseDuration);
    }

    _isRunning = true;
    _reviewEndTime = null;

    final box = _persistence.settingsBox;
    await box.put('timerStartTime', _startTime?.millisecondsSinceEpoch);
    await box.put('timerIsRunning', true);
    await box.delete('timerReviewEndTime');

    _updateNotification();
    _startTicker();
    notifyListeners();
  }

  void _updateNotification() {
    if (!_isRunning || _startTime == null) return;
    NotificationService.showTimerNotification(
      id: 100,
      title: _isOnBreak ? 'משמרת בהפסקה' : 'משמרת פעילה',
      body: _isOnBreak ? 'הטיימר מושהה' : 'הטיימר רץ...',
      startTime: _startTime!,
      isOnBreak: _isOnBreak,
    );
  }

  Future<void> toggleBreak() async {
    if (!_isRunning && _reviewEndTime == null) return;

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
    if (_isRunning) _updateNotification();
    notifyListeners();
  }

  Future<void> resetTimer() async {
    _ticker?.cancel();
    _startTime = null;
    _reviewEndTime = null;
    _isRunning = false;
    _isOnBreak = false;
    _breakStartTime = null;
    _accumulatedBreakMinutes = 0.0;
    _tips = 0.0;

    final box = _persistence.settingsBox;
    await box.delete('timerStartTime');
    await box.delete('timerIsRunning');
    await box.delete('timerReviewEndTime');
    await box.delete('timerIsOnBreak');
    await box.delete('timerBreakStartTime');
    await box.delete('timerAccumulatedBreakMinutes');
    await box.delete('timerTips');

    NotificationService.cancelNotification(100);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
