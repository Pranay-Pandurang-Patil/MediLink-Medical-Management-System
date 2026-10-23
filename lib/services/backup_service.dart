import 'dart:convert';

import 'package:hive/hive.dart';

import '../models/customer_medicine.dart';
import '../models/customer_payment.dart';
import '../models/daily_note.dart';
import '../models/medicine.dart';
import '../models/medicine_batch.dart';
import '../models/regular_customer.dart';
import '../models/shop_profile.dart';
import 'owner_data_service.dart';

/// Portable JSON backup for all owner-specific MediLink data.
///
/// Restore validates and parses every record before writing anything. Records
/// are merged by ID; unrelated records are retained. The shop profile is a
/// singleton and is replaced only when the backup contains one.
class BackupService {
  BackupService({OwnerDataService? ownerDataService})
      : _ownerDataService = ownerDataService ?? OwnerDataService.instance;

  static const int _backupVersion = 2;
  final OwnerDataService _ownerDataService;

  Future<String> createBackupJson() async {
    final ownerId = _ownerDataService.ownerId;
    final medicines = await _openBox<Medicine>(_ownerDataService.medicinesBoxName);
    final batches = await _openBox<MedicineBatch>(_ownerDataService.batchesBoxName);
    final profiles = await _openBox<ShopProfile>(_ownerDataService.shopProfileBoxName);
    final notes = await _openBox<DailyNote>(_ownerDataService.notesBoxName);
    final customers = await _openBox<RegularCustomer>(_ownerDataService.customersBoxName);
    final customerMedicines = await _openBox<CustomerMedicine>(_ownerDataService.customerMedicinesBoxName);
    final payments = await _openBox<CustomerPayment>(_ownerDataService.customerPaymentsBoxName);
    final profile = profiles.isEmpty ? null : profiles.getAt(0);

    return const JsonEncoder.withIndent('  ').convert({
      'format': 'medilink_backup',
      'version': _backupVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'ownerId': ownerId,
      'data': {
        'medicines': medicines.values.map(_medicineToJson).toList(),
        'batches': batches.values.map(_batchToJson).toList(),
        'shopProfile': profile == null ? null : _profileToJson(profile),
        'dailyNotes': notes.values.map(_noteToJson).toList(),
        'customers': customers.values.map(_customerToJson).toList(),
        'customerMedicines': customerMedicines.values.map(_customerMedicineToJson).toList(),
        'customerPayments': payments.values.map(_paymentToJson).toList(),
      },
    });
  }

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
    if (!allowDifferentOwner && decoded['ownerId'] != ownerId) {
      throw StateError('This backup belongs to a different owner. Restore was blocked for safety.');
    }
    final data = decoded['data'] as Map<String, dynamic>;
    final parsedMedicines = _requireList(data, 'medicines').map(_medicineFromJson).toList();
    final parsedBatches = _requireList(data, 'batches').map(_batchFromJson).toList();
    final parsedNotes = _requireList(data, 'dailyNotes').map(_noteFromJson).toList();
    final parsedCustomers = _requireList(data, 'customers').map(_customerFromJson).toList();
    final parsedCustomerMedicines = _requireList(data, 'customerMedicines').map(_customerMedicineFromJson).toList();
    final parsedPayments = _requireList(data, 'customerPayments').map(_paymentFromJson).toList();
    final rawProfile = data['shopProfile'];
    final parsedProfile = rawProfile == null ? null : _profileFromJson(_requireMap(rawProfile, 'shopProfile'));

