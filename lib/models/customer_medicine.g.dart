// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_medicine.dart';

class CustomerMedicineAdapter extends TypeAdapter<CustomerMedicine> {
  @override
  final int typeId = 5;

  @override
  CustomerMedicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return CustomerMedicine(
      id: fields[0] as String,
      customerId: fields[1] as String,
      medicineName: fields[2] as String,
      notes: fields[3] as String? ?? '',
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerMedicine obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.medicineName)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.createdAt);
  }
}
