import 'package:hive_flutter/hive_flutter.dart';
import 'package:shiftly/models/break_type.dart';
import 'package:shiftly/models/expense.dart';
import 'package:shiftly/models/job_type.dart';
import 'package:shiftly/models/shift.dart';

class PersistenceService {
  static const String shiftsBoxName = 'shifts';
  static const String jobTypesBoxName = 'job_types';
  static const String settingsBoxName = 'settings';
  static const String expensesBoxName = 'expenses';

  Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(JobTypeAdapter());
    Hive.registerAdapter(ShiftAdapter());
    Hive.registerAdapter(BreakTypeAdapter());
    Hive.registerAdapter(ExpenseAdapter());

    await Hive.openBox<Shift>(shiftsBoxName);
    await Hive.openBox<JobType>(jobTypesBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
    await Hive.openBox<Expense>(expensesBoxName);

    // Seed default job types if empty
    final jobBox = Hive.box<JobType>(jobTypesBoxName);
    if (jobBox.isEmpty) {
      final defaultJobs = [
        JobType(id: '1', name: 'סדרן', hourlyRate: 37.20),
        JobType(id: '2', name: 'מזנון', hourlyRate: 40.22),
        JobType(id: '3', name: 'פריקה', hourlyRate: 40.22),
      ];
      for (var job in defaultJobs) {
        await jobBox.put(job.id, job);
      }
    }
  }

  Box<Shift> get shiftsBox => Hive.box<Shift>(shiftsBoxName);

  Box<JobType> get jobTypesBox => Hive.box<JobType>(jobTypesBoxName);

  Box<Expense> get expensesBox => Hive.box<Expense>(expensesBoxName);

  Box<dynamic> get settingsBox => Hive.box<dynamic>(settingsBoxName);
}
