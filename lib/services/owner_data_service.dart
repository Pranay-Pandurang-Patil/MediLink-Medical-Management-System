import 'package:firebase_auth/firebase_auth.dart';

/// Resolves the authenticated owner's isolated Hive box names.
///
/// This class does not open, clear, or migrate any boxes. Legacy shared data
/// remains untouched until DataMigrationService is explicitly invoked.
class OwnerDataService {
  OwnerDataService._();

  static final OwnerDataService instance = OwnerDataService._();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String get ownerId {
    final user = currentUser;
    if (user == null) {
      throw StateError('An authenticated owner is required to access MediLink data.');
    }
    return user.uid;
  }

  String get ownerKey => _safeKey(ownerId);

  String get medicinesBoxName => 'medicines_owner_$ownerKey';
  String get batchesBoxName => 'medicine_batches_owner_$ownerKey';
  String get shopProfileBoxName => 'shop_profile_owner_$ownerKey';
  String get notesBoxName => 'daily_notes_owner_$ownerKey';
  String get customersBoxName => 'regular_customers_owner_$ownerKey';
  String get customerMedicinesBoxName => 'customer_medicines_owner_$ownerKey';
  String get customerPaymentsBoxName => 'customer_payments_owner_$ownerKey';

  /// Ensures a supplied owner ID is converted to a safe Hive box-name segment.
  /// Firebase UIDs normally contain only letters, digits, hyphens and
  /// underscores; this also handles unexpected input defensively.
  static String _safeKey(String value) {
    final result = value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (result.isEmpty) {
      throw ArgumentError.value(value, 'value', 'Cannot be empty.');
    }
    return result;
  }
}
