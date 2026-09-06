import 'dart:async';
import 'package:flutter/material.dart';
import '../models/break_type.dart';
import '../services/notification_service.dart';
import '../services/persistence_service.dart';

class TimerProvider with ChangeNotifier {
  final PersistenceService _persistence;
  Timer? _ticker;

  TimerProvider(this._persistence) {
    _loadState();
    NotificationService.onActionReceived = (actionId) {
      final box = _persistence.settingsBox;
      final paidDur = box.get('paidBreakDurationMinutes', defaultValue: 20.0);
      final unpaidDur = box.get('unpaidBreakDurationMinutes', defaultValue: 45.0);

      if (actionId == 'start_paid_break') {
        toggleBreak(BreakType.paid, paidDur);
      } else if (actionId == 'start_unpaid_break') {
        toggleBreak(BreakType.unpaid, unpaidDur);
      } else if (actionId == 'end_break') {
        endBreak();
      } else if (actionId == 'stop_shift') {
        stopShift();
      }
    };
  }

  DateTime? _startTime;
  DateTime? _reviewEndTime;
  bool _isRunning = false;

  bool _isOnBreak = false;
  BreakType? _activeBreakType;
  DateTime? _breakStartTime;
  double _activeBreakDurationMinutes = 0.0;

  // Total seconds to deduct from (now - startTime)
  // This includes finished unpaid breaks and pauses in review mode.
  double _totalDeductedSeconds = 0.0;
  
  String? _jobTypeId;
  double _tips = 0.0;

  DateTime? get startTime => _startTime;
  DateTime? get reviewEndTime => _reviewEndTime;
  bool get isRunning => _isRunning;
  bool get isOnBreak => _isOnBreak;
  BreakType? get activeBreakType => _activeBreakType;
  
  // For the Shift model: only unpaid break time is stored here
  double get accumulatedUnpaidMinutes {
    // We don't want to include "pauses" from review mode in the official "Break" field of the shift,
    // but for the sake of the Shift model's netHours calculation, we can treat them as unpaid break.
    return _totalDeductedSeconds / 60.0;
  }

  String? get jobTypeId => _jobTypeId;
  double get tips => _tips;

  Duration get elapsed {
    if (_startTime == null) return Duration.zero;
    
    DateTime end;
    double currentDeduction = _totalDeductedSeconds;

    if (_isOnBreak) {
      end = _breakStartTime!;
      // If currently on unpaid break, time is already "frozen" at _breakStartTime.
      // If it's a PAID break, the clock keeps running, so we use now.
      if (_activeBreakType == BreakType.paid) {
        end = _isRunning ? DateTime.now() : (_reviewEndTime ?? DateTime.now());
      }
    } else {
      end = _isRunning ? DateTime.now() : (_reviewEndTime ?? DateTime.now());
    }

    final duration = end.difference(_startTime!).inSeconds - currentDeduction.toInt();
    return Duration(seconds: duration < 0 ? 0 : duration);
  }

