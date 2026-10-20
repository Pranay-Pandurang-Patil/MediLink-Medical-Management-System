import 'package:hive/hive.dart';

part 'customer_medicine.g.dart';

@HiveType(typeId: 5)
class CustomerMedicine {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final String medicineName;

  @HiveField(3)
  final String notes;

  @HiveField(4)
  final DateTime createdAt;

  CustomerMedicine({
    required this.id,
    required this.customerId,
    required this.medicineName,
    this.notes = '',
    required this.createdAt,
  });

  CustomerMedicine copyWith({String? medicineName, String? notes}) =>
      CustomerMedicine(
        id: id,
        customerId: customerId,
        medicineName: medicineName ?? this.medicineName,
        notes: notes ?? this.notes,
        createdAt: createdAt,
      );
}
