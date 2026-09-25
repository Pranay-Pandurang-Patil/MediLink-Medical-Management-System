// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shop_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShopProfileAdapter extends TypeAdapter<ShopProfile> {
  @override
  final int typeId = 2;

  @override
  ShopProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopProfile(
      shopName: fields[0] as String,
      ownerName: fields[1] as String,
      phone: fields[2] as String,
      email: fields[3] as String,
      address: fields[4] as String,
      openingTime: fields[5] as String,
      closingTime: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ShopProfile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.shopName)
      ..writeByte(1)
      ..write(obj.ownerName)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.openingTime)
      ..writeByte(6)
      ..write(obj.closingTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
