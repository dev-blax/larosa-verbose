import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import '../../Utils/colors.dart';
import '../../Utils/helpers.dart';
import 'payment_processing_modal.dart';

class PaymentMethodModal extends StatelessWidget {
  final List<Map<String, String>> paymentMethods = [
    {'type': 'Bank', 'name': 'CRDB Bank', 'value': 'CRDB'},
    {'type': 'Bank', 'name': 'NMB Bank', 'value': 'NMB'},
    {'type': 'Mobile', 'name': 'Airtel Money', 'value': 'Airtel'},
    {'type': 'Mobile', 'name': 'Tigo Pesa', 'value': 'Tigo'},
    {'type': 'Mobile', 'name': 'Halopesa', 'value': 'Halopesa'},
    {'type': 'Mobile', 'name': 'Azampesa', 'value': 'Azampesa'},
    {'type': 'Mobile', 'name': 'M-Pesa', 'value': 'Mpesa'},
  ];

  final Position? currentPosition;
  final String? deliveryDestination;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double totalPrice;
  final int quantity;
  final List<int> postId;

  final int adults; // New parameter
  final int children; // New parameter
  final String fullName; // New parameter
  final bool isReservation; // New parameter

 final DateTime? checkInDate; // Allow null values
final DateTime? checkOutDate; // Allow null values


  final List<Map<String, dynamic>> items;

