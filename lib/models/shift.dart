import 'package:hive/hive.dart';

import 'break_type.dart';

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

  @HiveField(7)
  BreakType? breakType;

  @HiveField(8)
  double? unpaidBreakMinutes;

  Shift({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.jobTypeId,
    this.tips = 0.0,
    this.breakType = BreakType.none,
    this.unpaidBreakMinutes = 45.0,
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
    if ((breakType ?? BreakType.none) == BreakType.unpaid) {
      return durationHours - ((unpaidBreakMinutes ?? 45.0) / 60.0);
    }
    return durationHours;
  }

  double calculateTotalPay(double hourlyRate) {
    return (netHours * hourlyRate) + tips;
  }
}
