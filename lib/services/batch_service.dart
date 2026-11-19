import 'package:hive/hive.dart';

import '../models/medicine.dart';
import '../models/medicine_batch.dart';
import 'owner_data_service.dart';

/// Provides batch inventory operations for the authenticated owner.
class BatchService {
  BatchService({OwnerDataService? ownerDataService})
      : _ownerDataService =
      ownerDataService ?? OwnerDataService.instance;

  /// Legacy box name retained for migration compatibility.
  static const String boxName = 'medicine_batches';

  final OwnerDataService _ownerDataService;

  String get ownerBoxName =>
      _ownerDataService.batchesBoxName;

  String get medicineBoxName =>
      _ownerDataService.medicinesBoxName;

  // Open batch storage.

  Future<void> openBox() async {
    final name = ownerBoxName;

    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<MedicineBatch>(name);
    }
  }

  // Access batch storage.

  Box<MedicineBatch> get box {
    final name = ownerBoxName;

    if (!Hive.isBoxOpen(name)) {
      throw StateError(
        'Batch storage is not open. '
            'Call and await BatchService.openBox() first.',
      );
    }

    return Hive.box<MedicineBatch>(name);
  }

  // Verify that the medicine belongs to the current owner's inventory.

  Future<void> _validateMedicineExists(
      String medicineId,
      ) async {
    if (medicineId.trim().isEmpty) {
      throw ArgumentError(
        'Medicine ID cannot be empty.',
      );
    }

    if (!Hive.isBoxOpen(medicineBoxName)) {
      await Hive.openBox<Medicine>(medicineBoxName);
    }

    final medicineBox =
    Hive.box<Medicine>(medicineBoxName);

    if (!medicineBox.containsKey(medicineId)) {
      throw StateError(
        'The associated medicine does not exist.',
      );
    }
  }

  // Validate batch information.

  void _validateBatch(MedicineBatch batch) {
    if (batch.id.trim().isEmpty) {
      throw ArgumentError(
        'Batch ID cannot be empty.',
      );
    }

    if (batch.batchNumber.trim().isEmpty) {
      throw ArgumentError(
        'Batch number cannot be empty.',
      );
    }

    if (batch.quantity < 0) {
      throw ArgumentError(
        'Batch quantity cannot be negative.',
      );
    }

    if (!batch.purchasePrice.isFinite ||
        batch.purchasePrice < 0) {
      throw ArgumentError(
        'Enter a valid batch purchase price.',
      );
    }
  }

  // Check duplicate batch numbers for the same medicine.

  void _checkDuplicateBatchNumber(
      MedicineBatch batch,
      ) {
    final normalizedNumber =
    batch.batchNumber.trim().toLowerCase();

    final duplicate = box.values.any((existing) {
      return existing.medicineId == batch.medicineId &&
          existing.id != batch.id &&
          existing.batchNumber.trim().toLowerCase() ==
              normalizedNumber;
    });

    if (duplicate) {
      throw StateError(
        'This batch number already exists for this medicine.',
      );
    }
  }

  // Add batch.

  Future<void> addBatch(MedicineBatch batch) async {
    _validateBatch(batch);

    await _validateMedicineExists(
      batch.medicineId,
    );

    if (box.containsKey(batch.id)) {
      throw StateError(
        'A batch with this ID already exists.',
      );
    }

    _checkDuplicateBatchNumber(batch);

    await box.put(batch.id, batch);
    await box.flush();
  }

  // Update batch.

  Future<void> updateBatch(MedicineBatch batch) async {
    _validateBatch(batch);

    await _validateMedicineExists(
      batch.medicineId,
    );

    final existing = box.get(batch.id);

    if (existing == null) {
      throw StateError(
        'Cannot update a batch that does not exist.',
      );
    }

    _checkDuplicateBatchNumber(batch);

    await box.put(batch.id, batch);
    await box.flush();
  }

  // Delete batch.

  Future<void> deleteBatch(String batchId) async {
    if (!box.containsKey(batchId)) {
      throw StateError(
        'Batch record not found.',
      );
    }

    await box.delete(batchId);
    await box.flush();
  }

  // Update stock quantity.

  Future<void> updateQuantity(
      String batchId,
      int newQuantity,
      ) async {
    if (newQuantity < 0) {
      throw ArgumentError(
        'Stock quantity cannot be negative.',
      );
    }

    final batch = box.get(batchId);

    if (batch == null) {
      throw StateError(
        'Batch record not found.',
      );
    }

    await box.put(
      batchId,
      batch.copyWith(
        quantity: newQuantity,
      ),
    );

    await box.flush();
  }

  // Increase stock by one unit.

  Future<void> increaseQuantity(
      String batchId,
      ) async {
    final batch = box.get(batchId);

    if (batch == null) {
      throw StateError(
        'Batch record not found.',
      );
    }

    await updateQuantity(
      batchId,
      batch.quantity + 1,
    );
  }

  // Decrease stock by one unit.

  Future<void> decreaseQuantity(
      String batchId,
      ) async {
    final batch = box.get(batchId);

    if (batch == null) {
      throw StateError(
        'Batch record not found.',
      );
    }

    if (batch.quantity <= 0) {
      throw StateError(
        'Stock quantity cannot go below zero.',
      );
    }

    await updateQuantity(
      batchId,
      batch.quantity - 1,
    );
  }

  // Get batch by ID.

  MedicineBatch? getBatchById(String batchId) {
    return box.get(batchId);
  }

  // Get all batches.

  List<MedicineBatch> getAllBatches() {
    return box.values.toList(growable: false);
  }

  // Get batches belonging to a medicine.

  List<MedicineBatch> getBatchesForMedicine(
      String medicineId,
      ) {
    return box.values
        .where(
          (batch) => batch.medicineId == medicineId,
    )
        .toList(growable: false);
  }

  // Calculate total stock for a medicine.

  int getTotalStock(String medicineId) {
    return getBatchesForMedicine(medicineId).fold<int>(
      0,
          (total, batch) => total + batch.quantity,
    );
  }

  // Generate the next numeric batch number.

  int getNextBatchNumber(String medicineId) {
    final batches = getBatchesForMedicine(
      medicineId,
    );

    if (batches.isEmpty) {
      return 1;
    }

    var highestNumber = 0;

    for (final batch in batches) {
      final number = int.tryParse(
        batch.batchNumber,
      );

      if (number != null && number > highestNumber) {
        highestNumber = number;
      }
    }

    return highestNumber + 1;
  }
}