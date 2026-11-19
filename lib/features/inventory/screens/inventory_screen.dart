import 'package:flutter/material.dart';

import 'package:medilink/core/utils/expiry_utils.dart';
import 'package:medilink/features/inventory/screens/add_medicine_screen.dart';
import 'package:medilink/features/inventory/screens/medicine_details_screen.dart';
import 'package:medilink/models/medicine.dart';
import 'package:medilink/models/medicine_batch.dart';
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

  late Future<void> _initializationFuture;

  String searchQuery = '';
  String selectedStockFilter = 'All';
  String selectedExpiryFilter = 'All';
  String selectedSortOption = 'Name (A–Z)';

  final List<String> stockFilters = [
    'All',
    'In Stock',
    'Low Stock',
    'Out of Stock',
  ];

  final List<String> expiryFilters = [
    'All',
    'Expired',
    '≤30 Days',
    '31–60 Days',
    '61–90 Days',
    'Safe',
  ];

  final List<String> sortOptions = [
    'Name (A–Z)',
    'Name (Z–A)',
    'Price (Low–High)',
    'Price (High–Low)',
    'Stock (Low–High)',
    'Stock (High–Low)',
    'Earliest Expiry',
  ];

  @override
  void initState() {
    super.initState();

    searchController.addListener(_onSearchChanged);

    _initializationFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    await Future.wait([
      medicineService.openBox(),
      batchService.openBox(),
    ]);
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text.trim().toLowerCase();
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

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _openEditMedicine(Medicine medicine) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          medicine: medicine,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _openMedicineDetails(Medicine medicine) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineDetailsScreen(
          medicine: medicine,
        ),
      ),
    );

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _deleteMedicine(Medicine medicine) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Medicine'),
          content: Text(
            'Are you sure you want to delete ${medicine.name}?\n\n'
                'All associated batches will also be deleted.',
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
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final batches =
      batchService.getBatchesForMedicine(medicine.id);

      for (final batch in batches) {
        await batchService.deleteBatch(batch.id);
      }

      await medicineService.box.delete(medicine.id);

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine and its batches deleted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete medicine: $e'),
        ),
      );
    }
  }

  bool _matchesSearch(Medicine medicine) {
    if (searchQuery.isEmpty) return true;

    return medicine.name.toLowerCase().contains(searchQuery) ||
        medicine.genericName.toLowerCase().contains(searchQuery) ||
        medicine.manufacturer.toLowerCase().contains(searchQuery);
  }

  bool _matchesStockFilter(
      Medicine medicine,
      int totalStock,
      ) {
    switch (selectedStockFilter) {
      case 'In Stock':
        return totalStock > 0 &&
            totalStock > medicine.minimumStock;

      case 'Low Stock':
        return totalStock > 0 &&
            totalStock <= medicine.minimumStock;

      case 'Out of Stock':
        return totalStock == 0;

      case 'All':
      default:
        return true;
    }
  }

  bool _matchesExpiryFilter(List<MedicineBatch> batches) {
    if (selectedExpiryFilter == 'All') return true;

    if (batches.isEmpty) return false;

    final sortedBatches = [...batches]
      ..sort(
            (a, b) => a.expiryDate.compareTo(b.expiryDate),
      );

    final earliestExpiry = sortedBatches.first.expiryDate;

    final daysRemaining =
    ExpiryUtils.daysRemaining(earliestExpiry);

    switch (selectedExpiryFilter) {
      case 'Expired':
        return daysRemaining < 0;

      case '≤30 Days':
        return daysRemaining >= 0 && daysRemaining <= 30;

      case '31–60 Days':
        return daysRemaining >= 31 && daysRemaining <= 60;

      case '61–90 Days':
        return daysRemaining >= 61 && daysRemaining <= 90;

      case 'Safe':
        return daysRemaining > 90;

      case 'All':
      default:
        return true;
    }
  }

  Icon? _getExpiryIcon(String filter) {
    switch (filter) {
      case 'Expired':
        return const Icon(Icons.error_outline, size: 18);

      case '≤30 Days':
        return const Icon(
          Icons.warning_amber_rounded,
          size: 18,
        );

      case '31–60 Days':
        return const Icon(Icons.schedule, size: 18);

      case '61–90 Days':
        return const Icon(
          Icons.event_available_outlined,
          size: 18,
        );

      case 'Safe':
        return const Icon(
          Icons.check_circle_outline,
          size: 18,
        );

      case 'All':
      default:
        return null;
    }
  }

  int _getStock(Medicine medicine) {
    return batchService
        .getBatchesForMedicine(medicine.id)
        .fold<int>(
      0,
          (total, batch) => total + batch.quantity,
    );
  }

  DateTime _getEarliestExpiry(Medicine medicine) {
    final batches =
    batchService.getBatchesForMedicine(medicine.id);

    if (batches.isEmpty) {
      return DateTime(9999);
    }

    return batches
        .map((batch) => batch.expiryDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  void _sortMedicines(List<Medicine> medicines) {
    medicines.sort((a, b) {
      switch (selectedSortOption) {
        case 'Name (Z–A)':
          return b.name.toLowerCase().compareTo(
            a.name.toLowerCase(),
          );

        case 'Price (Low–High)':
          return a.sellingPrice.compareTo(b.sellingPrice);

        case 'Price (High–Low)':
          return b.sellingPrice.compareTo(a.sellingPrice);

        case 'Stock (Low–High)':
          return _getStock(a).compareTo(_getStock(b));

        case 'Stock (High–Low)':
          return _getStock(b).compareTo(_getStock(a));

        case 'Earliest Expiry':
          return _getEarliestExpiry(a).compareTo(
            _getEarliestExpiry(b),
          );

        case 'Name (A–Z)':
        default:
          return a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          );
      }
    });
  }

  Widget _buildInventoryContent() {
    final allMedicines = medicineService.box.values.toList();

    final medicines = allMedicines.where((medicine) {
      final batches =
      batchService.getBatchesForMedicine(medicine.id);

      final totalStock = batches.fold<int>(
        0,
            (total, batch) => total + batch.quantity,
      );

      return _matchesSearch(medicine) &&
          _matchesStockFilter(medicine, totalStock) &&
          _matchesExpiryFilter(batches);
    }).toList();

    _sortMedicines(medicines);

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
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  onPressed: searchController.clear,
                  icon: const Icon(Icons.clear),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: stockFilters.length,
              separatorBuilder: (context, index) =>
              const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = stockFilters[index];

                return FilterChip(
                  label: Text(filter),
                  selected: selectedStockFilter == filter,
                  onSelected: (_) {
                    setState(() {
                      selectedStockFilter = filter;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: expiryFilters.length,
              separatorBuilder: (context, index) =>
              const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = expiryFilters[index];

                return FilterChip(
                  avatar: _getExpiryIcon(filter),
                  label: Text(filter),
                  selected: selectedExpiryFilter == filter,
                  onSelected: (_) {
                    setState(() {
                      selectedExpiryFilter = filter;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            child: DropdownButtonFormField<String>(
              initialValue: selectedSortOption,
              decoration: InputDecoration(
                labelText: 'Sort inventory by',
                prefixIcon: const Icon(Icons.sort),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: sortOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedSortOption = value;
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: medicines.isEmpty
                ? Center(
              child: Text(
                searchQuery.isEmpty &&
                    selectedStockFilter == 'All' &&
                    selectedExpiryFilter == 'All'
                    ? 'No medicines added yet'
                    : 'No medicines found',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final medicine = medicines[index];

                final batches =
                batchService.getBatchesForMedicine(
                  medicine.id,
                );

                final totalStock = batches.fold<int>(
                  0,
                      (total, batch) => total + batch.quantity,
                );

                final isLowStock =
                    totalStock <= medicine.minimumStock;

                return _MedicineCard(
                  medicine: medicine,
                  totalStock: totalStock,
                  batchCount: batches.length,
                  isLowStock: isLowStock,
                  onEdit: () {
                    _openEditMedicine(medicine);
                  },
                  onDelete: () {
                    _deleteMedicine(medicine);
                  },
                  onTap: () {
                    _openMedicineDetails(medicine);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMedicine,
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Inventory'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load inventory',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initializationFuture =
                              _initializeServices();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _buildInventoryContent();
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
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
          isLowStock ? Colors.orange.shade100 : null,
          child: Icon(
            Icons.medication_outlined,
            color: isLowStock ? Colors.orange.shade800 : null,
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
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontWeight: FontWeight.w600,
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
                      'Low Stock • Minimum: ${medicine.minimumStock}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 10),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem<String>(
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