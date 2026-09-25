import 'package:flutter/material.dart';

import 'package:medilink/core/utils/expiry_utils.dart';
import 'package:medilink/models/medicine.dart';
import 'package:medilink/models/medicine_batch.dart';
import 'package:medilink/services/batch_service.dart';
import 'package:medilink/services/medicine_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final MedicineService medicineService = MedicineService();
  final BatchService batchService = BatchService();

  Future<void> _refresh() async {
    await medicineService.openBox();
    await batchService.openBox();

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

        final lowStockMedicines = <Medicine>[];
        final outOfStockMedicines = <Medicine>[];

        final expiredBatches = <_ExpiryAlertItem>[];
        final criticalBatches = <_ExpiryAlertItem>[];
        final warningBatches = <_ExpiryAlertItem>[];
        final upcomingBatches = <_ExpiryAlertItem>[];

        for (final medicine in medicines) {
          final batches =
          batchService.getBatchesForMedicine(
            medicine.id,
          );

          final totalStock = batches.fold<int>(
            0,
                (total, batch) {
              return total + batch.quantity;
            },
          );

          if (totalStock == 0) {
            outOfStockMedicines.add(medicine);
          } else if (
          totalStock <= medicine.minimumStock) {
            lowStockMedicines.add(medicine);
          }

          for (final batch in batches) {
            final status =
            ExpiryUtils.getStatus(
              batch.expiryDate,
            );

            final item = _ExpiryAlertItem(
              medicine: medicine,
              batch: batch,
            );

            switch (status) {
              case ExpiryStatus.expired:
                expiredBatches.add(item);
                break;

              case ExpiryStatus.critical:
                criticalBatches.add(item);
                break;

              case ExpiryStatus.warning:
                warningBatches.add(item);
                break;

              case ExpiryStatus.upcoming:
                upcomingBatches.add(item);
                break;

              case ExpiryStatus.safe:
                break;
            }
          }
        }

        final totalAlerts =
            lowStockMedicines.length +
                outOfStockMedicines.length +
                expiredBatches.length +
                criticalBatches.length +
                warningBatches.length +
                upcomingBatches.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Alerts'),
            actions: [
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: totalAlerts == 0
              ? const _NoAlertsView()
              : RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Out of stock
                if (outOfStockMedicines.isNotEmpty) ...[
                  _AlertSection(
                    title: 'Out of Stock',
                    count:
                    outOfStockMedicines.length,
                    icon:
                    Icons.remove_shopping_cart_outlined,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  ...outOfStockMedicines.map(
                        (medicine) => _MedicineAlertCard(
                      medicine: medicine,
                      message: 'Out of stock',
                      icon:
                      Icons.remove_shopping_cart_outlined,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Low stock
                if (lowStockMedicines.isNotEmpty) ...[
                  _AlertSection(
                    title: 'Low Stock',
                    count:
                    lowStockMedicines.length,
                    icon:
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  ...lowStockMedicines.map(
                        (medicine) {
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

                      return _MedicineAlertCard(
                        medicine: medicine,
                        message:
                        'Stock: $totalStock • '
                            'Minimum: '
                            '${medicine.minimumStock}',
                        icon:
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Expired
                if (expiredBatches.isNotEmpty) ...[
                  _AlertSection(
                    title: 'Expired Medicines',
                    count: expiredBatches.length,
                    icon: Icons.dangerous_outlined,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  ...expiredBatches.map(
                        (item) => _ExpiryAlertCard(
                      item: item,
                      color: Colors.red,
                      icon: Icons.dangerous_outlined,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Expiring within 30 days
                if (criticalBatches.isNotEmpty) ...[
                  _AlertSection(
                    title: 'Expires Within 30 Days',
                    count: criticalBatches.length,
                    icon:
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  ...criticalBatches.map(
                        (item) => _ExpiryAlertCard(
                      item: item,
                      color: Colors.orange,
                      icon:
                      Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 31–60 days
                if (warningBatches.isNotEmpty) ...[
                  _AlertSection(
                    title: 'Expires Within 60 Days',
                    count: warningBatches.length,
                    icon: Icons.schedule_outlined,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(height: 12),
                  ...warningBatches.map(
                        (item) => _ExpiryAlertCard(
                      item: item,
                      color: Colors.amber.shade800,
                      icon:
                      Icons.schedule_outlined,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 61–90 days
                if (upcomingBatches.isNotEmpty) ...[
                  _AlertSection(
                    title: 'Expires Within 90 Days',
                    count: upcomingBatches.length,
                    icon:
                    Icons.calendar_month_outlined,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  ...upcomingBatches.map(
                        (item) => _ExpiryAlertCard(
                      item: item,
                      color: Colors.blue,
                      icon:
                      Icons.calendar_month_outlined,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExpiryAlertItem {
  final Medicine medicine;
  final MedicineBatch batch;

  const _ExpiryAlertItem({
    required this.medicine,
    required this.batch,
  });
}

class _AlertSection extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _AlertSection({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicineAlertCard extends StatelessWidget {
  final Medicine medicine;
  final String message;
  final IconData icon;
  final Color color;

  const _MedicineAlertCard({
    required this.medicine,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          color.withValues(alpha: 0.12),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          medicine.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(message),
      ),
    );
  }
}

class _ExpiryAlertCard extends StatelessWidget {
  final _ExpiryAlertItem item;
  final Color color;
  final IconData icon;

  const _ExpiryAlertCard({
    required this.item,
    required this.color,
    required this.icon,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final days =
    ExpiryUtils.daysRemaining(
      item.batch.expiryDate,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          color.withValues(alpha: 0.12),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          item.medicine.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Batch ${item.batch.batchNumber} • '
              'Expiry: ${_formatDate(item.batch.expiryDate)}\n'
              '${days < 0 ? 'Expired' : 'Expires in $days days'}',
        ),
      ),
    );
  }
}

class _NoAlertsView extends StatelessWidget {
  const _NoAlertsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No Alerts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your medicine stock looks good.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}