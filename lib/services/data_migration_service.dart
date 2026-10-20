import 'package:hive/hive.dart';

import '../models/medicine.dart';
import '../models/medicine_batch.dart';
import '../models/shop_profile.dart';
import 'owner_data_service.dart';

/// Safely copies the old shared MediLink Hive data into one owner's boxes.
///
/// Migration is opt-in: callers must pass [confirmLegacyOwnership] as true
/// only after confirming that the legacy data belongs to the signed-in owner.
/// Legacy boxes are never deleted or modified. A completion marker prevents
/// repeated migrations for the same owner.
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
        'Migration cancelled. Confirm that the existing local data belongs to this owner first.',
      );
    }

    final ownerId = _ownerDataService.ownerId;
    final markerKey = 'legacy_v1_$ownerId';
    final markers = await _openMarkerBox();

    if (markers.get(markerKey) == true) {
      return const MigrationResult(alreadyMigrated: true);
    }

    final sourceMedicines = await _openIfExists<Medicine>(legacyMedicinesBoxName);
    final sourceBatches = await _openIfExists<MedicineBatch>(legacyBatchesBoxName);
    final sourceProfiles = await _openIfExists<ShopProfile>(legacyShopProfileBoxName);

    final targetMedicines = await Hive.openBox<Medicine>(
      _ownerDataService.medicinesBoxName,
    );
    final targetBatches = await Hive.openBox<MedicineBatch>(
      _ownerDataService.batchesBoxName,
    );
    final targetProfiles = await Hive.openBox<ShopProfile>(
      _ownerDataService.shopProfileBoxName,
    );

    // Do not overwrite owner-specific data. A non-empty target means the
    // owner has already started using the new storage; stop for manual review.
    if (targetMedicines.isNotEmpty ||
        targetBatches.isNotEmpty ||
        targetProfiles.isNotEmpty) {
      throw StateError(
        'Owner-specific storage is not empty. Migration was stopped to avoid overwriting data.',
      );
    }

    final medicineEntries = sourceMedicines?.toMap() ?? <dynamic, Medicine>{};
    final batchEntries = sourceBatches?.toMap() ?? <dynamic, MedicineBatch>{};
    final profileEntries = sourceProfiles?.toMap() ?? <dynamic, ShopProfile>{};

    try {
      if (medicineEntries.isNotEmpty) {
        await targetMedicines.putAll(medicineEntries);
      }
      if (batchEntries.isNotEmpty) {
        await targetBatches.putAll(batchEntries);
      }
      if (profileEntries.isNotEmpty) {
        await targetProfiles.putAll(profileEntries);
      }

      // Verify copied key/value counts before marking the migration complete.
      if (targetMedicines.length != medicineEntries.length ||
          targetBatches.length != batchEntries.length ||
          targetProfiles.length != profileEntries.length) {
        throw StateError('Migration verification failed. Completion was not recorded.');
      }

      await markers.put(markerKey, true);
      return MigrationResult(
        medicinesCopied: medicineEntries.length,
        batchesCopied: batchEntries.length,
        profilesCopied: profileEntries.length,
      );
    } catch (_) {
      // The legacy boxes remain intact. Remove partially copied target data
      // only if those target boxes were empty when migration began.
      await targetMedicines.clear();
      await targetBatches.clear();
      await targetProfiles.clear();
      rethrow;
    }
  }

  Future<Box<dynamic>> _openMarkerBox() async {
    if (Hive.isBoxOpen(_migrationBoxName)) {
      return Hive.box<dynamic>(_migrationBoxName);
    }
    return Hive.openBox<dynamic>(_migrationBoxName);
  }

  Future<Box<T>?> _openIfExists<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    if (!await _boxExists(name)) {
      return null;
    }
    return Hive.openBox<T>(name);
  }

  Future<bool> _boxExists(String name) async {
    // Hive.boxExists is available in Hive 2.x and checks the local storage.
    return Hive.boxExists(name);
  }
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
