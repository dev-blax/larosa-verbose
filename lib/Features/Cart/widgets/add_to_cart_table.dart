import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:flutter/cupertino.dart';

class AddToCartTable extends StatelessWidget {
  final bool isReservation;
  final String? currentStreetName;
  final int itemCount;
  final int adults;
  final int children;
  final double price;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String deliveryCost;
  final String estimatedTime;
  final String? transportCost;
  final String? deliveryDuration;
  final double? exchangeRate;
  final Function(int) onAdultQuantityChanged;
  final Function(int) onChildQuantityChanged;
  final Function(BuildContext) pickCheckInDate;
  final Function(BuildContext) pickCheckOutDate;
  final Function(DateTime) getFormattedDate;
  final Function(String) getFormattedTime;
  final Function(int) onQuantityChanged;

  const AddToCartTable({
    super.key,
    required this.isReservation,
    required this.currentStreetName,
    required this.itemCount,
    required this.adults,
    required this.children,
    required this.price,
    required this.checkInDate,
    required this.checkOutDate,
    required this.deliveryCost,
    required this.estimatedTime,
    required this.transportCost,
    required this.deliveryDuration,
    required this.exchangeRate,
    required this.onAdultQuantityChanged,
    required this.onChildQuantityChanged,
    required this.pickCheckInDate,
    required this.pickCheckOutDate,
    required this.getFormattedDate,
    required this.getFormattedTime,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    //final secondaryColor = isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? CupertinoColors.darkBackgroundGray : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isReservation) ...[
              _buildInfoRow(
                context,
                'Delivery Location',
                currentStreetName ?? 'N/A',
                icon: CupertinoIcons.location,
                primaryColor: primaryColor,
              ),
              _buildDivider(),
            ],
            _buildInfoRow(
              context,
              isReservation ? 'Quantity' : 'Rooms',
              '$itemCount @${HelperFunctions.formatPrice(price)}/=',
              icon: isReservation ? CupertinoIcons.number : CupertinoIcons.bed_double,
              primaryColor: primaryColor,
              //customWidget: _buildQuantitySelector(context, itemCount, primaryColor),
            ),
            if (!isReservation) ...[
              _buildDivider(),
              _buildSliderRow(
                context,
                'Adults',
                adults,
                1,
                20,
                onAdultQuantityChanged,
                icon: CupertinoIcons.person_2,
                primaryColor: primaryColor,
              ),
              _buildDivider(),
              _buildSliderRow(
                context,
                'Children',
                children,
                0,
                20,
                onChildQuantityChanged,
                icon: CupertinoIcons.person_2,
                primaryColor: primaryColor,
              ),
              _buildDivider(),
              _buildDateRow(
                context,
                'Check-In',
                checkInDate,
                () => pickCheckInDate(context),
                getFormattedDate,
                primaryColor: primaryColor,
              ),
              _buildDivider(),
              _buildDateRow(
                context,
                'Check-Out',
                checkOutDate,
                () => pickCheckOutDate(context),
                getFormattedDate,
                primaryColor: primaryColor,
              ),
            ],
            if (isReservation) ...[
              _buildDivider(),
              _buildInfoRow(
                context,
                'Estimated Time',
                estimatedTime.contains('min')
                    ? getFormattedTime(estimatedTime)
                    : 'Calculating...',
                icon: CupertinoIcons.time,
                primaryColor: primaryColor,
              ),
              _buildDivider(),
              _buildInfoRow(
                context,
                'Delivery Cost',
                (deliveryCost.contains('Tsh') && exchangeRate != null)
                    ? 'Tsh ${HelperFunctions.formatPrice(double.parse(deliveryCost.replaceAll('Tsh ', '').trim()))}/='
                    : 'Calculating...',
                icon: CupertinoIcons.money_dollar,
                primaryColor: primaryColor,
              ),
            ],
            _buildDivider(),
            _buildInfoRow(
              context,
              'Product(s) Price',
              'Tsh ${HelperFunctions.formatPrice(price * itemCount)}/=',
              icon: CupertinoIcons.tag,
              primaryColor: primaryColor,
              isHighlighted: true,
            ),
            if (isReservation) ...[
              _buildDivider(),
              _buildInfoRow(
                context,
                'Total Price',
                (deliveryCost.contains('Tsh') && exchangeRate != null)
                    ? 'Tsh ${HelperFunctions.formatPrice(price * itemCount + double.parse(deliveryCost.replaceAll('Tsh ', '').trim()))}/='
                    : 'Calculating...',
                icon: CupertinoIcons.money_dollar_circle,
                primaryColor: primaryColor,
                isHighlighted: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Color? primaryColor,
    bool isHighlighted = false,
    Widget? customWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: primaryColor?.withOpacity(0.8)),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: primaryColor?.withOpacity(0.8),
                    fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isHighlighted ? 16 : 15,
                    color: primaryColor,
                    fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          if (customWidget != null) ...[
            const SizedBox(height: 8),
            customWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    BuildContext context,
    String label,
    int value,
    int min,
    int max,
    Function(int) onChanged, {
    IconData? icon,
    Color? primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: primaryColor?.withOpacity(0.8)),
                const SizedBox(width: 12),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: primaryColor?.withOpacity(0.8),
                ),
              ),
              const Spacer(),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 15,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CupertinoSlider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: (newValue) {
              onChanged(newValue.toInt());
              HapticFeedback.selectionClick();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(
    BuildContext context,
    String label,
    DateTime? date,
    VoidCallback onTap,
    Function(DateTime) formatter, {
    Color? primaryColor,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onPressed: onTap,
      child: Row(
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 20,
            color: primaryColor?.withOpacity(0.8),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: primaryColor?.withOpacity(0.8),
            ),
          ),
          const Spacer(),
          Text(
            date == null ? 'Tap to Set' : formatter(date),
            style: TextStyle(
              fontSize: 15,
              color: date == null ? CupertinoColors.systemBlue : primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(BuildContext context, int quantity, Color? primaryColor) {
    final quickAddValues = [20, 50, 100];
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: quantity > 1 
                  ? () {
                      onQuantityChanged(quantity - 1);
                      HapticFeedback.selectionClick();
                    }
                  : null,
              child: Icon(
                CupertinoIcons.minus_circle_fill,
                color: quantity > 1 
                    ? primaryColor 
                    : primaryColor?.withOpacity(0.3),
                size: 24,
              ),
            ),
            GestureDetector(
              onTap: () => _showQuantityPicker(context, quantity),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: primaryColor?.withOpacity(0.2) ?? CupertinoColors.systemGrey4,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  quantity.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                onQuantityChanged(quantity + 1);
                HapticFeedback.selectionClick();
              },
              child: Icon(
                CupertinoIcons.plus_circle_fill,
                color: primaryColor,
                size: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final value in quickAddValues)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: primaryColor?.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () {
                      onQuantityChanged(quantity + value);
                      HapticFeedback.mediumImpact();
                    },
                    child: Text(
                      '+$value',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showQuantityPicker(BuildContext context, int currentQuantity) {
    final textController = TextEditingController(text: currentQuantity.toString());
    
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter Quantity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: textController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              onSubmitted: (value) {
                final newQuantity = int.tryParse(value);
                if (newQuantity != null && newQuantity >= 1) {
                  onQuantityChanged(newQuantity);
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    final newQuantity = int.tryParse(textController.text);
                    if (newQuantity != null && newQuantity >= 1) {
                      onQuantityChanged(newQuantity);
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5);
  }
}