    // Reject duplicate IDs and broken relationships before touching local data.
    _ensureUniqueIds(parsedMedicines.map((x) => x.id), 'medicine');
    _ensureUniqueIds(parsedBatches.map((x) => x.id), 'batch');
    _ensureUniqueIds(parsedNotes.map((x) => x.id), 'daily note');
    _ensureUniqueIds(parsedCustomers.map((x) => x.id), 'customer');
    _ensureUniqueIds(parsedCustomerMedicines.map((x) => x.id), 'customer medicine');
    _ensureUniqueIds(parsedPayments.map((x) => x.id), 'customer payment');
    final medicineIds = parsedMedicines.map((x) => x.id).toSet();
    for (final batch in parsedBatches) {
      if (!medicineIds.contains(batch.medicineId)) {
        throw FormatException('Batch "${batch.id}" refers to a medicine missing from this backup.');
      }
      if (batch.quantity < 0 || batch.purchasePrice < 0) {
        throw FormatException('Batch "${batch.id}" contains a negative quantity or price.');
      }
    }
    final customerIds = parsedCustomers.map((x) => x.id).toSet();
    for (final item in parsedCustomerMedicines) {
      if (!customerIds.contains(item.customerId)) {
        throw FormatException('Frequent-medicine record "${item.id}" refers to a missing customer.');
      }
    }
    for (final payment in parsedPayments) {
      if (!customerIds.contains(payment.customerId)) {
        throw FormatException('Payment "${payment.id}" refers to a missing customer.');
      }
    }

    // Open all destinations only after every record has passed validation.
    final medicines = await _openBox<Medicine>(_ownerDataService.medicinesBoxName);
    final batches = await _openBox<MedicineBatch>(_ownerDataService.batchesBoxName);
    final profiles = await _openBox<ShopProfile>(_ownerDataService.shopProfileBoxName);
    final notes = await _openBox<DailyNote>(_ownerDataService.notesBoxName);
    final customers = await _openBox<RegularCustomer>(_ownerDataService.customersBoxName);
    final customerMedicines = await _openBox<CustomerMedicine>(_ownerDataService.customerMedicinesBoxName);
    final payments = await _openBox<CustomerPayment>(_ownerDataService.customerPaymentsBoxName);

    // Snapshot current owner data so a write failure can be rolled back.
    // Hive does not offer a multi-box transaction, so this is best-effort
    // recovery across boxes while retaining unrelated records on success.
    final oldMedicines = Map<dynamic, Medicine>.from(medicines.toMap());
    final oldBatches = Map<dynamic, MedicineBatch>.from(batches.toMap());
    final oldProfiles = Map<dynamic, ShopProfile>.from(profiles.toMap());
    final oldNotes = Map<dynamic, DailyNote>.from(notes.toMap());
    final oldCustomers = Map<dynamic, RegularCustomer>.from(customers.toMap());
    final oldCustomerMedicines = Map<dynamic, CustomerMedicine>.from(customerMedicines.toMap());
    final oldPayments = Map<dynamic, CustomerPayment>.from(payments.toMap());

    try {
      await medicines.putAll({for (final item in parsedMedicines) item.id: item});
      await batches.putAll({for (final item in parsedBatches) item.id: item});
      await notes.putAll({for (final item in parsedNotes) item.id: item});
      await customers.putAll({for (final item in parsedCustomers) item.id: item});
      await customerMedicines.putAll({for (final item in parsedCustomerMedicines) item.id: item});
      await payments.putAll({for (final item in parsedPayments) item.id: item});
      if (parsedProfile != null) {
        await profiles.clear();
        await profiles.add(parsedProfile);
      }
    } catch (error) {
      // Restore every box to its pre-restore contents if any write fails.
      await _replaceContents(medicines, oldMedicines);
      await _replaceContents(batches, oldBatches);
      await _replaceContents(profiles, oldProfiles);
      await _replaceContents(notes, oldNotes);
      await _replaceContents(customers, oldCustomers);
      await _replaceContents(customerMedicines, oldCustomerMedicines);
      await _replaceContents(payments, oldPayments);
      rethrow;
    }

