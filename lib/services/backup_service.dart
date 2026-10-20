import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/medicine.dart';
import '../models/medicine_batch.dart';
import '../models/shop_profile.dart';
import 'owner_data_service.dart';

/// Creates and restores a portable JSON backup of the signed-in owner's data.
///
/// This service returns/accepts JSON text so the UI can later save it to a
/// file or share it without requiring a file-picker dependency. Restore merges
/// by record ID and does not clear existing records.
class BackupService {
  BackupService({OwnerDataService? ownerDataService})
      : _ownerDataService = ownerDataService ?? OwnerDataService.instance;

  static const int _backupVersion = 1;
  final OwnerDataService _ownerDataService;

  Future<String> createBackupJson() async {
    final ownerId = _ownerDataService.ownerId;
    final medicines = await _openBox<Medicine>(_ownerDataService.medicinesBoxName);
    final batches = await _openBox<MedicineBatch>(_ownerDataService.batchesBoxName);
    final profiles = await _openBox<ShopProfile>(_ownerDataService.shopProfileBoxName);

    final profile = profiles.isEmpty ? null : profiles.getAt(0);

    final backup = <String, dynamic>{
      'format': 'medilink_backup',
      'version': _backupVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'ownerId': ownerId,
      'data': {
        'medicines': medicines.values.map(_medicineToJson).toList(),
        'batches': batches.values.map(_batchToJson).toList(),
        'shopProfile': profile == null ? null : _profileToJson(profile),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  /// Restores records into the currently authenticated owner's boxes.
  /// Existing matching IDs are replaced; unrelated records are preserved.
  /// By default, a backup created for another owner is rejected.
  Future<BackupRestoreResult> restoreBackupJson(
      String jsonText, {
        bool allowDifferentOwner = false,
      }) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } on FormatException {
      throw const FormatException('The selected backup is not valid JSON.');
    }

    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'medilink_backup' ||
        decoded['version'] != _backupVersion ||
        decoded['data'] is! Map<String, dynamic>) {
      throw const FormatException('Unsupported or invalid MediLink backup format.');
    }

    final ownerId = _ownerDataService.ownerId;
    final backupOwnerId = decoded['ownerId'];
    if (!allowDifferentOwner && backupOwnerId != ownerId) {
      throw StateError(
        'This backup belongs to a different owner. Restore was blocked for safety.',
      );
    }

    final data = decoded['data'] as Map<String, dynamic>;
    final medicineJson = _requireList(data, 'medicines');
    final batchJson = _requireList(data, 'batches');

    final parsedMedicines = medicineJson.map(_medicineFromJson).toList();
    final parsedBatches = batchJson.map(_batchFromJson).toList();
    final rawProfile = data['shopProfile'];
    final parsedProfile = rawProfile == null
        ? null
        : _profileFromJson(_requireMap(rawProfile, 'shopProfile'));

    // Parse/validate the entire backup before making any changes.
    final medicines = await _openBox<Medicine>(_ownerDataService.medicinesBoxName);
    final batches = await _openBox<MedicineBatch>(_ownerDataService.batchesBoxName);
    final profiles = await _openBox<ShopProfile>(_ownerDataService.shopProfileBoxName);

    await medicines.putAll({for (final item in parsedMedicines) item.id: item});
    await batches.putAll({for (final item in parsedBatches) item.id: item});
    if (parsedProfile != null) {
      // Profile is a singleton box. Replace its current contents only after
      // the backup has been fully validated.
      await profiles.clear();
      await profiles.add(parsedProfile);
    }

    return BackupRestoreResult(
      medicinesRestored: parsedMedicines.length,
      batchesRestored: parsedBatches.length,
      shopProfileRestored: parsedProfile != null,
    );
  }

  Future<Box<T>> _openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    return Hive.openBox<T>(name);
  }

  static Map<String, dynamic> _medicineToJson(Medicine item) => {
    'id': item.id,
    'name': item.name,
    'genericName': item.genericName,
    'manufacturer': item.manufacturer,
    'category': item.category,
    'unit': item.unit,
    'sellingPrice': item.sellingPrice,
    'description': item.description,
    'minimumStock': item.minimumStock,
  };

  static Medicine _medicineFromJson(dynamic value) {
    final map = _requireMap(value, 'medicine');
    return Medicine(
      id: _requiredString(map, 'id'),
      name: _requiredString(map, 'name'),
      genericName: _optionalString(map, 'genericName'),
      manufacturer: _optionalString(map, 'manufacturer'),
      category: _optionalString(map, 'category'),
      unit: _optionalString(map, 'unit'),
      sellingPrice: _number(map, 'sellingPrice'),
      description: _optionalString(map, 'description'),
      minimumStock: _integer(map, 'minimumStock', fallback: 0),
    );
  }

  static Map<String, dynamic> _batchToJson(MedicineBatch item) => {
    'id': item.id,
    'medicineId': item.medicineId,
    'batchNumber': item.batchNumber,
    'quantity': item.quantity,
    'expiryDate': item.expiryDate.toIso8601String(),
    'purchasePrice': item.purchasePrice,
  };

  static MedicineBatch _batchFromJson(dynamic value) {
    final map = _requireMap(value, 'batch');
    final expiry = DateTime.tryParse(_requiredString(map, 'expiryDate'));
    if (expiry == null) throw const FormatException('A batch has an invalid expiryDate.');
    return MedicineBatch(
      id: _requiredString(map, 'id'),
      medicineId: _requiredString(map, 'medicineId'),
      batchNumber: _requiredString(map, 'batchNumber'),
      quantity: _integer(map, 'quantity'),
      expiryDate: expiry,
      purchasePrice: _number(map, 'purchasePrice'),
    );
  }

  static Map<String, dynamic> _profileToJson(ShopProfile item) => {
    'shopName': item.shopName,
    'ownerName': item.ownerName,
    'phone': item.phone,
    'email': item.email,
    'address': item.address,
    'openingTime': item.openingTime,
    'closingTime': item.closingTime,
  };

  static ShopProfile _profileFromJson(Map<String, dynamic> map) => ShopProfile(
    shopName: _optionalString(map, 'shopName'),
    ownerName: _optionalString(map, 'ownerName'),
    phone: _optionalString(map, 'phone'),
    email: _optionalString(map, 'email'),
    address: _optionalString(map, 'address'),
    openingTime: _optionalString(map, 'openingTime'),
    closingTime: _optionalString(map, 'closingTime'),
  );

  static List<dynamic> _requireList(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! List) throw FormatException('Backup field "$key" must be a list.');
    return value;
  }

  static Map<String, dynamic> _requireMap(dynamic value, String field) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, value) => MapEntry(key.toString(), value));
    throw FormatException('Backup field "$field" must be an object.');
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Backup field "$key" is missing or invalid.');
  }

  static String _optionalString(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value == null ? '' : value.toString();
  }

  static double _number(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) return value.toDouble();
    throw FormatException('Backup field "$key" must be numeric.');
  }

  static int _integer(
      Map<String, dynamic> map,
      String key, {
        int? fallback,
      }) {
    final value = map[key];
    if (value is int) return value;
    if (value is num && value == value.roundToDouble()) return value.toInt();
    if (fallback != null && value == null) return fallback;
    throw FormatException('Backup field "$key" must be an integer.');
  }
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.medicinesRestored,
    required this.batchesRestored,
    required this.shopProfileRestored,
  });

  final int medicinesRestored;
  final int batchesRestored;
  final bool shopProfileRestored;

  int get totalRecordsRestored =>
      medicinesRestored + batchesRestored + (shopProfileRestored ? 1 : 0);
}
