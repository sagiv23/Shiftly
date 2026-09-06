import 'package:hive/hive.dart';

part 'job_type.g.dart';

@HiveType(typeId: 0)
class JobType extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double hourlyRate;

  JobType({required this.id, required this.name, this.hourlyRate = 40.22});

  JobType copyWith({
    String? id,
    String? name,
    double? hourlyRate,
  }) {
    return JobType(
      id: id ?? this.id,
      name: name ?? this.name,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hourlyRate': hourlyRate,
  };

  factory JobType.fromJson(Map<String, dynamic> json) => JobType(
    id: json['id'],
    name: json['name'],
    hourlyRate: json['hourlyRate'],
  );
}
