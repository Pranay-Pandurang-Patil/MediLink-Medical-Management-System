import 'package:flutter/material.dart';

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
  final _search = TextEditingController();
  late Future<List<RegularCustomer>> _customers;

  @override
  void initState() {
    super.initState();
    _customers = _loadCustomers();
  }

  Future<List<RegularCustomer>> _loadCustomers() =>
      CustomerService.instance.getCustomers(query: _search.text);

  void _reload() {
    if (mounted) setState(() => _customers = _loadCustomers());
  }

  Future<void> _addCustomer() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const AddCustomerScreen()),
    );
    _reload();
  }

  Future<void> _openCustomer(RegularCustomer customer) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CustomerDetailsScreen(customerId: customer.id),
      ),
    );
    _reload();
  }

  Future<void> _editCustomer(RegularCustomer customer) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddCustomerScreen(customer: customer),
      ),
    );
    _reload();
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
    if (confirmed != true) return;

    try {
      await CustomerService.instance.deleteCustomer(customer.id);
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete customer: $error')),
        );
      }
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
            onChanged: (_) => _reload(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search name or phone',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<RegularCustomer>>(
            future: _customers,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Could not load customers: ${snapshot.error}',
                  ),
                );
              }
              final customers = snapshot.data ?? [];
              if (customers.isEmpty) {
                return const Center(
                  child: Text('No customers found. Add your first customer.'),
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
                          if (action == 'open') _openCustomer(customer);
                          if (action == 'edit') _editCustomer(customer);
                          if (action == 'delete') _deleteCustomer(customer);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'open',
                            child: ListTile(
                              dense: true,
                              leading: Icon(Icons.person_outline),
                              title: Text('View details'),
                            ),
                          ),
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
