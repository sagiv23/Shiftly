import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/job_type.dart';
import '../models/shift.dart';
import '../services/persistence_service.dart';

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

  Future<void> addShift(Shift shift) async {
    await _persistence.shiftsBox.put(shift.id, shift);
    notifyListeners();
  }

  Future<void> updateShift(Shift shift) async {
    await shift.save();
    notifyListeners();
  }

  Future<void> deleteShift(String id) async {
    await _persistence.shiftsBox.delete(id);
    notifyListeners();
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
    notifyListeners();
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
      (Expense e) =>
          "${e.date.year}-${e.date.month.toString().padLeft(2, '0')}",
    );
  }
}
