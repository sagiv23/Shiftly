import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:shiftly/models/expense.dart';
import 'package:shiftly/models/job_type.dart';
import 'package:shiftly/models/shift.dart';
import 'package:shiftly/services/notification_service.dart';
import 'package:shiftly/services/persistence_service.dart';

class ShiftProvider with ChangeNotifier {
  final PersistenceService _persistence;

  ShiftProvider(this._persistence);

  // Shifts
  List<Shift> get shifts =>
      _persistence.shiftsBox.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  // Expenses
  List<Expense> get expenses =>
      _persistence.expensesBox.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<JobType> get jobTypes => _persistence.jobTypesBox.values.toList();

  bool get _remindersEnabled =>
      _persistence.settingsBox.get('shiftRemindersEnabled', defaultValue: true);

  double get _reminderDuration => _persistence.settingsBox.get(
    'shiftReminderDurationHours',
    defaultValue: 4.0,
  );

  Future<void> addShift(Shift shift) async {
    await _persistence.shiftsBox.put(shift.id, shift);
    _scheduleReminder(shift);
    notifyListeners();
  }

  Future<void> updateShift(Shift shift) async {
    await shift.save();
    _scheduleReminder(shift);
    notifyListeners();
  }

  Future<void> deleteShift(String id) async {
    await _persistence.shiftsBox.delete(id);
    NotificationService.cancelNotification(id.hashCode);
    notifyListeners();
  }

  void _scheduleReminder(Shift shift) {
    if (!_remindersEnabled) return;

    final job = getJobTypeById(shift.jobTypeId);
    NotificationService.scheduleShiftReminder(
      id: shift.id.hashCode,
      shiftName: job?.name ?? 'משמרת',
      startTime: shift.startTime,
      reminderDurationHours: _reminderDuration,
    );
  }

  void refreshAllReminders() {
    // Cancel all first
    for (var shift in shifts) {
      NotificationService.cancelNotification(shift.id.hashCode);
    }

    // Schedule only if enabled
    if (_remindersEnabled) {
      for (var shift in shifts) {
        _scheduleReminder(shift);
      }
    }
  }

  // Expense Methods
  Future<void> addExpense(Expense expense) async {
    await _persistence.expensesBox.put(expense.id, expense);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await expense.save();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _persistence.expensesBox.delete(id);
    notifyListeners();
  }

  Future<void> addJobType(JobType jobType) async {
    await _persistence.jobTypesBox.put(jobType.id, jobType);
    notifyListeners();
  }

  Future<void> updateJobType(JobType jobType) async {
    if (jobType.isInBox) {
      await jobType.save();
    } else {
      await _persistence.jobTypesBox.put(jobType.id, jobType);
    }
    // Keep shift snapshots in sync with the updated wage history
    await _resyncShiftRatesForJob(jobType);
    notifyListeners();
  }

  /// Re-applies [JobType.getRateForDate] onto every shift for this job so
  /// wage history edits (raises, reverts, effective-date changes) show up
  /// immediately without requiring each shift to be re-saved.
  Future<void> _resyncShiftRatesForJob(JobType job) async {
    for (final shift in _persistence.shiftsBox.values) {
      if (shift.jobTypeId != job.id) continue;
      final rate = job.getRateForDate(shift.date);
      if (shift.hourlyRate != rate) {
        shift.hourlyRate = rate;
        await shift.save();
      }
    }
  }

  Future<void> deleteJobType(String id) async {
    await _persistence.jobTypesBox.delete(id);
    notifyListeners();
  }

  JobType? getJobTypeById(String id) {
    // Try key lookup first
    var job = _persistence.jobTypesBox.get(id);
    if (job != null) return job;

    // Fallback: search by id field in case keys are indexed differently
    return jobTypes.firstWhereOrNull((j) => j.id == id);
  }

  Map<String, List<Shift>> get shiftsGroupedByMonth {
    return groupBy(
      shifts,
      (Shift s) => "${s.date.year}-${s.date.month.toString().padLeft(2, '0')}",
    );
  }

  Map<String, List<Expense>> get expensesGroupedByMonth {
    return groupBy(
      expenses,
      (Expense e) => "${e.date.year}-${e.date.month.toString().padLeft(2, '0')}",
    );
  }

  Future<void> factoryReset() async {
    // 1. Cancel all notifications
    for (var shift in shifts) {
      NotificationService.cancelNotification(shift.id.hashCode);
    }
    // 2. Clear persistence
    await _persistence.deleteAllData();
    // 3. Notify listeners
    notifyListeners();
  }
}
