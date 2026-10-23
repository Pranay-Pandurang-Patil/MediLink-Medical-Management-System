import 'package:flutter/material.dart';

import '../../../models/customer_medicine.dart';
import '../../../models/customer_payment.dart';
import '../../../models/regular_customer.dart';
import '../../../services/customer_service.dart';
import '../widgets/customer_payment_card.dart';
import 'add_customer_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late Future<RegularCustomer?> _customerFuture;
  late Future<_CustomerDetailsData> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<_CustomerDetailsData> _loadDetails() async {
    final results = await Future.wait<Object>([
      CustomerService.instance.getFrequentMedicines(widget.customerId),
      CustomerService.instance.getPayments(widget.customerId),
      CustomerService.instance.getOutstandingBalance(widget.customerId),
    ]);
    return _CustomerDetailsData(
      medicines: results[0] as List<CustomerMedicine>,
      payments: results[1] as List<CustomerPayment>,
      balance: results[2] as double,
    );
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _customerFuture =
          CustomerService.instance.getCustomerById(widget.customerId);
      _detailsFuture = _loadDetails();
    });
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editCustomer(RegularCustomer customer) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddCustomerScreen(customer: customer),
      ),
    );
    _refresh();
  }

  Future<void> _deleteMedicine(CustomerMedicine medicine) async {
    final confirmed = await _confirm(
      title: 'Delete medicine?',
      message: 'Remove ${medicine.medicineName} from this customer?',
    );
    if (confirmed != true) return;
    try {
      await CustomerService.instance.deleteFrequentMedicine(medicine.id);
      _refresh();
      _message('Medicine removed.');
    } catch (error) {
      _message('Could not remove medicine: $error');
    }
  }

  Future<void> _editMedicine(CustomerMedicine? existing) async {
    final nameController = TextEditingController(
      text: existing?.medicineName ?? '',
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    var saving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(existing == null ? 'Add frequent medicine' : 'Edit medicine'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Medicine name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a medicine name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => saving = true);
                  try {
                    final now = DateTime.now();
                    if (existing == null) {
                      await CustomerService.instance.addFrequentMedicine(
                        CustomerMedicine(
                          id: now.microsecondsSinceEpoch.toString(),
                          customerId: widget.customerId,
                          medicineName: nameController.text.trim(),
                          notes: notesController.text.trim(),
                          createdAt: now,
                        ),
                      );
                    } else {
                      await CustomerService.instance.updateFrequentMedicine(
                        existing.copyWith(
                          medicineName: nameController.text.trim(),
                          notes: notesController.text.trim(),
                        ),
                      );
                    }
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    _refresh();
                    _message(existing == null ? 'Medicine added.' : 'Medicine updated.');
                  } catch (error) {
                    setDialogState(() => saving = false);
                    _message('Could not save medicine: $error');
                  }
                },
                child: Text(saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameController.dispose();
      notesController.dispose();
    }
  }

  Future<void> _editPayment(CustomerPayment? existing) async {
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final totalController = TextEditingController(
      text: existing == null ? '' : existing.totalAmount.toStringAsFixed(2),
    );
    final paidController = TextEditingController(
      text: existing == null ? '0' : existing.paidAmount.toStringAsFixed(2),
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    final formKey = GlobalKey<FormState>();
    var saving = false;

    String? amountValidator(String? value) {
      final amount = double.tryParse((value ?? '').trim());
      if (amount == null || !amount.isFinite || amount < 0) {
        return 'Enter a valid amount (0 or more)';
      }
      return null;
    }

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(existing == null ? 'Add payment record' : 'Edit payment record'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a description'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: totalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Total amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                      validator: amountValidator,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: paidController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Paid amount (₹)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final baseError = amountValidator(value);
                        if (baseError != null) return baseError;
                        final total = double.tryParse(totalController.text.trim());
                        final paid = double.tryParse((value ?? '').trim());
                        if (total != null && paid != null && paid > total) {
                          return 'Paid amount cannot exceed total';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                  if (!formKey.currentState!.validate()) return;
                  final total = double.parse(totalController.text.trim());
                  final paid = double.parse(paidController.text.trim());
                  if (paid > total) {
                    _message('Paid amount cannot exceed total amount.');
                    return;
                  }
                  setDialogState(() => saving = true);
                  try {
                    final now = DateTime.now();
                    if (existing == null) {
                      await CustomerService.instance.addPayment(
                        CustomerPayment(
                          id: now.microsecondsSinceEpoch.toString(),
                          customerId: widget.customerId,
                          description: descriptionController.text.trim(),
                          totalAmount: total,
                          paidAmount: paid,
                          createdAt: now,
                          notes: notesController.text.trim(),
                        ),
                      );
                    } else {
                      await CustomerService.instance.updatePayment(
                        existing.copyWith(
                          description: descriptionController.text.trim(),
                          totalAmount: total,
                          paidAmount: paid,
                          notes: notesController.text.trim(),
                        ),
                      );
                    }
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    _refresh();
                    _message(existing == null ? 'Payment saved.' : 'Payment updated.');
                  } catch (error) {
                    setDialogState(() => saving = false);
                    _message('Could not save payment: $error');
                  }
                },
                child: Text(saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      descriptionController.dispose();
      totalController.dispose();
      paidController.dispose();
      notesController.dispose();
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePayment(CustomerPayment payment) async {
    final confirmed = await _confirm(
      title: 'Delete payment record?',
      message: 'Delete “${payment.description}”? This cannot be undone.',
    );
    if (confirmed != true) return;
    try {
      await CustomerService.instance.deletePayment(payment.id);
      _refresh();
      _message('Payment record deleted.');
    } catch (error) {
      _message('Could not delete payment: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Customer details')),
    body: FutureBuilder<RegularCustomer?>(
      future: _customerFuture,
      builder: (context, customerSnapshot) {
        if (customerSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (customerSnapshot.hasError) {
          return Center(
            child: Text('Could not load customer: ${customerSnapshot.error}'),
          );
        }
        final customer = customerSnapshot.data;
        if (customer == null) {
          return const Center(child: Text('Customer not found.'));
        }
        return FutureBuilder<_CustomerDetailsData>(
          future: _detailsFuture,
          builder: (context, detailsSnapshot) {
            if (detailsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (detailsSnapshot.hasError) {
              return Center(
                child: Text('Could not load customer records: ${detailsSnapshot.error}'),
              );
            }
            final details = detailsSnapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text(
                      [
                        if (customer.phone.isNotEmpty) customer.phone,
                        if (customer.notes.isNotEmpty) customer.notes,
                      ].join('\n'),
                    ),
                    isThreeLine: customer.notes.isNotEmpty,
                    trailing: IconButton(
                      tooltip: 'Edit customer',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editCustomer(customer),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('Outstanding balance'),
                    subtitle: const Text('Total unpaid amount across records'),
                    trailing: Text(
                      '₹${details.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: details.balance > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Frequently purchased medicines',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add medicine',
                      onPressed: () => _editMedicine(null),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                if (details.medicines.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No frequent medicines recorded.'),
                  )
                else
                  ...details.medicines.map(
                        (medicine) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.medication_outlined),
                        title: Text(medicine.medicineName),
                        subtitle: medicine.notes.isEmpty ? null : Text(medicine.notes),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Medicine actions',
                          onSelected: (action) {
                            if (action == 'edit') _editMedicine(medicine);
                            if (action == 'delete') _deleteMedicine(medicine);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment records',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add payment record',
                      onPressed: () => _editPayment(null),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                if (details.payments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No payment records.'),
                  )
                else
                  ...details.payments.map(
                        (payment) => CustomerPaymentCard(
                      payment: payment,
                      onEdit: () => _editPayment(payment),
                      onDelete: () => _deletePayment(payment),
                    ),
                  ),
                const SizedBox(height: 72),
              ],
            );
          },
        );
      },
    ),
  );

  @override
  void dispose() {
    super.dispose();
  }
}

class _CustomerDetailsData {
  final List<CustomerMedicine> medicines;
  final List<CustomerPayment> payments;
  final double balance;

  const _CustomerDetailsData({
    required this.medicines,
    required this.payments,
    required this.balance,
  });
}