    return BackupRestoreResult(
      medicinesRestored: parsedMedicines.length,
      batchesRestored: parsedBatches.length,
      shopProfileRestored: parsedProfile != null,
      notesRestored: parsedNotes.length,
      customersRestored: parsedCustomers.length,
      customerMedicinesRestored: parsedCustomerMedicines.length,
      paymentsRestored: parsedPayments.length,
    );
  }


  static void _ensureUniqueIds(Iterable<String> ids, String label) {
    final seen = <String>{};
    for (final id in ids) {
      if (id.trim().isEmpty || !seen.add(id)) {
        throw FormatException('Backup contains an empty or duplicate ID for a $label.');
      }
    }
  }

  Future<void> _replaceContents<T>(Box<T> box, Map<dynamic, T> snapshot) async {
    await box.clear();
    if (snapshot.isNotEmpty) await box.putAll(snapshot);
  }

  Future<Box<T>> _openBox<T>(String name) async =>
      Hive.isBoxOpen(name) ? Hive.box<T>(name) : Hive.openBox<T>(name);

  static Map<String, dynamic> _medicineToJson(Medicine x) => {
    'id': x.id, 'name': x.name, 'genericName': x.genericName,
    'manufacturer': x.manufacturer, 'category': x.category, 'unit': x.unit,
    'sellingPrice': x.sellingPrice, 'description': x.description,
    'minimumStock': x.minimumStock,
  };
  static Medicine _medicineFromJson(dynamic v) {
    final m = _requireMap(v, 'medicine');
    return Medicine(id: _requiredString(m, 'id'), name: _requiredString(m, 'name'),
        genericName: _string(m, 'genericName'), manufacturer: _string(m, 'manufacturer'),
        category: _string(m, 'category'), unit: _string(m, 'unit'),
        sellingPrice: _number(m, 'sellingPrice'), description: _string(m, 'description'),
        minimumStock: _integer(m, 'minimumStock', fallback: 0));
  }
  static Map<String, dynamic> _batchToJson(MedicineBatch x) => {
    'id': x.id, 'medicineId': x.medicineId, 'batchNumber': x.batchNumber,
    'quantity': x.quantity, 'expiryDate': x.expiryDate.toIso8601String(),
    'purchasePrice': x.purchasePrice,
  };
  static MedicineBatch _batchFromJson(dynamic v) {
    final m = _requireMap(v, 'batch');
    final date = DateTime.tryParse(_requiredString(m, 'expiryDate'));
    if (date == null) throw const FormatException('Invalid batch expiryDate.');
    return MedicineBatch(id: _requiredString(m, 'id'), medicineId: _requiredString(m, 'medicineId'),
        batchNumber: _requiredString(m, 'batchNumber'), quantity: _integer(m, 'quantity'),
        expiryDate: date, purchasePrice: _number(m, 'purchasePrice'));
  }
  static Map<String, dynamic> _profileToJson(ShopProfile x) => {
    'shopName': x.shopName, 'ownerName': x.ownerName, 'phone': x.phone,
    'email': x.email, 'address': x.address, 'openingTime': x.openingTime,
    'closingTime': x.closingTime,
  };
  static ShopProfile _profileFromJson(Map<String, dynamic> m) => ShopProfile(
      shopName: _string(m, 'shopName'), ownerName: _string(m, 'ownerName'),
      phone: _string(m, 'phone'), email: _string(m, 'email'), address: _string(m, 'address'),
      openingTime: _string(m, 'openingTime'), closingTime: _string(m, 'closingTime'));
  static Map<String, dynamic> _noteToJson(DailyNote x) => {
    'id': x.id, 'title': x.title, 'content': x.content,
    'createdAt': x.createdAt.toIso8601String(), 'updatedAt': x.updatedAt.toIso8601String(),
  };
  static DailyNote _noteFromJson(dynamic v) {
    final m = _requireMap(v, 'daily note');
    return DailyNote(id: _requiredString(m, 'id'), title: _string(m, 'title'), content: _string(m, 'content'),
        createdAt: _date(m, 'createdAt'), updatedAt: _date(m, 'updatedAt'));
  }
  static Map<String, dynamic> _customerToJson(RegularCustomer x) => {
    'id': x.id, 'name': x.name, 'phone': x.phone, 'notes': x.notes,
    'createdAt': x.createdAt.toIso8601String(), 'updatedAt': x.updatedAt.toIso8601String(),
  };
  static RegularCustomer _customerFromJson(dynamic v) {
    final m = _requireMap(v, 'customer');
    return RegularCustomer(id: _requiredString(m, 'id'), name: _requiredString(m, 'name'),
        phone: _string(m, 'phone'), notes: _string(m, 'notes'),
        createdAt: _date(m, 'createdAt'), updatedAt: _date(m, 'updatedAt'));
  }
  static Map<String, dynamic> _customerMedicineToJson(CustomerMedicine x) => {
    'id': x.id, 'customerId': x.customerId, 'medicineName': x.medicineName,
    'notes': x.notes, 'createdAt': x.createdAt.toIso8601String(),
  };
  static CustomerMedicine _customerMedicineFromJson(dynamic v) {
    final m = _requireMap(v, 'customer medicine');
    return CustomerMedicine(id: _requiredString(m, 'id'), customerId: _requiredString(m, 'customerId'),
        medicineName: _requiredString(m, 'medicineName'), notes: _string(m, 'notes'), createdAt: _date(m, 'createdAt'));
  }
  static Map<String, dynamic> _paymentToJson(CustomerPayment x) => {
    'id': x.id, 'customerId': x.customerId, 'description': x.description,
    'totalAmount': x.totalAmount, 'paidAmount': x.paidAmount,
    'createdAt': x.createdAt.toIso8601String(), 'notes': x.notes,
  };
  static CustomerPayment _paymentFromJson(dynamic v) {
    final m = _requireMap(v, 'customer payment');
    final total = _number(m, 'totalAmount');
    final paid = _number(m, 'paidAmount');
    if (total < 0 || paid < 0 || paid > total) throw const FormatException('Invalid payment amounts in backup.');
    return CustomerPayment(id: _requiredString(m, 'id'), customerId: _requiredString(m, 'customerId'),
        description: _requiredString(m, 'description'), totalAmount: total, paidAmount: paid,
        createdAt: _date(m, 'createdAt'), notes: _string(m, 'notes'));
  }

  static List<dynamic> _requireList(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is! List) throw FormatException('Backup field "$key" must be a list.');
    return v;
  }
  static Map<String, dynamic> _requireMap(dynamic v, String field) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, value) => MapEntry(k.toString(), value));
    throw FormatException('Backup field "$field" must be an object.');
  }
  static String _requiredString(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is String && v.trim().isNotEmpty) return v;
    throw FormatException('Backup field "$key" is missing or invalid.');
  }
  static String _string(Map<String, dynamic> m, String key) => m[key] == null ? '' : m[key].toString();
  static double _number(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is num && v.toDouble().isFinite) return v.toDouble();
    throw FormatException('Backup field "$key" must be a finite number.');
  }
  static int _integer(Map<String, dynamic> m, String key, {int? fallback}) {
    final v = m[key];
    if (v is int) return v;
    if (v is num && v == v.roundToDouble()) return v.toInt();
    if (fallback != null && v == null) return fallback;
    throw FormatException('Backup field "$key" must be an integer.');
  }
  static DateTime _date(Map<String, dynamic> m, String key) {
    final raw = _requiredString(m, key);
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) throw FormatException('Backup field "$key" is not a valid date.');
    return parsed;
  }
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.medicinesRestored,
    required this.batchesRestored,
    required this.shopProfileRestored,
    this.notesRestored = 0,
    this.customersRestored = 0,
    this.customerMedicinesRestored = 0,
    this.paymentsRestored = 0,
  });
  final int medicinesRestored;
  final int batchesRestored;
  final bool shopProfileRestored;
  final int notesRestored;
  final int customersRestored;
  final int customerMedicinesRestored;
  final int paymentsRestored;
  int get totalRecordsRestored => medicinesRestored + batchesRestored +
      (shopProfileRestored ? 1 : 0) + notesRestored + customersRestored +
      customerMedicinesRestored + paymentsRestored;
}
