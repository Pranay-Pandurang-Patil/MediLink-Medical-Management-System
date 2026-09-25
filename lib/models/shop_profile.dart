import 'package:hive/hive.dart';

part 'shop_profile.g.dart';

@HiveType(typeId: 2)
class ShopProfile {
  @HiveField(0)
  final String shopName;

  @HiveField(1)
  final String ownerName;

  @HiveField(2)
  final String phone;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String address;

  @HiveField(5)
  final String openingTime;

  @HiveField(6)
  final String closingTime;

  ShopProfile({
    this.shopName = '',
    this.ownerName = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.openingTime = '',
    this.closingTime = '',
  });
}