// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regular_customer.dart';

class RegularCustomerAdapter extends TypeAdapter<RegularCustomer> {
  @override
  final int typeId = 4;

  @override
  RegularCustomer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return RegularCustomer(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String? ?? '',
      notes: fields[3] as String? ?? '',
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RegularCustomer obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }
}
