import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RideHistoryModal extends StatelessWidget {
  final List<dynamic> rideHistory;

  const RideHistoryModal({super.key, required this.rideHistory});

  String formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final parsedDate = DateTime.parse(dateTime);
      return DateFormat('yyyy-MM-dd hh:mm a').format(parsedDate);
    } catch (e) {
      return dateTime; // Fallback to original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 18, left: 8, right: 8),
      child: Column(
        children: [
          // Close button at the top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(''),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: rideHistory.isEmpty
                ? const Center(
                    child: Text(
                      "No ride history available",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  )
                : ListView.builder(
                    itemCount: rideHistory.length,
                    itemBuilder: (context, index) {
                      final ride = rideHistory[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Ride ID: ${ride['rideId']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ride['rideStatus'] == 'COMPLETED'
                                          ? Colors.green
                                          : Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      ride['rideStatus'],
                                      style: TextStyle(
                                        color: ride['rideStatus'] == 'COMPLETED'
                                            ? Colors.white
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.person,
                                      size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${ride['driverFirstName']} ${ride['driverLastName']}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.directions_car,
                                      size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${ride['vehicleType']} (${ride['licensePlate']})",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money,
                                      size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Total Fare: Tsh ${ride['totalFare']}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              // Row(
                              //   children: [
                              //     const Icon(Icons.location_on,
                              //         size: 20, color: Colors.grey),
                              //     const SizedBox(width: 8),
                              //     Expanded(
                              //       child: Column(
                              //         crossAxisAlignment: CrossAxisAlignment.start,
                              //         children: [
                              //           Text(
                              //             "Pickup: ${ride['pickupLatitude']}, ${ride['pickupLongitude']}",
                              //             style: const TextStyle(fontSize: 13),
                              //           ),
                              //           const SizedBox(height: 4),
                              //           Text(
                              //             "Dropoff: ${ride['dropoffLatitude']}, ${ride['dropoffLongitude']}",
                              //             style: const TextStyle(fontSize: 13),
                              //           ),
                              //         ],
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              if (ride['startTime'] != null ||
                                  ride['endTime'] != null)
                                Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 20, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (ride['startTime'] != null)
                                                Text(
                                                  "Start Time: ${formatDateTime(ride['startTime'])}",
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              if (ride['endTime'] != null)
                                                Text(
                                                  "End Time: ${formatDateTime(ride['endTime'])}",
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}