import 'package:hive/hive.dart';

part 'customer_payment.g.dart';

enum PaymentStatus { unpaid, partiallyPaid, paid }

@HiveType(typeId: 6)
class CustomerPayment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double totalAmount;

  @HiveField(4)
  final double paidAmount;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String notes;

  CustomerPayment({
    required this.id,
    required this.customerId,
    required this.description,
    required this.totalAmount,
    this.paidAmount = 0,
    required this.createdAt,
    this.notes = '',
  })  : assert(totalAmount >= 0),
        assert(paidAmount >= 0);

  double get remainingAmount => (totalAmount - paidAmount).clamp(0.0, double.infinity);

  PaymentStatus get status {
    if (paidAmount <= 0) return PaymentStatus.unpaid;
    if (paidAmount >= totalAmount) return PaymentStatus.paid;
    return PaymentStatus.partiallyPaid;
  }

  CustomerPayment copyWith({
    String? description,
    double? totalAmount,
    double? paidAmount,
    String? notes,
  }) => CustomerPayment(
        id: id,
        customerId: customerId,
        description: description ?? this.description,
        totalAmount: totalAmount ?? this.totalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        createdAt: createdAt,
        notes: notes ?? this.notes,
      );
}
