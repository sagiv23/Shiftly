import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 3)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String description;

  @HiveField(3)
  double amount;

  Expense({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'description': description,
    'amount': amount,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'],
    date: DateTime.parse(json['date']),
    description: json['description'],
    amount: json['amount'],
  );
}
