import 'package:hive/hive.dart';

import '../models/customer_medicine.dart';
import '../models/customer_payment.dart';
import '../models/regular_customer.dart';
import 'owner_data_service.dart';

/// Offline-first customer, frequently purchased medicine, and payment service.
/// All Hive boxes are isolated by the currently authenticated Firebase UID.
class CustomerService {
  CustomerService._();
  static final CustomerService instance = CustomerService._();

  Box<RegularCustomer>? _customersBox;
  Box<CustomerMedicine>? _medicinesBox;
  Box<CustomerPayment>? _paymentsBox;

  Future<Box<RegularCustomer>> openCustomersBox() async {
    final name = OwnerDataService.instance.customersBoxName;
    if (_customersBox != null && _customersBox!.isOpen && _customersBox!.name == name) return _customersBox!;
    _customersBox = await Hive.openBox<RegularCustomer>(name);
    return _customersBox!;
  }

  Future<Box<CustomerMedicine>> openCustomerMedicinesBox() async {
    final name = OwnerDataService.instance.customerMedicinesBoxName;
    if (_medicinesBox != null && _medicinesBox!.isOpen && _medicinesBox!.name == name) return _medicinesBox!;
    _medicinesBox = await Hive.openBox<CustomerMedicine>(name);
    return _medicinesBox!;
  }

  Future<Box<CustomerPayment>> openPaymentsBox() async {
    final name = OwnerDataService.instance.customerPaymentsBoxName;
    if (_paymentsBox != null && _paymentsBox!.isOpen && _paymentsBox!.name == name) return _paymentsBox!;
    _paymentsBox = await Hive.openBox<CustomerPayment>(name);
    return _paymentsBox!;
  }

  Future<List<RegularCustomer>> getCustomers({String query = ''}) async {
    final values = (await openCustomersBox()).values.toList();
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty ? values : values.where((c) => c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q)).toList();
    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return filtered;
  }

  Future<RegularCustomer?> getCustomerById(String id) async => (await openCustomersBox()).get(id);

  Future<void> addCustomer(RegularCustomer customer) async {
    final box = await openCustomersBox();
    if (box.containsKey(customer.id)) throw StateError('A customer with this ID already exists.');
    await box.put(customer.id, customer);
  }

  Future<void> updateCustomer(RegularCustomer customer) async {
    final box = await openCustomersBox();
    if (!box.containsKey(customer.id)) throw StateError('Customer not found.');
    await box.put(customer.id, customer);
  }

  Future<void> deleteCustomer(String customerId) async {
    await (await openCustomersBox()).delete(customerId);
    final medicines = await openCustomerMedicinesBox();
    final payments = await openPaymentsBox();
    final medicineIds = medicines.values.where((m) => m.customerId == customerId).map((m) => m.id).toList();
    final paymentIds = payments.values.where((p) => p.customerId == customerId).map((p) => p.id).toList();
    await medicines.deleteAll(medicineIds);
    await payments.deleteAll(paymentIds);
  }

  Future<List<CustomerMedicine>> getFrequentMedicines(String customerId) async {
    final values = (await openCustomerMedicinesBox()).values.where((m) => m.customerId == customerId).toList();
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<void> addFrequentMedicine(CustomerMedicine medicine) async {
    if (await getCustomerById(medicine.customerId) == null) throw StateError('Customer not found.');
    final box = await openCustomerMedicinesBox();
    if (box.containsKey(medicine.id)) throw StateError('This medicine record already exists.');
    await box.put(medicine.id, medicine);
  }

  Future<void> updateFrequentMedicine(CustomerMedicine medicine) async {
    final box = await openCustomerMedicinesBox();
    if (!box.containsKey(medicine.id)) throw StateError('Medicine record not found.');
    await box.put(medicine.id, medicine);
  }

  Future<void> deleteFrequentMedicine(String id) async => (await openCustomerMedicinesBox()).delete(id);

  Future<List<CustomerPayment>> getPayments(String customerId) async {
    final values = (await openPaymentsBox()).values.where((p) => p.customerId == customerId).toList();
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<void> addPayment(CustomerPayment payment) async {
    if (await getCustomerById(payment.customerId) == null) throw StateError('Customer not found.');
    if (payment.paidAmount > payment.totalAmount) throw ArgumentError('Paid amount cannot exceed total amount.');
    final box = await openPaymentsBox();
    if (box.containsKey(payment.id)) throw StateError('This payment record already exists.');
    await box.put(payment.id, payment);
  }

  Future<void> updatePayment(CustomerPayment payment) async {
    if (payment.paidAmount > payment.totalAmount) throw ArgumentError('Paid amount cannot exceed total amount.');
    final box = await openPaymentsBox();
    if (!box.containsKey(payment.id)) throw StateError('Payment record not found.');
    await box.put(payment.id, payment);
  }

  Future<void> deletePayment(String id) async => (await openPaymentsBox()).delete(id);

  Future<double> getOutstandingBalance(String customerId) async {
    final payments = await getPayments(customerId);
    return payments.fold<double>(0, (sum, p) => sum + p.remainingAmount);
  }
}
