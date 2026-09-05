import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../models/job_type.dart';
import '../models/shift.dart';
import '../services/persistence_service.dart';

class ShiftProvider with ChangeNotifier {
  final PersistenceService _persistence;

  ShiftProvider(this._persistence);

  List<Shift> get shifts =>
      _persistence.shiftsBox.values.toList()
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

  Future<void> addJobType(JobType jobType) async {
    await _persistence.jobTypesBox.put(jobType.id, jobType);
    notifyListeners();
  }

  Future<void> updateJobType(JobType jobType) async {
    await jobType.save();
    notifyListeners();
  }

  Future<void> deleteJobType(String id) async {
    await _persistence.jobTypesBox.delete(id);
    notifyListeners();
  }

  JobType? getJobTypeById(String id) {
    return _persistence.jobTypesBox.get(id);
  }

  Map<String, List<Shift>> get shiftsGroupedByMonth {
    return groupBy(
      shifts,
      (Shift s) => "${s.date.year}-${s.date.month.toString().padLeft(2, '0')}",
    );
  }
}
