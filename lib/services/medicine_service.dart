import 'package:hive/hive.dart';

import '../models/medicine.dart';
import 'owner_data_service.dart';

/// Provides access to the authenticated owner's medicine inventory.
///
/// Each Firebase owner receives a separate Hive box. The legacy shared box
/// named `medicines` is intentionally not opened or modified here; use
/// DataMigrationService only after confirming that the legacy records belong
/// to the currently authenticated owner.
class MedicineService {
  MedicineService({OwnerDataService? ownerDataService})
      : _ownerDataService = ownerDataService ?? OwnerDataService.instance;

  /// Name of the legacy box, retained for migration and compatibility.
  static const String boxName = 'medicines';

  final OwnerDataService _ownerDataService;
  String get ownerBoxName => _ownerDataService.medicinesBoxName;

  Future<void> openBox() async {
    // Accessing ownerBoxName throws if no Firebase owner is signed in.
    final name = ownerBoxName;
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox<Medicine>(name);
    }
  }

  Box<Medicine> get box {
    final name = ownerBoxName;
    if (!Hive.isBoxOpen(name)) {
      throw StateError(
        'Medicine storage is not open. Call and await MedicineService.openBox() first.',
      );
    }
    return Hive.box<Medicine>(name);
  }

  Future<void> addMedicine(Medicine medicine) async {
    await box.put(medicine.id, medicine);
  }

  Future<void> updateMedicine(Medicine medicine) async {
    if (!box.containsKey(medicine.id)) {
      throw StateError('Cannot update a medicine that does not exist.');
    }
    await box.put(medicine.id, medicine);
  }

  Future<void> deleteMedicine(String medicineId) async {
    await box.delete(medicineId);
  }

  Medicine? getMedicineById(String medicineId) => box.get(medicineId);

  List<Medicine> getAllMedicines() => box.values.toList(growable: false);

  List<Medicine> searchMedicines(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return getAllMedicines();

    return box.values.where((medicine) {
      return medicine.name.toLowerCase().contains(normalizedQuery) ||
          medicine.genericName.toLowerCase().contains(normalizedQuery) ||
          medicine.manufacturer.toLowerCase().contains(normalizedQuery) ||
          medicine.category.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);
  }
}
