import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../models/regular_customer.dart';
import '../../../services/customer_service.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _search = TextEditingController();
  late Future<Box<RegularCustomer>> _boxFuture;

  @override
  void initState() {
    super.initState();
    _boxFuture = CustomerService.instance.openCustomersBox();
  }

  void _reopenBox() {
    if (!mounted) return;
    setState(() {
      _boxFuture = CustomerService.instance.openCustomersBox();
    });
  }

  Future<void> _addCustomer() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const AddCustomerScreen(),
      ),
    );
    _reopenBox();
  }

  Future<void> _openCustomer(RegularCustomer customer) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CustomerDetailsScreen(customerId: customer.id),
      ),
    );
    _reopenBox();
  }

  Future<void> _editCustomer(RegularCustomer customer) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddCustomerScreen(customer: customer),
      ),
    );
    _reopenBox();
  }

  Future<void> _deleteCustomer(RegularCustomer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text(
          'Delete ${customer.name} and all their saved medicine and payment '
              'records? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete customer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await CustomerService.instance.deleteCustomer(customer.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer and related records deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete customer: $error')),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Regular customers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search name or phone',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: FutureBuilder<Box<RegularCustomer>>(
              future: _boxFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Could not open customers: ${snapshot.error}',
                      ),
                    ),
                  );
                }

                final box = snapshot.data;
                if (box == null || !box.isOpen) {
                  return Center(
                    child: OutlinedButton(
                      onPressed: _reopenBox,
                      child: const Text('Retry loading customers'),
                    ),
                  );
                }

                return ValueListenableBuilder<Box<RegularCustomer>>(
                  valueListenable: box.listenable(),
                  builder: (context, listenableBox, _) {
                    final query = _search.text.trim().toLowerCase();
                    final customers = listenableBox.values.where((customer) {
                      if (query.isEmpty) return true;
                      return customer.name.toLowerCase().contains(query) ||
                          customer.phone.toLowerCase().contains(query);
                    }).toList()
                      ..sort(
                            (a, b) => a.name.toLowerCase().compareTo(
                          b.name.toLowerCase(),
                        ),
                      );

                    if (customers.isEmpty) {
                      return Center(
                        child: Text(
                          query.isEmpty
                              ? 'No customers yet. Add your first customer.'
                              : 'No customers match "${_search.text.trim()}".',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person_outline),
                            ),
                            title: Text(customer.name),
                            subtitle: Text(
                              customer.phone.isNotEmpty
                                  ? customer.phone
                                  : (customer.notes.isNotEmpty
                                  ? customer.notes
                                  : 'No additional details'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _openCustomer(customer),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'Customer actions',
                              onSelected: (action) {
                                if (action == 'view') _openCustomer(customer);
                                if (action == 'edit') _editCustomer(customer);
                                if (action == 'delete') {
                                  _deleteCustomer(customer);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'view',
                                  child: Text('View details'),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit customer'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete customer'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
