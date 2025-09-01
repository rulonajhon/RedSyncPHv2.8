import 'package:hive/hive.dart';

part 'calculator_history.g.dart';

@HiveType(typeId: 3)
class CalculatorHistory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double weight;

  @HiveField(2)
  String factorType;

  @HiveField(3)
  double targetLevel;

  @HiveField(4)
  double calculatedDose;

  @HiveField(5)
  String notes;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  String uid;

  CalculatorHistory({
    required this.id,
    required this.weight,
    required this.factorType,
    required this.targetLevel,
    required this.calculatedDose,
    required this.notes,
    required this.createdAt,
    required this.uid,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'factorType': factorType,
      'targetLevel': targetLevel,
      'calculatedDose': calculatedDose,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'uid': uid,
    };
  }
}
