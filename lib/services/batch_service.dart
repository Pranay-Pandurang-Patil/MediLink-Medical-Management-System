import 'package:hive/hive.dart';

import 'package:medilink/models/medicine_batch.dart';

class BatchService {
  static const String boxName = 'medicine_batches';

  Future<void> openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<MedicineBatch>(boxName);
    }
  }

  Box<MedicineBatch> get box {
    return Hive.box<MedicineBatch>(boxName);
  }

  Future<void> addBatch(MedicineBatch batch) async {
    await box.put(batch.id, batch);
  }

  Future<void> deleteBatch(String batchId) async {
    await box.delete(batchId);
  }

  Future<void> updateQuantity(
      String batchId,
      int newQuantity,
      ) async {
    final batch = box.get(batchId);

    if (batch == null) {
      return;
    }

    final safeQuantity = newQuantity < 0 ? 0 : newQuantity;

    final updatedBatch = batch.copyWith(
      quantity: safeQuantity,
    );

    await box.put(
      batchId,
      updatedBatch,
    );
  }

  Future<void> increaseQuantity(String batchId) async {
    final batch = box.get(batchId);

    if (batch == null) {
      return;
    }

    await updateQuantity(
      batchId,
      batch.quantity + 1,
    );
  }

  Future<void> decreaseQuantity(String batchId) async {
    final batch = box.get(batchId);

    if (batch == null || batch.quantity <= 0) {
      return;
    }

    await updateQuantity(
      batchId,
      batch.quantity - 1,
    );
  }

  List<MedicineBatch> getBatchesForMedicine(String medicineId) {
    return box.values
        .where((batch) => batch.medicineId == medicineId)
        .toList();
  }

  int getNextBatchNumber(String medicineId) {
    final batches = getBatchesForMedicine(medicineId);

    if (batches.isEmpty) {
      return 1;
    }

    int highestNumber = 0;

    for (final batch in batches) {
      final number = int.tryParse(batch.batchNumber);

      if (number != null && number > highestNumber) {
        highestNumber = number;
      }
    }

    return highestNumber + 1;
  }
}