import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Function(BuildContext) pickCheckInDate;
  final Function(BuildContext) pickCheckOutDate;
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
    required this.pickCheckInDate,
    required this.pickCheckOutDate,
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
              ),
              _buildInfoTile(
                icon: Icons.timer_outlined,
                label: 'Estimated Time',
                value: estimatedTime.contains('min')
                    ? formatEstimatedTime(estimatedTime)
                    : 'Calculating...',
              ),
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
            ),
            if (!isReservation) ...[
              _buildSliderTile(
                icon: Icons.person_outline,
                label: 'Adults',
                value: adults,
                min: 1,
                max: 20,
                onChanged: onAdultsChanged,
                context: context,
              ),
              _buildSliderTile(
                icon: Icons.child_care,
                label: 'Children',
                value: children,
                min: 0,
                max: 20,
                onChanged: onChildrenChanged,
                context: context,
              ),
              _buildDateTile(
                icon: Icons.calendar_today_outlined,
                label: 'Check-In',
                date: checkInDate,
                onTap: () => pickCheckInDate(context),
                context: context,
              ),
              _buildDateTile(
                icon: Icons.calendar_today_outlined,
                label: 'Check-Out',
                date: checkOutDate,
                onTap: () => pickCheckOutDate(context),
                context: context,
              ),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: labelStyle ?? const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: valueStyle ?? TextStyle(
                    fontSize: 15,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String label,
    required int value,
    required double min,
    required double max,
    required Function(int) onChanged,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: min,
                    max: max,
                    divisions: max.toInt(),
                    activeColor: isDark ? Colors.white : Colors.black,
                    inactiveColor: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
                    onChanged: (value) {
                      onChanged(value.toInt());
                      HapticFeedback.lightImpact();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile({
    required IconData icon,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date == null ? 'Select Date' : getFormattedDate(date),
                    style: TextStyle(
                      fontSize: 15,
                      color: date == null
                          ? (isDark ? Colors.grey[400] : Colors.grey[600])
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}