import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentSummaryCard extends StatelessWidget {
  final bool isReservation;
  final double totalPrice;
  final int itemCount;
  final String deliveryCost;
  final VoidCallback onViewDetails;

  const PaymentSummaryCard({
    super.key,
    required this.isReservation,
    required this.totalPrice,
    required this.itemCount,
    required this.deliveryCost,
    required this.onViewDetails,
  });

  double get totalAmount {
    final baseAmount = totalPrice * itemCount;
    if (!isReservation || !deliveryCost.contains('Tsh')) return baseAmount;
    
    final delivery = double.parse(deliveryCost.replaceAll('Tsh ', '').trim());
    return baseAmount + delivery;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]!
              : Colors.grey[300]!,
        ),
      ),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Amount Payable',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tsh ${NumberFormat('#,##0.00', 'en_US').format(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
