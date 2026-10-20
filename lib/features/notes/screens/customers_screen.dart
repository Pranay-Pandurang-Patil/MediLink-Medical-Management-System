import 'package:flutter/material.dart';
import '../../../models/regular_customer.dart';
import '../../../services/customer_service.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';

class CustomersScreen extends StatefulWidget { const CustomersScreen({super.key}); @override State<CustomersScreen> createState() => _CustomersScreenState(); }
class _CustomersScreenState extends State<CustomersScreen> {
  final _search = TextEditingController(); late Future<List<RegularCustomer>> _customers;
  @override void initState() { super.initState(); _load(); }
  void _load() => _customers = CustomerService.instance.getCustomers(query: _search.text);
  @override void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _refresh() async { setState(_load); await _customers; }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Regular customers')), floatingActionButton: FloatingActionButton.extended(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen())); await _refresh(); }, icon: const Icon(Icons.person_add_alt_1), label: const Text('Add customer')), body: Column(children: [Padding(padding: const EdgeInsets.all(16), child: TextField(controller: _search, onChanged: (_) => setState(_load), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search name or phone', border: OutlineInputBorder()))), Expanded(child: FutureBuilder<List<RegularCustomer>>(future: _customers, builder: (context, snap) { if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (snap.hasError) return Center(child: Text('Could not load customers: ${snap.error}')); final customers = snap.data ?? []; if (customers.isEmpty) return const Center(child: Text('No regular customers added yet.')); return ListView.builder(itemCount: customers.length, itemBuilder: (context, i) { final c = customers[i]; return ListTile(leading: const CircleAvatar(child: Icon(Icons.person_outline)), title: Text(c.name), subtitle: Text(c.phone.isEmpty ? (c.notes.isEmpty ? 'No additional details' : c.notes) : c.phone), trailing: const Icon(Icons.chevron_right), onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customerId: c.id))); await _refresh(); }); }); }))]));
}
