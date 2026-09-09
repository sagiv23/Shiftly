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

  double getRateForDate(DateTime date) {
    if (wageHistory == null || wageHistory!.isEmpty) {
      return hourlyRate;
    }

    // Sort history by date descending
    final sortedHistory = List<WageEntry>.from(wageHistory!)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    // Find the first entry that started on or before the given date
    for (var entry in sortedHistory) {
      if (!entry.startDate.isAfter(date)) {
        return entry.hourlyRate;
      }
    }

    // If no entry found (date is before all history), return the earliest rate
    return sortedHistory.last.hourlyRate;
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
