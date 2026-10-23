import 'package:hive/hive.dart';

import '../models/medicine.dart';
import '../models/medicine_batch.dart';
import '../models/shop_profile.dart';
import 'owner_data_service.dart';

/// Copies legacy shared MediLink records into the currently authenticated
/// owner's boxes. Legacy boxes are never changed or deleted.
///
/// Migration is opt-in and resumable. If an earlier attempt stopped part-way,
/// a later attempt can continue only when all records already in the target
/// boxes match the corresponding legacy records. Unrelated/conflicting target
/// records cause the migration to stop without clearing or overwriting data.
class DataMigrationService {
  DataMigrationService({OwnerDataService? ownerDataService})
      : _ownerDataService = ownerDataService ?? OwnerDataService.instance;

  static const String legacyMedicinesBoxName = 'medicines';
  static const String legacyBatchesBoxName = 'medicine_batches';
  static const String legacyShopProfileBoxName = 'shop_profile';
  static const String _migrationBoxName = 'medilink_data_migrations';

  final OwnerDataService _ownerDataService;

  Future<MigrationResult> migrateLegacyDataToCurrentOwner({
    required bool confirmLegacyOwnership,
  }) async {
    if (!confirmLegacyOwnership) {
      throw StateError(
        'Migration cancelled. Confirm that the legacy data belongs to this owner first.',
      );
    }

    // Resolve the owner before opening any target storage.
    final ownerId = _ownerDataService.ownerId;
    final markerKey = 'legacy_v1_$ownerId';
    final markers = await _openMarkerBox();

    if (markers.get(markerKey) == true) {
      return const MigrationResult(alreadyMigrated: true);
    }

    final sourceMedicines =
    await _openIfExists<Medicine>(legacyMedicinesBoxName);
    final sourceBatches =
    await _openIfExists<MedicineBatch>(legacyBatchesBoxName);
    final sourceProfiles =
    await _openIfExists<ShopProfile>(legacyShopProfileBoxName);

    final medicineEntries =
        sourceMedicines?.toMap() ?? <dynamic, Medicine>{};
    final batchEntries =
        sourceBatches?.toMap() ?? <dynamic, MedicineBatch>{};
    final profileEntries =
        sourceProfiles?.toMap() ?? <dynamic, ShopProfile>{};

    final targetMedicines = await _openTarget<Medicine>(
      _ownerDataService.medicinesBoxName,
    );
    final targetBatches = await _openTarget<MedicineBatch>(
      _ownerDataService.batchesBoxName,
    );
    final targetProfiles = await _openTarget<ShopProfile>(
      _ownerDataService.shopProfileBoxName,
    );

    // Preflight all existing destination records before writing anything.
    // This allows safe resumption after an interrupted earlier attempt.
    _validateExistingRecords<Medicine>(
      source: medicineEntries,
      target: targetMedicines,
      sameRecord: _sameMedicine,
      label: 'medicine',
    );
    _validateExistingRecords<MedicineBatch>(
      source: batchEntries,
      target: targetBatches,
      sameRecord: _sameBatch,
      label: 'batch',
    );
    _validateExistingRecords<ShopProfile>(
      source: profileEntries,
      target: targetProfiles,
      sameRecord: _sameProfile,
      label: 'shop profile',
    );

    // Copy only missing keys. Do not clear destinations on failure: that could
    // erase unrelated records added by the owner or another app operation.
    for (final entry in medicineEntries.entries) {
      if (!targetMedicines.containsKey(entry.key)) {
        await targetMedicines.put(entry.key, entry.value);
      }
    }
    for (final entry in batchEntries.entries) {
      if (!targetBatches.containsKey(entry.key)) {
        await targetBatches.put(entry.key, entry.value);
      }
    }
    for (final entry in profileEntries.entries) {
      if (!targetProfiles.containsKey(entry.key)) {
        await targetProfiles.put(entry.key, entry.value);
      }
    }

    // Verify every legacy key exists in the destination and has matching
    // field values. The completion marker is written only after verification.
    _verifyCopiedRecords<Medicine>(
      source: medicineEntries,
      target: targetMedicines,
      sameRecord: _sameMedicine,
      label: 'medicine',
    );
    _verifyCopiedRecords<MedicineBatch>(
      source: batchEntries,
      target: targetBatches,
      sameRecord: _sameBatch,
      label: 'batch',
    );
    _verifyCopiedRecords<ShopProfile>(
      source: profileEntries,
      target: targetProfiles,
      sameRecord: _sameProfile,
      label: 'shop profile',
    );

    await markers.put(markerKey, true);
    return MigrationResult(
      medicinesCopied: medicineEntries.length,
      batchesCopied: batchEntries.length,
      profilesCopied: profileEntries.length,
    );
  }

