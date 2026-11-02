import 'package:hive/hive.dart';

import '../models/customer_medicine.dart';
import '../models/customer_payment.dart';
import '../models/regular_customer.dart';
import 'owner_data_service.dart';

/// Offline-first CRUD service for the authenticated owner's customer records.
class CustomerService {
  CustomerService._();
  static final CustomerService instance = CustomerService._();

  Box<RegularCustomer>? _customersBox;
  Box<CustomerMedicine>? _medicinesBox;
  Box<CustomerPayment>? _paymentsBox;

  Future<Box<RegularCustomer>> openCustomersBox() async {
    final name = OwnerDataService.instance.customersBoxName;
    if (_customersBox != null &&
        _customersBox!.isOpen &&
        _customersBox!.name == name) {
      return _customersBox!;
    }
    _customersBox = await Hive.openBox<RegularCustomer>(name);
    return _customersBox!;
  }

  Future<Box<CustomerMedicine>> openCustomerMedicinesBox() async {
    final name = OwnerDataService.instance.customerMedicinesBoxName;
    if (_medicinesBox != null &&
        _medicinesBox!.isOpen &&
        _medicinesBox!.name == name) {
      return _medicinesBox!;
    }
    _medicinesBox = await Hive.openBox<CustomerMedicine>(name);
    return _medicinesBox!;
  }

  Future<Box<CustomerPayment>> openPaymentsBox() async {
    final name = OwnerDataService.instance.customerPaymentsBoxName;
    if (_paymentsBox != null &&
        _paymentsBox!.isOpen &&
        _paymentsBox!.name == name) {
      return _paymentsBox!;
    }
    _paymentsBox = await Hive.openBox<CustomerPayment>(name);
    return _paymentsBox!;
  }

  Future<List<RegularCustomer>> getCustomers({String query = ''}) async {
    final values = (await openCustomersBox()).values.toList();
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? values
        : values
        .where((c) =>
    c.name.toLowerCase().contains(q) ||
        c.phone.toLowerCase().contains(q))
        .toList();
    filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return filtered;
  }

  Future<RegularCustomer?> getCustomerById(String id) async =>
      (await openCustomersBox()).get(id);

  Future<void> addCustomer(RegularCustomer customer) async {
    final box = await openCustomersBox();
    if (box.containsKey(customer.id)) {
      throw StateError('A customer with this ID already exists.');
    }
    await box.put(customer.id, customer);
    await box.flush();
  }

  Future<void> updateCustomer(RegularCustomer customer) async {
    final box = await openCustomersBox();
    if (!box.containsKey(customer.id)) {
      throw StateError('Customer not found. Refresh and try again.');
    }
    await box.put(customer.id, customer);
    await box.flush();
  }

  Future<void> deleteCustomer(String customerId) async {
    final customers = await openCustomersBox();
    if (!customers.containsKey(customerId)) {
      throw StateError('Customer not found. Refresh and try again.');
    }

    final medicines = await openCustomerMedicinesBox();
    final payments = await openPaymentsBox();

    // Remove associated records first, then the customer record.
    final medicineIds = medicines.values
        .where((m) => m.customerId == customerId)
        .map((m) => m.id)
        .toList();
    final paymentIds = payments.values
        .where((p) => p.customerId == customerId)
        .map((p) => p.id)
        .toList();

    await medicines.deleteAll(medicineIds);
    await medicines.flush();
    await payments.deleteAll(paymentIds);
    await payments.flush();
    await customers.delete(customerId);
    await customers.flush();
  }

  Future<List<CustomerMedicine>> getFrequentMedicines(
      String customerId,
      ) async {
    final values = (await openCustomerMedicinesBox())
        .values
        .where((m) => m.customerId == customerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<void> addFrequentMedicine(CustomerMedicine medicine) async {
    if (medicine.medicineName.trim().isEmpty) {
      throw ArgumentError('Medicine name cannot be empty.');
    }
    if (await getCustomerById(medicine.customerId) == null) {
      throw StateError('Customer not found.');
    }
    final box = await openCustomerMedicinesBox();
    if (box.containsKey(medicine.id)) {
      throw StateError('This medicine record already exists.');
    }
    await box.put(medicine.id, medicine);
    await box.flush();
  }

  Future<void> updateFrequentMedicine(CustomerMedicine medicine) async {
    if (medicine.medicineName.trim().isEmpty) {
      throw ArgumentError('Medicine name cannot be empty.');
    }
    if (await getCustomerById(medicine.customerId) == null) {
      throw StateError('Customer not found.');
    }

    final box = await openCustomerMedicinesBox();
    final existing = box.get(medicine.id);
    if (existing == null) {
      throw StateError('Medicine record not found.');
    }
    if (existing.customerId != medicine.customerId) {
      throw StateError('Medicine record does not belong to this customer.');
    }

    await box.put(medicine.id, medicine);
    await box.flush();
  }

  Future<void> deleteFrequentMedicine(String id) async {
    final box = await openCustomerMedicinesBox();
    if (!box.containsKey(id)) {
      throw StateError('Medicine record not found.');
    }
    await box.delete(id);
    await box.flush();
  }

  Future<List<CustomerPayment>> getPayments(String customerId) async {
    final values = (await openPaymentsBox())
        .values
        .where((p) => p.customerId == customerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  void _validatePayment(CustomerPayment payment) {
    if (payment.description.trim().isEmpty) {
      throw ArgumentError('Payment description cannot be empty.');
    }
    if (!payment.totalAmount.isFinite ||
        !payment.paidAmount.isFinite ||
        payment.totalAmount < 0 ||
        payment.paidAmount < 0 ||
        payment.paidAmount > payment.totalAmount) {
      throw ArgumentError('Enter valid amounts; paid cannot exceed total.');
    }
  }

  Future<void> addPayment(CustomerPayment payment) async {
    _validatePayment(payment);
    if (await getCustomerById(payment.customerId) == null) {
      throw StateError('Customer not found.');
    }
    final box = await openPaymentsBox();
    if (box.containsKey(payment.id)) {
      throw StateError('This payment record already exists.');
    }
    await box.put(payment.id, payment);
    await box.flush();
  }

  Future<void> updatePayment(CustomerPayment payment) async {
    _validatePayment(payment);
    if (await getCustomerById(payment.customerId) == null) {
      throw StateError('Customer not found.');
    }

    final box = await openPaymentsBox();
    final existing = box.get(payment.id);
    if (existing == null) {
      throw StateError('Payment record not found.');
    }
    if (existing.customerId != payment.customerId) {
      throw StateError('Payment record does not belong to this customer.');
    }

    await box.put(payment.id, payment);
    await box.flush();
  }

  Future<void> deletePayment(String id) async {
    final box = await openPaymentsBox();
    if (!box.containsKey(id)) {
      throw StateError('Payment record not found.');
    }
    await box.delete(id);
    await box.flush();
  }

  Future<double> getOutstandingBalance(String customerId) async {
    final payments = await getPayments(customerId);
    return payments.fold<double>(0, (sum, p) => sum + p.remainingAmount);
  }
}
