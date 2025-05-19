import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ride_controller.dart';
import '../models/ride_model.dart';

class DriverCard extends StatefulWidget {
  final DriverModel driver;

  const DriverCard({
    super.key,
    required this.driver,
  });

  @override
  State<DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<DriverCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.directions_car,
                  'Vehicle',
                  widget.driver.vehicleType,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.confirmation_number,
                  'Plate',
                  widget.driver.vehicleNumber,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.access_time,
                  'Arrival',
                  '${widget.driver.estimatedArrivalTimeInMinutes} min',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CupertinoButton.tinted(
                  onPressed: () {
                    context.read<RideController>().acceptVehicle();
                  },
                  child: const Text('Accept Vehicle'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
