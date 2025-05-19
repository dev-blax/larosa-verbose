import 'package:flutter/material.dart';
import '../models/ride_model.dart';

class RideTypeSelector extends StatelessWidget {
  final RideType selectedRideType;
  final Function(RideType) onRideTypeSelected;

  const RideTypeSelector({
    super.key,
    required this.selectedRideType,
    required this.onRideTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Ride Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRideTypeOption(
                  context,
                  RideType.economy,
                  'Economy',
                  'Budget Friendly',
                  Icons.directions_car,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRideTypeOption(
                  context,
                  RideType.comfort,
                  'Comfort',
                  'Premium Vehicles',
                  Icons.airport_shuttle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRideTypeOption(
                  context,
                  RideType.boda,
                  'Boda',
                  'Quick & Agile',
                  Icons.motorcycle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideTypeOption(
    BuildContext context,
    RideType type,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = selectedRideType == type;
    return GestureDetector(
      onTap: () => onRideTypeSelected(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
