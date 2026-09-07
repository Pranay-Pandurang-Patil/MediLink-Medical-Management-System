import 'package:hive/hive.dart';

import 'package:medilink/models/medicine.dart';

class MedicineService {
  static const String boxName = 'medicines';

  Future<void> openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<Medicine>(boxName);
    }
  }

  Box<Medicine> get box {
    return Hive.box<Medicine>(boxName);
  }
}