  Duration get breakRemaining {
    if (!_isOnBreak || _breakStartTime == null) return Duration.zero;
    final elapsedBreak = DateTime.now().difference(_breakStartTime!);
    final totalBreak = Duration(
      seconds: (_activeBreakDurationMinutes * 60).toInt(),
    );
    final remaining = totalBreak - elapsedBreak;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double get netMinutes {
    if (_startTime == null) return 0.0;
    return elapsed.inSeconds / 60.0;
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

    final bTypeIdx = box.get('timerActiveBreakType');
    if (bTypeIdx != null) _activeBreakType = BreakType.values[bTypeIdx];

    _activeBreakDurationMinutes = box.get(
      'timerActiveBreakDuration',
      defaultValue: 0.0,
    );
    _totalDeductedSeconds = box.get(
      'timerTotalDeductedSeconds',
      defaultValue: 0.0,
    );
    _jobTypeId = box.get('timerJobTypeId');
    _tips = box.get('timerTips', defaultValue: 0.0);

    if (_isRunning) _startTicker();
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
    _totalDeductedSeconds = 0.0;
    _tips = 0.0;
    _isOnBreak = false;
    _activeBreakType = null;

    final box = _persistence.settingsBox;
    await box.put('timerStartTime', _startTime!.millisecondsSinceEpoch);
    await box.put('timerIsRunning', true);
    await box.delete('timerReviewEndTime');
    await box.put('timerJobTypeId', _jobTypeId);
    await box.put('timerTotalDeductedSeconds', 0.0);
    await box.put('timerTips', 0.0);
    await box.put('timerIsOnBreak', false);
    await box.delete('timerBreakStartTime');
    await box.delete('timerActiveBreakType');

    _updateNotification();
    _startTicker();
    notifyListeners();
  }

  Future<void> stopShift() async {
    if (_isOnBreak) {
      await endBreak();
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
      // Add the time spent in review mode to deductions
      final pauseSeconds = DateTime.now().difference(_reviewEndTime!).inSeconds;
      _totalDeductedSeconds += pauseSeconds;
    }

    _isRunning = true;
    _reviewEndTime = null;

    final box = _persistence.settingsBox;
    await box.put('timerIsRunning', true);
    await box.delete('timerReviewEndTime');
    await box.put('timerTotalDeductedSeconds', _totalDeductedSeconds);

    _updateNotification();
    _startTicker();
    notifyListeners();
  }

  Future<void> toggleBreak(BreakType type, double duration) async {
    if (!_isRunning && _reviewEndTime == null) return;

    if (_isOnBreak && _activeBreakType == type) {
      await endBreak();
    } else {
      // If switching from another break, finalize previous if it was unpaid
      if (_isOnBreak && _activeBreakType == BreakType.unpaid) {
        _totalDeductedSeconds +=
            DateTime.now().difference(_breakStartTime!).inSeconds;
      }

      _isOnBreak = true;
      _activeBreakType = type;
      _activeBreakDurationMinutes = duration;
      _breakStartTime = DateTime.now();

      final box = _persistence.settingsBox;
      await box.put('timerIsOnBreak', true);
      await box.put('timerActiveBreakType', type.index);
      await box.put('timerActiveBreakDuration', duration);
      await box.put(
        'timerBreakStartTime',
        _breakStartTime!.millisecondsSinceEpoch,
      );
      await box.put('timerTotalDeductedSeconds', _totalDeductedSeconds);
    }

    if (_isRunning) _updateNotification();
    notifyListeners();
  }

  Future<void> endBreak() async {
    if (!_isOnBreak) return;

    if (_activeBreakType == BreakType.unpaid && _breakStartTime != null) {
      _totalDeductedSeconds +=
          DateTime.now().difference(_breakStartTime!).inSeconds;
    }

    _isOnBreak = false;
    _activeBreakType = null;
    _breakStartTime = null;

    final box = _persistence.settingsBox;
    await box.put('timerIsOnBreak', false);
    await box.delete('timerActiveBreakType');
    await box.delete('timerBreakStartTime');
    await box.put('timerTotalDeductedSeconds', _totalDeductedSeconds);

    notifyListeners();
  }

  void _updateNotification() {
    if (!_isRunning || _startTime == null) return;
    NotificationService.showTimerNotification(
      id: 100,
      title: _isOnBreak
          ? (_activeBreakType == BreakType.paid
                ? 'הפסקה בתשלום'
                : 'הפסקה ללא תשלום')
          : 'משמרת פעילה',
      body: _isOnBreak
          ? 'ספירה לאחור: ${breakRemaining.inMinutes}:${(breakRemaining.inSeconds % 60).toString().padLeft(2, '0')}'
          : 'הטיימר רץ...',
      startTime: _startTime!,
      isOnBreak: _isOnBreak,
    );
  }

  Future<void> resetTimer() async {
    _ticker?.cancel();
    _startTime = null;
    _reviewEndTime = null;
    _isRunning = false;
    _isOnBreak = false;
    _breakStartTime = null;
    _activeBreakType = null;
    _totalDeductedSeconds = 0.0;
    _tips = 0.0;

    final box = _persistence.settingsBox;
    await box.delete('timerStartTime');
    await box.delete('timerIsRunning');
    await box.delete('timerReviewEndTime');
    await box.delete('timerIsOnBreak');
    await box.delete('timerActiveBreakType');
    await box.delete('timerBreakStartTime');
    await box.delete('timerActiveBreakDuration');
    await box.delete('timerAccumulatedUnpaidMinutes');
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
