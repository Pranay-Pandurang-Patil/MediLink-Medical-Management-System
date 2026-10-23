import 'package:flutter/material.dart';

import '../../../models/customer_payment.dart';

class CustomerPaymentCard extends StatelessWidget {
  final CustomerPayment payment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CustomerPaymentCard({
    super.key,
    required this.payment,
    this.onEdit,
    this.onDelete,
  });

  String _money(double value) => '₹${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final status = switch (payment.status) {
      PaymentStatus.paid => 'Paid',
      PaymentStatus.partiallyPaid => 'Partially paid',
      PaymentStatus.unpaid => 'Unpaid',
    };
    final color = switch (payment.status) {
      PaymentStatus.paid => Colors.green,
      PaymentStatus.partiallyPaid => Colors.orange,
      PaymentStatus.unpaid => Colors.red,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    payment.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(status),
                  labelStyle: TextStyle(color: color),
                  side: BorderSide(color: color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Total: ${_money(payment.totalAmount)}'),
            Text('Paid: ${_money(payment.paidAmount)}'),
            Text(
              'Remaining: ${_money(payment.remainingAmount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: payment.remainingAmount > 0 ? Colors.red : Colors.green,
              ),
            ),
            if (payment.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(payment.notes),
              ),
            if (onEdit != null || onDelete != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    IconButton(
                      tooltip: 'Edit payment',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Delete payment',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
