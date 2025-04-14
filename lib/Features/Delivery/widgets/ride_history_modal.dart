import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:larosa_block/Utils/colors.dart';

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
      // You can uncomment this decoration if needed.
      // decoration: BoxDecoration(
      //   gradient: LinearGradient(
      //     colors: [
      //       LarosaColors.primary.withOpacity(0.9),
      //       LarosaColors.purple.withOpacity(0.9),
      //     ],
      //     begin: Alignment.topLeft,
      //     end: Alignment.bottomRight,
      //   ),
      //   borderRadius: const BorderRadius.only(
      //     topLeft: Radius.circular(20),
      //     topRight: Radius.circular(20),
      //   ),
      // ),
      padding: EdgeInsets.only(
        top: Platform.isIOS ? 50 : 24,
        left: 4,
        right: 4,
        bottom: 8,
      ),
      child: Column(
        children: [
          // Custom header with a creative close button.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48), // To balance the close button on the right.
              Text(
                'Ride History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: LarosaColors.light,
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: LarosaColors.light,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: LarosaColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(
            color: Colors.white54,
            thickness: 1,
          ),
          const SizedBox(height: 8),
          // Expanded list area.
          Expanded(
            child: rideHistory.isEmpty
                ? Center(
                    child: Text(
                      "No ride history available",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: LarosaColors.light,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: rideHistory.length,
                    itemBuilder: (context, index) {
                      final ride = rideHistory[index];
                      return _creativeRideCard(context, ride);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _creativeRideCard(BuildContext context, Map ride) {
    // Helper method for formatting number amounts with commas.
    String formatAmount(num amount) {
      return amount
          .toStringAsFixed(0)
          .replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }

    // Define a common border style for each cell.
    final cellBorder = TableBorder.all(
      color: Colors.grey.withOpacity(0.5),
      width: 1,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LarosaColors.secondary.withOpacity(0.7),
            LarosaColors.purple.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: LarosaColors.light,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Decorative header for Ride ID.
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [LarosaColors.secondary, LarosaColors.purple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Ride ID: ${ride['rideId']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Single table for all ride details with borders.
              Table(
                border: cellBorder,
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                },
                children: [
                  // Row 1: Status and Timestamp.
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Status: ${ride['rideStatus']}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ride['rideStatus'] == 'COMPLETED'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ride['startTime'] != null
                              ? Text(
                                  formatDateTime(ride['startTime']),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                )
                              : Container(),
                        ),
                      ),
                    ],
                  ),
                  // Row 2: Driver and Vehicle Info.
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(Icons.person,
                                  size: 20, color: LarosaColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${ride['driverFirstName']} ${ride['driverLastName']}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.directions_car,
                                  size: 20, color: LarosaColors.secondary),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "${ride['vehicleType']} (${ride['licensePlate']})",
                                  style: const TextStyle(fontSize: 14),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Row 3: Total Fare.
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "Total Fare:",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Tsh ${ride['totalFare']}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: LarosaColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Row 4: Start and End Times.
                  if (ride['startTime'] != null || ride['endTime'] != null)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: ride['startTime'] != null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.play_circle_fill,
                                      size: 18,
                                      color: LarosaColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        "Start: ${formatDateTime(ride['startTime'])}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: ride['endTime'] != null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "End: ${formatDateTime(ride['endTime'])}",
                                        style: const TextStyle(fontSize: 13),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.stop_circle,
                                      size: 18,
                                      color: LarosaColors.secondary,
                                    ),
                                  ],
                                )
                              : Container(),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
