import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentProceedTable extends StatelessWidget {
  final bool isReservation;
  final String? currentStreetName;
  final int totalQuantity;
  final int adults;
  final int children;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String estimatedTime;
  final String deliveryCost;
  final double totalPrice;
  final int itemCount;
  final double? exchangeRate;
  final Function(int) onAdultsChanged;
  final Function(int) onChildrenChanged;

  const PaymentProceedTable({
    super.key,
    required this.isReservation,
    this.currentStreetName,
    required this.totalQuantity,
    required this.adults,
    required this.children,
    this.checkInDate,
    this.checkOutDate,
    required this.estimatedTime,
    required this.deliveryCost,
    required this.totalPrice,
    required this.itemCount,
    this.exchangeRate,
    required this.onAdultsChanged,
    required this.onChildrenChanged,
  });

  String getFormattedDate(DateTime? date) {
    return date != null ? DateFormat('MMM dd, yyyy').format(date) : 'Not set';
  }

  String formatEstimatedTime(String time) {
    return time;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isReservation) ...[
          _buildSection(
            title: 'Delivery Information',
            children: [
              _buildInfoTile(
                icon: Icons.location_on_outlined,
                label: 'Delivery Location',
                value: currentStreetName ?? 'N/A',
                context: context,
              ),
              // _buildInfoTile(
              //   icon: Icons.timer_outlined,
              //   label: 'Estimated Time',
              //   value: estimatedTime.contains('min')
              //       ? formatEstimatedTime(estimatedTime)
              //       : 'Calculating...',
              // ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        
        _buildSection(
          title: isReservation ? 'Order Summary' : 'Booking Details',
          children: [
            _buildInfoTile(
              icon: isReservation ? Icons.shopping_bag_outlined : Icons.hotel_outlined,
              label: isReservation ? 'Quantity' : 'Rooms',
              value: totalQuantity.toString(),
              context: context,
            ),
            if (!isReservation) ...[

              _buildInfoTile(icon: Icons.person_outline, label: 'Adults', value: adults.toString(), context: context),
              _buildInfoTile(icon: Icons.child_care, label: 'Children', value: children.toString(), context: context),
              _buildInfoTile(icon: Icons.calendar_today_outlined, label: 'Check-In', value: getFormattedDate(checkInDate), context: context),
              _buildInfoTile(icon: Icons.calendar_today_outlined, label: 'Check-Out', value: getFormattedDate(checkOutDate), context: context),
            ],
          ],
        ),
        const SizedBox(height: 24),
        
        _buildSection(
          title: 'Price Breakdown',
          children: [
            _buildInfoTile(
              icon: Icons.receipt_outlined,
              label: 'Item Price',
              value: NumberFormat.currency(
                locale: 'en_US',
                symbol: 'Tsh ',
                decimalDigits: 2,
              ).format(totalPrice * itemCount),
              valueColor: Theme.of(context).primaryColor,
              context: context,
            ),
            if (isReservation)
              _buildInfoTile(
                icon: Icons.local_shipping_outlined,
                label: 'Delivery Cost',
                value: deliveryCost.contains('Tsh')
                    ? NumberFormat.currency(
                        locale: 'sw_TZ',
                        symbol: 'Tsh ',
                        decimalDigits: 2,
                      ).format(double.parse(deliveryCost.replaceAll('Tsh ', '').trim()))
                    : 'Calculating...',
                context: context,
              ),
            if (isReservation)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildInfoTile(
                  icon: Icons.payment_outlined,
                  label: 'Total Amount',
                  value: deliveryCost.contains('Tsh')
                      ? NumberFormat.currency(
                          locale: 'sw_TZ',
                          symbol: 'Tsh ',
                          decimalDigits: 2,
                        ).format(totalPrice * itemCount +
                          double.parse(deliveryCost.replaceAll('Tsh ', '').trim()))
                      : 'Calculating...',
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  context: context,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Icon(icon, size: 20),),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: valueStyle ?? TextStyle(
                    fontSize: 15,
                    color: valueColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: labelStyle ?? const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}