import 'package:hive/hive.dart';

import '../models/medicine_batch.dart';
import 'owner_data_service.dart';

/// Provides batch-inventory operations in the authenticated owner's Hive box.
///
/// The legacy shared `medicine_batches` box is left untouched. Migrate legacy
/// records explicitly through DataMigrationService after confirming ownership.
class BatchService {
  BatchService({OwnerDataService? ownerDataService})
      : _ownerDataService = ownerDataService ?? OwnerDataService.instance;

  /// Name of the legacy box, retained for migration and compatibility.
  static const String boxName = 'medicine_batches';

  final OwnerDataService _ownerDataService;
  String get ownerBoxName => _ownerDataService.batchesBoxName;

  Future<void> openBox() async {
    final name = ownerBoxName;
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<MedicineBatch>(name);
    }
  }

  Box<MedicineBatch> get box {
    final name = ownerBoxName;
    if (!Hive.isBoxOpen(name)) {
      throw StateError(
        'Batch storage is not open. Call and await BatchService.openBox() first.',
      );
    }
    return Hive.box<MedicineBatch>(name);
  }

  Future<void> addBatch(MedicineBatch batch) async {
    await box.put(batch.id, batch);
  }

  Future<void> updateBatch(MedicineBatch batch) async {
    if (!box.containsKey(batch.id)) {
      throw StateError('Cannot update a batch that does not exist.');
    }
    await box.put(batch.id, batch);
  }

  Future<void> deleteBatch(String batchId) async {
    await box.delete(batchId);
  }

  Future<void> updateQuantity(String batchId, int newQuantity) async {
    final batch = box.get(batchId);
    if (batch == null) return;

    await box.put(
      batchId,
      batch.copyWith(quantity: newQuantity < 0 ? 0 : newQuantity),
    );
  }

  Future<void> increaseQuantity(String batchId) async {
    final batch = box.get(batchId);
    if (batch == null) return;
    await updateQuantity(batchId, batch.quantity + 1);
  }

  Future<void> decreaseQuantity(String batchId) async {
    final batch = box.get(batchId);
    if (batch == null || batch.quantity <= 0) return;
    await updateQuantity(batchId, batch.quantity - 1);
  }

  MedicineBatch? getBatchById(String batchId) => box.get(batchId);

  List<MedicineBatch> getAllBatches() => box.values.toList(growable: false);

  List<MedicineBatch> getBatchesForMedicine(String medicineId) {
    return box.values
        .where((batch) => batch.medicineId == medicineId)
        .toList(growable: false);
  }

  int getNextBatchNumber(String medicineId) {
    final batches = getBatchesForMedicine(medicineId);
    if (batches.isEmpty) return 1;

    var highestNumber = 0;
    for (final batch in batches) {
      final number = int.tryParse(batch.batchNumber);
      if (number != null && number > highestNumber) highestNumber = number;
    }
    return highestNumber + 1;
  }
}
