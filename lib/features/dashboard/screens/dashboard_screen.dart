import 'package:flutter/material.dart';

import 'package:medilink/core/utils/expiry_utils.dart';
import 'package:medilink/features/alerts/screens/alerts_screen.dart';
import 'package:medilink/features/inventory/screens/add_medicine_screen.dart';
import 'package:medilink/features/inventory/screens/inventory_screen.dart';

import 'package:medilink/services/batch_service.dart';
import 'package:medilink/services/medicine_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  final MedicineService medicineService =
  MedicineService();

  final BatchService batchService =
  BatchService();

  Future<void> _openAddMedicine() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const AddMedicineScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openInventory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const InventoryScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _openAlerts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const AlertsScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {});
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

        final medicines =
        medicineService.box.values.toList();

        int totalStock = 0;
        int lowStockCount = 0;
        int expiredCount = 0;
        int expiringSoonCount = 0;

        for (final medicine in medicines) {
          final batches =
          batchService.getBatchesForMedicine(
            medicine.id,
          );

          final medicineStock =
          batches.fold<int>(
            0,
                (total, batch) {
              return total + batch.quantity;
            },
          );

          totalStock += medicineStock;

          if (medicineStock > 0 &&
              medicineStock <=
                  medicine.minimumStock) {
            lowStockCount++;
          }

          for (final batch in batches) {
            final status =
            ExpiryUtils.getStatus(
              batch.expiryDate,
            );

            if (status == ExpiryStatus.expired) {
              expiredCount++;
            }

            if (status == ExpiryStatus.critical ||
                status == ExpiryStatus.warning ||
                status == ExpiryStatus.upcoming) {
              expiringSoonCount++;
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('MediLink'),
          ),

          body: RefreshIndicator(
            onRefresh: () async {
              await medicineService.openBox();
              await batchService.openBox();

              if (!mounted) {
                return;
              }

              setState(() {});
            },

            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Overview of your medical shop',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 25),

                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    _DashboardCard(
                      title: 'Medicines',
                      value: '${medicines.length}',
                      icon:
                      Icons.medication_outlined,
                      color: Colors.blue,
                    ),

                    _DashboardCard(
                      title: 'Total Stock',
                      value: '$totalStock',
                      icon:
                      Icons.inventory_2_outlined,
                      color: Colors.green,
                    ),

                    _DashboardCard(
                      title: 'Low Stock',
                      value: '$lowStockCount',
                      icon:
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),

                    _DashboardCard(
                      title: 'Expired',
                      value: '$expiredCount',
                      icon:
                      Icons.dangerous_outlined,
                      color: Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      Colors.orange.shade100,
                      child: Icon(
                        Icons.schedule_outlined,
                        color:
                        Colors.orange.shade800,
                      ),
                    ),
                    title: const Text(
                      'Expiring Soon',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '$expiringSoonCount batch'
                          '${expiringSoonCount == 1 ? '' : 'es'} '
                          'within 90 days',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: _openAlerts,
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.add,
                        label: 'Add Medicine',
                        onTap: _openAddMedicine,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _QuickActionButton(
                        icon:
                        Icons.inventory_2_outlined,
                        label: 'Inventory',
                        onTap: _openInventory,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _QuickActionButton(
                  icon:
                  Icons.notifications_outlined,
                  label: 'View Alerts',
                  onTap: _openAlerts,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor:
              color.withValues(alpha: 0.12),
              child: Icon(
                icon,
                color: color,
              ),
            ),

            const Spacer(),

            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(12),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}