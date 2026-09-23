import 'package:flutter/material.dart';

import 'package:medilink/features/inventory/screens/add_medicine_screen.dart';
import 'package:medilink/features/inventory/screens/medicine_details_screen.dart';
import 'package:medilink/models/medicine.dart';
import 'package:medilink/services/batch_service.dart';
import 'package:medilink/services/medicine_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final MedicineService medicineService = MedicineService();
  final BatchService batchService = BatchService();

  final TextEditingController searchController =
  TextEditingController();

  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery =
          searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddMedicine() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMedicineScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openEditMedicine(
      Medicine medicine,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          medicine: medicine,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openMedicineDetails(
      Medicine medicine,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineDetailsScreen(
          medicine: medicine,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _deleteMedicine(
      Medicine medicine,
      ) async {
    final bool? shouldDelete =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Medicine'),
          content: Text(
            'Are you sure you want to delete '
                '${medicine.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await medicineService.box.delete(
      medicine.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Medicine deleted'),
      ),
    );
  }

  bool _matchesSearch(Medicine medicine) {
    if (searchQuery.isEmpty) {
      return true;
    }

    return medicine.name
        .toLowerCase()
        .contains(searchQuery) ||
        medicine.genericName
            .toLowerCase()
            .contains(searchQuery) ||
        medicine.manufacturer
            .toLowerCase()
            .contains(searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        medicineService.openBox(),
        batchService.openBox(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState !=
            ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final allMedicines =
        medicineService.box.values.toList();

        final medicines =
        allMedicines.where(_matchesSearch).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Inventory'),
          ),

          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search medicines...',
                    prefixIcon: const Icon(
                      Icons.search,
                    ),
                    suffixIcon:
                    searchQuery.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        searchController.clear();
                      },
                      icon: const Icon(
                        Icons.clear,
                      ),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: medicines.isEmpty
                    ? Center(
                  child: Text(
                    searchQuery.isEmpty
                        ? 'No medicines added yet'
                        : 'No medicines found',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  itemCount: medicines.length,
                  itemBuilder:
                      (context, index) {
                    final medicine =
                    medicines[index];

                    final batches =
                    batchService
                        .getBatchesForMedicine(
                      medicine.id,
                    );

                    final totalStock =
                    batches.fold<int>(
                      0,
                          (total, batch) {
                        return total +
                            batch.quantity;
                      },
                    );

                    final isLowStock =
                        totalStock <=
                            medicine.minimumStock;

                    return _MedicineCard(
                      medicine: medicine,
                      totalStock: totalStock,
                      batchCount: batches.length,
                      isLowStock: isLowStock,
                      onEdit: () {
                        _openEditMedicine(
                          medicine,
                        );
                      },
                      onDelete: () {
                        _deleteMedicine(
                          medicine,
                        );
                      },
                      onTap: () {
                        _openMedicineDetails(
                          medicine,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          floatingActionButton:
          FloatingActionButton.extended(
            onPressed: _openAddMedicine,
            icon: const Icon(Icons.add),
            label: const Text('Add Medicine'),
          ),
        );
      },
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final int totalStock;
  final int batchCount;
  final bool isLowStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _MedicineCard({
    required this.medicine,
    required this.totalStock,
    required this.batchCount,
    required this.isLowStock,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        onTap: onTap,

        leading: CircleAvatar(
          backgroundColor: isLowStock
              ? Colors.orange.shade100
              : null,
          child: Icon(
            Icons.medication_outlined,
            color: isLowStock
                ? Colors.orange.shade800
                : null,
          ),
        ),

        title: Text(
          medicine.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: 6,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                '₹${medicine.sellingPrice.toStringAsFixed(2)}',
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 15,
                    color: totalStock == 0
                        ? Colors.red
                        : isLowStock
                        ? Colors.orange
                        : Colors.green,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    'Stock: $totalStock',
                    style: TextStyle(
                      color: totalStock == 0
                          ? Colors.red
                          : isLowStock
                          ? Colors.orange
                          : Colors.green,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Icon(
                    Icons.layers_outlined,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    'Batches: $batchCount',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),

              if (isLowStock) ...[
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      'Low Stock • Minimum: '
                          '${medicine.minimumStock}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        trailing:
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            }

            if (value == 'delete') {
              onDelete();
            }
          },

          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                  ),
                  SizedBox(width: 10),
                  Text('Edit'),
                ],
              ),
            ),

            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}