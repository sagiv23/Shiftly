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

  @HiveField(9)
  List<double>? individualTips;

  Shift({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.jobTypeId,
    this.tips = 0.0,
    this.breakType = BreakType.none,
    this.unpaidBreakMinutes = 45.0,
    this.individualTips,
  });

  double get durationHours {
    // Use seconds for high precision, especially for short timer-based shifts
    var diff = endTime.difference(startTime).inSeconds / 3600.0;
    if (diff < 0) {
      // Overnight shift support
      diff += 24.0;
    }
    return diff;
  }

  double get netHours {
    double net;
    if ((breakType ?? BreakType.none) == BreakType.unpaid) {
      net = durationHours - ((unpaidBreakMinutes ?? 45.0) / 60.0);
    } else {
      net = durationHours;
    }
    return net < 0 ? 0.0 : net;
  }

  double calculateTotalPay(double hourlyRate) {
    return (netHours * hourlyRate) + tips;
  }
}