  Future<Box<dynamic>> _openMarkerBox() async {
    if (Hive.isBoxOpen(_migrationBoxName)) {
      return Hive.box<dynamic>(_migrationBoxName);
    }
    return Hive.openBox<dynamic>(_migrationBoxName);
  }

  Future<Box<T>> _openTarget<T>(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    return Hive.openBox<T>(name);
  }

  Future<Box<T>?> _openIfExists<T>(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    if (!await Hive.boxExists(name)) return null;
    return Hive.openBox<T>(name);
  }

  void _validateExistingRecords<T>({
    required Map<dynamic, T> source,
    required Box<T> target,
    required bool Function(T, T) sameRecord,
    required String label,
  }) {
    for (final key in target.keys) {
      if (!source.containsKey(key)) {
        throw StateError(
          'Migration stopped: destination contains an unrelated $label record. No data was changed.',
        );
      }
      final sourceRecord = source[key];
      final targetRecord = target.get(key);
      if (sourceRecord == null ||
          targetRecord == null ||
          !sameRecord(sourceRecord, targetRecord)) {
        throw StateError(
          'Migration stopped: destination $label record conflicts with legacy data. No data was changed.',
        );
      }
    }
  }

  void _verifyCopiedRecords<T>({
    required Map<dynamic, T> source,
    required Box<T> target,
    required bool Function(T, T) sameRecord,
    required String label,
  }) {
    for (final entry in source.entries) {
      final copied = target.get(entry.key);
      if (copied == null || !sameRecord(entry.value, copied)) {
        throw StateError(
          'Migration verification failed for a $label record. Legacy data remains intact; run migration again to resume.',
        );
      }
    }
  }

  bool _sameMedicine(Medicine a, Medicine b) =>
      a.id == b.id &&
          a.name == b.name &&
          a.genericName == b.genericName &&
          a.manufacturer == b.manufacturer &&
          a.category == b.category &&
          a.unit == b.unit &&
          a.sellingPrice == b.sellingPrice &&
          a.description == b.description &&
          a.minimumStock == b.minimumStock;

  bool _sameBatch(MedicineBatch a, MedicineBatch b) =>
      a.id == b.id &&
          a.medicineId == b.medicineId &&
          a.batchNumber == b.batchNumber &&
          a.quantity == b.quantity &&
          a.expiryDate == b.expiryDate &&
          a.purchasePrice == b.purchasePrice;

  bool _sameProfile(ShopProfile a, ShopProfile b) =>
      a.shopName == b.shopName &&
          a.ownerName == b.ownerName &&
          a.phone == b.phone &&
          a.email == b.email &&
          a.address == b.address &&
          a.openingTime == b.openingTime &&
          a.closingTime == b.closingTime;
}

class MigrationResult {
  const MigrationResult({
    this.medicinesCopied = 0,
    this.batchesCopied = 0,
    this.profilesCopied = 0,
    this.alreadyMigrated = false,
  });

  final int medicinesCopied;
  final int batchesCopied;
  final int profilesCopied;
  final bool alreadyMigrated;

  int get totalRecordsCopied =>
      medicinesCopied + batchesCopied + profilesCopied;
}
