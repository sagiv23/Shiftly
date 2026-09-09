import 'package:hive/hive.dart';

part 'wage_entry.g.dart';

@HiveType(typeId: 4)
class WageEntry extends HiveObject {
  @HiveField(0)
  DateTime startDate;

  @HiveField(1)
  double hourlyRate;

  WageEntry({required this.startDate, required this.hourlyRate});
}