  PaymentMethodModal({
    super.key,
    required this.currentPosition,
    required this.deliveryDestination,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.totalPrice,
    required this.quantity,
    required this.postId,
    required this.adults, // Initialize in constructor
    required this.children, // Initialize in constructor
    required this.fullName, // Initialize in constructor
    required this.isReservation,
    required this.items,
    required this.checkInDate,
    required this.checkOutDate, // Initialize in constructor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      padding: const EdgeInsets.all(8.0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 5),
          const Center(
            child: Text(
              'Order Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: Colors.purple, width: 1),
            children: getTableRows(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank Payments Section
                const Text(
                  'Bank Payments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: MediaQuery.of(context).size.height * .1,
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          (MediaQuery.of(context).size.width / 150).floor(),
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: paymentMethods
                        .where((method) => method['type'] == 'Bank')
                        .length,
                    itemBuilder: (context, index) {
                      final method = paymentMethods
                          .where((method) => method['type'] == 'Bank')
                          .toList()[index];
                      return Card(
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () {
                            final String? destination = deliveryDestination
                                        ?.isNotEmpty ==
                                    true
                                ? deliveryDestination
                                : '${currentPosition?.latitude}, ${currentPosition?.longitude}';

                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => PaymentProcessingModal(
                                paymentMethod: method['value']!,
                                paymentType: method['type']!,
                                totalPrice: totalPrice,
                                quantity: quantity,
                                postId: postId,
                                items: items,
                                deliveryLatitude: deliveryLatitude,
                                deliveryLongitude: deliveryLongitude,
                                deliveryDestination: destination,
                                currentLatitude: deliveryLatitude == null
                                    ? currentPosition?.latitude
                                    : null,
                                currentLongitude: deliveryLongitude == null
                                    ? currentPosition?.longitude
                                    : null,

                                adults: adults, // Pass adults parameter
                                children: children, // Pass children parameter
                                fullName: fullName, // Pass fullName parameter
                                checkInDate: checkInDate,
                                checkOutDate: checkOutDate,
                                isReservation:
                                    isReservation, // Pass isReservation parameter
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  LarosaColors.secondary,
                                  LarosaColors.purple,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Iconsax.bank,
                                      color: Colors
                                          .white), // Change icon color if needed
                                  const SizedBox(height: 8.0),
                                  Text(
                                    method['name']!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      color: Colors
                                          .white, // Adjust text color for better contrast
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                // Mobile Payments Section
                const Text(
                  'Mobile Payments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  // height: deliveryDestination?.isNotEmpty == true
                  //     ? MediaQuery.of(context).size.height * .25
                  //     : MediaQuery.of(context).size.height * .40,
                  height: MediaQuery.of(context).size.height * .4,
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          (MediaQuery.of(context).size.width / 150).floor(),
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: paymentMethods
                        .where((method) => method['type'] == 'Mobile')
                        .length,
                    itemBuilder: (context, index) {
                      final method = paymentMethods
                          .where((method) => method['type'] == 'Mobile')
                          .toList()[index];
                      return Card(
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () {
                            final String? destination = deliveryDestination
                                        ?.isNotEmpty ==
                                    true
                                ? deliveryDestination
                                : '${currentPosition?.latitude}, ${currentPosition?.longitude}';

                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => PaymentProcessingModal(
                                paymentMethod: method['value']!,
                                paymentType: method['type']!,
                                totalPrice: totalPrice,
                                quantity: quantity,
                                postId: postId,
                                items: items,
                                deliveryLatitude: deliveryLatitude,
                                deliveryLongitude: deliveryLongitude,
                                deliveryDestination: destination,
                                currentLatitude: deliveryLatitude == null
                                    ? currentPosition?.latitude
                                    : null,
                                currentLongitude: deliveryLongitude == null
                                    ? currentPosition?.longitude
                                    : null,

                                adults: adults, // Pass adults parameter
                                children: children, // Pass children parameter
                                fullName: fullName, // Pass fullName parameter
                                checkInDate: checkInDate,
                                checkOutDate: checkOutDate,
                                isReservation:
                                    isReservation, // Pass isReservation parameter
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  LarosaColors.secondary,
                                  LarosaColors.purple,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Iconsax.mobile,
                                    color: Colors
                                        .white, // Adjust the icon color for contrast
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    method['name']!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      color: Colors
                                          .white, // Adjust text color for better contrast
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
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

  List<TableRow> getTableRows() {
    return [
      // if (currentPosition?.latitude != null &&
      //     currentPosition?.longitude != null)
      //   TableRow(
      //     children: [
      //       const Padding(
      //         padding: EdgeInsets.all(8.0),
      //         child: Text(
      //           'Current Location',
      //           style: TextStyle(fontWeight: FontWeight.bold),
      //         ),
      //       ),
      //       Padding(
      //         padding: const EdgeInsets.all(8.0),
      //         child: Text(
      //           '${currentPosition!.latitude}, ${currentPosition!.longitude}',
      //         ),
      //       ),
      //     ],
      //   ),
      if (deliveryDestination != null && deliveryDestination!.isNotEmpty)
        TableRow(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Delivery Destination (Street)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(deliveryDestination!),
            ),
          ],
        ),
      // if (deliveryLatitude != null)
      //   TableRow(
      //     children: [
      //       const Padding(
      //         padding: EdgeInsets.all(8.0),
      //         child: Text(
      //           'Delivery Latitude',
      //           style: TextStyle(fontWeight: FontWeight.bold),
      //         ),
      //       ),
      //       Padding(
      //         padding: const EdgeInsets.all(8.0),
      //         child: Text('$deliveryLatitude'),
      //       ),
      //     ],
      //   ),
      // if (deliveryLongitude != null)
      //   TableRow(
      //     children: [
      //       const Padding(
      //         padding: EdgeInsets.all(8.0),
      //         child: Text(
      //           'Delivery Longitude',
      //           style: TextStyle(fontWeight: FontWeight.bold),
      //         ),
      //       ),
      //       Padding(
      //         padding: const EdgeInsets.all(8.0),
      //         child: Text('$deliveryLongitude'),
      //       ),
      //     ],
      //   ),
      TableRow(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Total Price',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Tsh ${HelperFunctions.formatPrice(totalPrice)}')),
        ],
      ),
      TableRow(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Quantity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('$quantity'),
          ),
        ],
      ),
      // TableRow(
      //   children: [
      //     const Padding(
      //       padding: EdgeInsets.all(8.0),
      //       child: Text(
      //         'Post ID',
      //         style: TextStyle(fontWeight: FontWeight.bold),
      //       ),
      //     ),
      //     Padding(
      //       padding: const EdgeInsets.all(8.0),
      //       child: Text('$postId'),
      //     ),
      //   ],
      // ),
    ];
  }
}
