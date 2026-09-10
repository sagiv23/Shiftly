import 'package:hive/hive.dart';
import 'package:shiftly/models/wage_entry.dart';

part 'job_type.g.dart';

@HiveType(typeId: 0)
class JobType extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double hourlyRate;

  @HiveField(3)
  List<WageEntry>? wageHistory;

  JobType({
    required this.id,
    required this.name,
    this.hourlyRate = 40.22,
    this.wageHistory,
  });

  /// Returns the hourly rate effective on [date] (date-only comparison).
  double getRateForDate(DateTime date) {
    if (wageHistory == null || wageHistory!.isEmpty) {
      return hourlyRate;
    }

    final target = DateTime(date.year, date.month, date.day);

    // Sort history by date descending (newest first)
    final sortedHistory = List<WageEntry>.from(wageHistory!)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    for (final entry in sortedHistory) {
      final entryDate = DateTime(
        entry.startDate.year,
        entry.startDate.month,
        entry.startDate.day,
      );
      if (!entryDate.isAfter(target)) {
        return entry.hourlyRate;
      }
    }

    // Date is before all history — use the earliest known rate
    return sortedHistory.last.hourlyRate;
  }

  /// Syncs [hourlyRate] to whatever rate is effective today.
  void syncCurrentRate() {
    hourlyRate = getRateForDate(DateTime.now());
  }

  JobType copyWith({
    String? id,
    String? name,
    double? hourlyRate,
    List<WageEntry>? wageHistory,
  }) {
    return JobType(
      id: id ?? this.id,
      name: name ?? this.name,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      wageHistory: wageHistory ?? this.wageHistory,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hourlyRate': hourlyRate,
    // Note: complex types like wageHistory might need specific handling in JSON if used
  };

  factory JobType.fromJson(Map<String, dynamic> json) => JobType(
    id: json['id'],
    name: json['name'],
    hourlyRate: json['hourlyRate'],
  );
}
