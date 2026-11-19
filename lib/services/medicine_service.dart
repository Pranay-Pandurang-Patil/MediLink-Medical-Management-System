import 'package:hive/hive.dart';

import '../models/medicine.dart';
import 'owner_data_service.dart';

/// Provides access to the authenticated owner's medicine inventory.
class MedicineService {
  MedicineService({OwnerDataService? ownerDataService})
      : _ownerDataService =
      ownerDataService ?? OwnerDataService.instance;

  /// Legacy box name retained for migration compatibility.
  static const String boxName = 'medicines';

  final OwnerDataService _ownerDataService;

  String get ownerBoxName =>
      _ownerDataService.medicinesBoxName;

  Future<void> openBox() async {
    final name = ownerBoxName;

    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<Medicine>(name);
    }
  }

  Box<Medicine> get box {
    final name = ownerBoxName;

    if (!Hive.isBoxOpen(name)) {
      throw StateError(
        'Medicine storage is not open. '
            'Call and await MedicineService.openBox() first.',
      );
    }

    return Hive.box<Medicine>(name);
  }

  // Validate medicine data before saving.

  void _validateMedicine(Medicine medicine) {
    if (medicine.id.trim().isEmpty) {
      throw ArgumentError('Medicine ID cannot be empty.');
    }

    if (medicine.name.trim().isEmpty) {
      throw ArgumentError('Medicine name cannot be empty.');
    }

    if (!medicine.sellingPrice.isFinite ||
        medicine.sellingPrice < 0) {
      throw ArgumentError(
        'Enter a valid medicine selling price.',
      );
    }

    if (medicine.minimumStock < 0) {
      throw ArgumentError(
        'Minimum stock cannot be negative.',
      );
    }
  }

  // Add medicine.

  Future<void> addMedicine(Medicine medicine) async {
    _validateMedicine(medicine);

    if (box.containsKey(medicine.id)) {
      throw StateError(
        'A medicine with this ID already exists.',
      );
    }

    await box.put(medicine.id, medicine);
    await box.flush();
  }

  // Update existing medicine.

  Future<void> updateMedicine(Medicine medicine) async {
    _validateMedicine(medicine);

    if (!box.containsKey(medicine.id)) {
      throw StateError(
        'Cannot update a medicine that does not exist.',
      );
    }

    await box.put(medicine.id, medicine);
    await box.flush();
  }

  // Delete medicine.

  Future<void> deleteMedicine(String medicineId) async {
    if (!box.containsKey(medicineId)) {
      throw StateError(
        'Medicine record not found.',
      );
    }

    await box.delete(medicineId);
    await box.flush();
  }

  // Get medicine by ID.

  Medicine? getMedicineById(String medicineId) {
    return box.get(medicineId);
  }

  // Get all medicines.

  List<Medicine> getAllMedicines() {
    return box.values.toList(growable: false);
  }

  // Search medicines.

  List<Medicine> searchMedicines(String query) {
    final normalizedQuery =
    query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return getAllMedicines();
    }

    return box.values.where((medicine) {
      return medicine.name
          .toLowerCase()
          .contains(normalizedQuery) ||
          medicine.genericName
              .toLowerCase()
              .contains(normalizedQuery) ||
          medicine.manufacturer
              .toLowerCase()
              .contains(normalizedQuery) ||
          medicine.category
              .toLowerCase()
              .contains(normalizedQuery);
    }).toList(growable: false);
  }
}