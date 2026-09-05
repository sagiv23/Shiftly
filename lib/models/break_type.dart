import 'package:hive/hive.dart';

part 'break_type.g.dart';

@HiveType(typeId: 2)
enum BreakType {
  @HiveField(0)
  none,
  @HiveField(1)
  twentyMinPaid,
  @HiveField(2)
  fortyFiveMinUnpaid,
}
