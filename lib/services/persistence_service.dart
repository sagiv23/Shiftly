import 'package:hive_flutter/hive_flutter.dart';
import 'package:shiftly/models/break_type.dart';
import 'package:shiftly/models/expense.dart';
import 'package:shiftly/models/job_type.dart';
import 'package:shiftly/models/shift.dart';
import 'package:shiftly/models/wage_entry.dart';

class PersistenceService {
  static const String shiftsBoxName = 'shifts';
  static const String jobTypesBoxName = 'job_types';
  static const String settingsBoxName = 'settings';
  static const String expensesBoxName = 'expenses';
  static const String wageHistoryMigratedKey = 'wageHistoryMigrated_v1';

  Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(JobTypeAdapter());
    Hive.registerAdapter(ShiftAdapter());
    Hive.registerAdapter(BreakTypeAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(WageEntryAdapter());

    await Hive.openBox<Shift>(shiftsBoxName);
    await Hive.openBox<JobType>(jobTypesBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
    await Hive.openBox<Expense>(expensesBoxName);

    // Seed default job types if empty
    final jobBox = Hive.box<JobType>(jobTypesBoxName);
    if (jobBox.isEmpty) {
      final epoch = DateTime(2020, 1, 1);
      final defaultJobs = [
        JobType(
          id: '1',
          name: 'סדרן',
          hourlyRate: 37.20,
          wageHistory: [WageEntry(startDate: epoch, hourlyRate: 37.20)],
        ),
        JobType(
          id: '2',
          name: 'מזנון',
          hourlyRate: 40.22,
          wageHistory: [WageEntry(startDate: epoch, hourlyRate: 40.22)],
        ),
        JobType(
          id: '3',
          name: 'פריקה',
          hourlyRate: 40.22,
          wageHistory: [WageEntry(startDate: epoch, hourlyRate: 40.22)],
        ),
      ];
      for (var job in defaultJobs) {
        await jobBox.put(job.id, job);
      }
    }

    await _migrateWageHistory();
  }

  /// Backfills wageHistory on jobs and snapshots hourlyRate on existing shifts.
  Future<void> _migrateWageHistory() async {
    final settings = settingsBox;
    if (settings.get(wageHistoryMigratedKey) == true) return;

    final jobBox = jobTypesBox;
    final shiftBox = shiftsBox;

    for (final job in jobBox.values) {
      if (job.wageHistory == null || job.wageHistory!.isEmpty) {
        final jobShifts = shiftBox.values
            .where((s) => s.jobTypeId == job.id)
            .toList();
        DateTime startDate;
        if (jobShifts.isNotEmpty) {
          startDate = jobShifts
              .map((s) => s.date)
              .reduce((a, b) => a.isBefore(b) ? a : b);
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
        } else {
          // Far past so any future lookup still resolves to this rate
          startDate = DateTime(2020, 1, 1);
        }
        job.wageHistory = [
          WageEntry(startDate: startDate, hourlyRate: job.hourlyRate),
        ];
        job.syncCurrentRate();
        await job.save();
      }
    }

    for (final shift in shiftBox.values) {
      if (shift.hourlyRate != null) continue;

      JobType? job = jobBox.get(shift.jobTypeId);
      if (job == null) {
        for (final j in jobBox.values) {
          if (j.id == shift.jobTypeId) {
            job = j;
            break;
          }
        }
      }

      if (job != null) {
        shift.hourlyRate = job.getRateForDate(shift.date);
        await shift.save();
      }
    }

    await settings.put(wageHistoryMigratedKey, true);
  }

  Box<Shift> get shiftsBox => Hive.box<Shift>(shiftsBoxName);

  Box<JobType> get jobTypesBox => Hive.box<JobType>(jobTypesBoxName);

  Box<Expense> get expensesBox => Hive.box<Expense>(expensesBoxName);

  Box<dynamic> get settingsBox => Hive.box<dynamic>(settingsBoxName);
}
