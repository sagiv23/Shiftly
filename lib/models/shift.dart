import 'package:hive/hive.dart';
import 'job_type.dart';

part 'shift.g.dart';

@HiveType(typeId: 1)
class Shift extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  DateTime startTime;

  @HiveField(3)
  DateTime endTime;

  @HiveField(4)
  String jobTypeId;

  @HiveField(5)
  double tips;

  @HiveField(6)
  double breakMinutes;

  Shift({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.jobTypeId,
    this.tips = 0.0,
    this.breakMinutes = 0.0,
  });

  double get durationHours {
    var diff = endTime.difference(startTime).inMinutes / 60.0;
    if (diff < 0) {
      // Overnight shift support
      diff += 24.0;
    }
    return diff;
  }

  double get netHours {
    return durationHours - (breakMinutes / 60.0);
  }

  double calculateTotalPay(double hourlyRate) {
    return (netHours * hourlyRate) + tips;
  }
}
