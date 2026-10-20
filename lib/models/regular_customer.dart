import 'package:hive/hive.dart';

part 'regular_customer.g.dart';

@HiveType(typeId: 4)
class RegularCustomer {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  final String notes;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  RegularCustomer({
    required this.id,
    required this.name,
    this.phone = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  RegularCustomer copyWith({
    String? name,
    String? phone,
    String? notes,
    DateTime? updatedAt,
  }) => RegularCustomer(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
