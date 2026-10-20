// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_payment.dart';

class CustomerPaymentAdapter extends TypeAdapter<CustomerPayment> {
  @override
  final int typeId = 6;

  @override
  CustomerPayment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return CustomerPayment(
      id: fields[0] as String,
      customerId: fields[1] as String,
      description: fields[2] as String,
      totalAmount: (fields[3] as num).toDouble(),
      paidAmount: (fields[4] as num?)?.toDouble() ?? 0,
      createdAt: fields[5] as DateTime,
      notes: fields[6] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, CustomerPayment obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.paidAmount)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.notes);
  }
}
