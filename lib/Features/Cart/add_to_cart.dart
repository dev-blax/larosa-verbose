// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:gap/gap.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:go_router/go_router.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:larosa_block/Features/Cart/Models/product_model.dart';
// import 'package:larosa_block/Features/Cart/controllers/cart_controller.dart';
// import 'package:larosa_block/Services/log_service.dart';
// import 'dart:ui';
// import 'package:geolocator/geolocator.dart';
// import 'package:provider/provider.dart';

// import '../../Components/cart_button.dart';
// import '../../Components/PaymentModals/payment_method_modal.dart';
// import '../../Components/wavy_border_clipper.dart';
// import '../../Utils/colors.dart';

// class AddToCartScreen extends StatefulWidget {
//   final String username;
//   final double price;
//   final String names;
//   final int postId;

//   const AddToCartScreen({
//     super.key,
//     required this.username,
//     required this.price,
//     required this.names,
//     required this.postId,
//   });

//   @override
//   State<AddToCartScreen> createState() => _AddToCartScreenState();
// }

// class _AddToCartScreenState extends State<AddToCartScreen> {
//   int itemCount = 1;
//   final TextEditingController _typeAheadController = TextEditingController();
//   Position? _currentPosition;
//   String? selectedStreetName;
//   String? currentStreetName;

//   double? latitude;
//   double? longitude;

//   Future<void> _getCurrentLocation() async {
//   bool serviceEnabled;
//   LocationPermission permission;

//   serviceEnabled = await Geolocator.isLocationServiceEnabled();
//   if (!serviceEnabled) {
//     return Future.error('Location services are disabled.');
//   }

//   permission = await Geolocator.checkPermission();
//   if (permission == LocationPermission.denied) {
//     permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) {
//       return Future.error('Location permissions are denied');
//     }
//   }

//   if (permission == LocationPermission.deniedForever) {
//     return Future.error(
//         'Location permissions are permanently denied, we cannot request permissions.');
//   }

//   final position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high);

//   setState(() {
//     _currentPosition = position;
//   });

//   // Fetch the full street name using reverse geocoding
//   try {
//     List<Placemark> placemarks = await placemarkFromCoordinates(
//       position.latitude,
//       position.longitude,
//     );
//     if (placemarks.isNotEmpty) {
//       Placemark place = placemarks[0];
//       setState(() {
//         currentStreetName =
//             '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
//       });
//     }
//   } catch (e) {
//     print('Error: $e');
//   }
// }

//   // Future<List<Map<String, String>>> _getPlaceSuggestions(String input) async {
//   //   final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
//   //   const String baseUrl =
//   //       'https://maps.googleapis.com/maps/api/place/autocomplete/json';
//   //   final url = '$baseUrl?input=$input&key=$apiKey&components=country:tz';

//   //   final response = await http.get(Uri.parse(url));
//   //   if (response.statusCode == 200) {
//   //     final json = jsonDecode(response.body);
//   //     final suggestions = (json['predictions'] as List)
//   //         .map((prediction) => {
//   //               'description': prediction['description'] as String,
//   //               'place_id': prediction['place_id'] as String,
//   //             })
//   //         .toList();
//   //     return suggestions;
//   //   } else {
//   //     throw Exception('Failed to load suggestions');
//   //   }
//   // }

//   Future<List<Map<String, String>>> _getPlaceSuggestions(String input) async {
//   final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
//   const String baseUrl =
//       'https://maps.googleapis.com/maps/api/place/autocomplete/json';
//   final url = '$baseUrl?input=$input&key=$apiKey&components=country:tz';

//   try {
//     final response = await http.get(Uri.parse(url));
//     if (response.statusCode == 200) {
//       final json = jsonDecode(response.body);
//       final suggestions = (json['predictions'] as List)
//           .map((prediction) => {
//                 'description': prediction['description'] as String,
//                 'place_id': prediction['place_id'] as String,
//               })
//           .toList();
//       return suggestions.isNotEmpty
//           ? suggestions
//           : [
//               {'description': 'No results found', 'place_id': ''}
//             ];
//     } else {
//       LogService.logError('Error fetching suggestions: ${response.body}');
//       return [
//         {'description': 'Failed to fetch locations. Please try again.', 'place_id': ''}
//       ];
//     }
//   } catch (e) {
//     LogService.logError('Error fetching suggestions: $e');
//     return [
//       {'description': 'Failed to fetch locations. Please check your connection.', 'place_id': ''}
//     ];
//   }
// }

//   Future<void> _getPlaceDetails(String placeId) async {
//     final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
//     const String detailsUrl =
//         'https://maps.googleapis.com/maps/api/place/details/json';
//     final url = '$detailsUrl?place_id=$placeId&key=$apiKey';

//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final json = jsonDecode(response.body);
//         if (json['result'] != null && json['result']['geometry'] != null) {
//           final location = json['result']['geometry']['location'];
//           final address = json['result']['formatted_address'];
//           final lat = location['lat'];
//           final lng = location['lng'];

//           setState(() {
//             latitude = lat;
//             longitude = lng;
//             selectedStreetName = address;
//           });
//         }
//       }
//     } catch (e) {
//       LogService.logError('Error: $e');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     _getCurrentLocation();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cartNotifier = Provider.of<CartController>(context);
//     List<String> imageUrls = widget.names.split(',');
//     double totalPrice = widget.price * itemCount;

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           onPressed: () => context.pop(),
//           icon: const Icon(
//             Iconsax.arrow_left_2,
//           ),
//         ),
//         title: const Text('Add To Cart', style: TextStyle(fontSize: 16),),
//         centerTitle: true,
//       ),
//       body: ListView(
//         children: [
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: imageUrls.map((imageUrl) {
//                 return CachedNetworkImage(
//                   imageUrl: imageUrl.trim(),
//                   height: 500,
//                   progressIndicatorBuilder: (context, url, downloadProgress) =>
//                       const SpinKitCircle(
//                     color: Colors.blue,
//                   ),
//                   errorWidget: (context, url, error) => const Icon(Icons.error),
//                 );
//               }).toList(),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Display individual price and count
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Unit Price: ${NumberFormat.currency(locale: 'en_US', symbol: 'Tsh ', decimalDigits: 2).format(widget.price)}',
//                       style: const TextStyle(
//                           fontSize: 15, fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       'Quantity: $itemCount',
//                       style: const TextStyle(
//                           fontSize: 15, fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//                 const Gap(10),
//                 // Total Price Calculation
//                 Center(
//                   child: Text(
//                     'Total Price: ${NumberFormat.currency(locale: 'en_US', symbol: 'Tsh ', decimalDigits: 2).format(totalPrice)}',
//                     style: const TextStyle(
//                         fontSize: 15, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 const Gap(10),
//                 // Display current location if available
//                 // Table for Current Location
//                 if (_currentPosition != null)
//                   Table(
//                     border:
//                         TableBorder.all(color: LarosaColors.primary, width: 1),
//                     children: [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text(
//                               'Current Location',
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Now, 12 Jan 2024'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Latitude'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text('${_currentPosition!.latitude}'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Longitude'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text('${_currentPosition!.longitude}'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Street Name'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text(currentStreetName ?? 'N/A'),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),

//                 const Gap(20),

//                 if (latitude != null &&
//                     longitude != null &&
//                     selectedStreetName != null)
//                   Table(
//                     border: TableBorder.all(color: Colors.purple, width: 1),
//                     children: [
//                       const TableRow(
//                         children: [
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text(
//                               'Delivery Destination',
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                           Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Approx 2300, 12 Oct 2024'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Latitude'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text('$latitude'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Longitude'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text('$longitude'),
//                           ),
//                         ],
//                       ),
//                       TableRow(
//                         children: [
//                           const Padding(
//                             padding: EdgeInsets.all(8.0),
//                             child: Text('Street Name'),
//                           ),
//                           Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Text('$selectedStreetName'),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),

//                 const Gap(15),

//                 // Delivery Destination TextField
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Delivery Destination',
//                       style:
//                           TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.info_outline, color: Colors.grey),
//                       onPressed: () {
//                         showDialog(
//                           context: context,
//                           builder: (BuildContext context) {
//                             return AlertDialog(
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15.0),
//                               ),
//                               title: const Text('Location Information'),
//                               content: const Text(
//                                 'When location permission is granted:\n\n'
//                                 '1. If no delivery destination is selected, your current location will be used automatically.\n'
//                                 '2. If both a delivery destination and your current location are available, the delivery destination will be used.\n'
//                                 '3. If your current location is not available, you will need to search for and select a delivery destination manually.\n\n'
//                                 'By allowing location permission, the app can auto-fill your location for a seamless experience.',
//                                 style: TextStyle(fontSize: 14),
//                               ),
//                               actions: [
//                                 TextButton(
//                                   onPressed: () {
//                                     Navigator.of(context).pop();
//                                   },
//                                   child: const Text('OK'),
//                                 ),
//                               ],
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ],
//                 ),

//                 const Gap(10),
//                 // TypeAheadField<Map<String, String>>(
//                 //   suggestionsCallback: _getPlaceSuggestions,
//                 //   itemBuilder: (context, Map<String, String> suggestion) {
//                 //     return ListTile(
//                 //       title: Text(suggestion['description']!),
//                 //     );
//                 //   },
//                 //   onSelected: (Map<String, String> suggestion) async {
//                 //     // Automatically fill the form field with the selected suggestion
//                 //     _typeAheadController.text = suggestion['description']!;
//                 //     final placeId = suggestion['place_id']!;
//                 //     await _getPlaceDetails(placeId);
//                 //   },
//                 //   direction: VerticalDirection.up,
//                 //   builder: (context, controller, focusNode) {
//                 //     return TextField(
//                 //       controller: controller,
//                 //       focusNode: focusNode,
//                 //       decoration: const InputDecoration(
//                 //         labelText: 'Enter delivery destination',
//                 //         border: OutlineInputBorder(),
//                 //         prefixIcon: Icon(Iconsax.location),
//                 //       ),
//                 //     );
//                 //   },
//                 //   controller:
//                 //       _typeAheadController, // Make sure to assign the controller here
//                 // ),

//                 TypeAheadField<Map<String, String>>(
//   suggestionsCallback: _getPlaceSuggestions,
//   itemBuilder: (context, Map<String, String> suggestion) {
//     // Display the suggestion or fallback message
//     if (suggestion['place_id'] == '') {
//       // Center the fallback error message
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 10.0),
//           child: Text(
//             suggestion['description']!,
//             style: const TextStyle(
//               fontSize: 14,
//               color: Colors.grey,
//               fontStyle: FontStyle.italic,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       );
//     }
//     // Display normal suggestions
//     return ListTile(
//       title: Text(suggestion['description']!),
//     );
//   },
//   onSelected: (Map<String, String> suggestion) async {
//     if (suggestion['place_id'] != '') {
//       // Automatically fill the form field with the selected suggestion
//       _typeAheadController.text = suggestion['description']!;
//       final placeId = suggestion['place_id']!;
//       await _getPlaceDetails(placeId);
//     } else {
//       // Log invalid selection or take no action
//       LogService.logInfo('Invalid selection: ${suggestion['description']}');
//     }
//   },
//   direction: VerticalDirection.up,
//   builder: (context, controller, focusNode) {
//     return TextField(
//       controller: controller,
//       focusNode: focusNode,
//       decoration: const InputDecoration(
//         labelText: 'Enter delivery destination',
//         border: OutlineInputBorder(),
//         prefixIcon: Icon(Iconsax.location),
//       ),
//     );
//   },
//   controller: _typeAheadController,
// ),

//                 const Gap(25),

//                 buildQuantityAdjustmentRow(),

//                 const Gap(20),

//                 // Confirm Order Button
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Expanded(
//                       child: buildWideGradientButton(
//                         onTap: () {
//                           showModalBottomSheet(
//                             context: context,
//                             shape: const RoundedRectangleBorder(
//                               borderRadius: BorderRadius.vertical(
//                                 top: Radius.circular(20),
//                               ),
//                             ),
//                             isScrollControlled: true,
//                             builder: (BuildContext context) {
//                               return FractionallySizedBox(
//                                 heightFactor: 0.95,
//                                 child: PaymentMethodModal(
//                                   currentPosition: _currentPosition,
//                                   deliveryDestination: selectedStreetName,
//                                   deliveryLatitude: latitude,
//                                   deliveryLongitude: longitude,
//                                   totalPrice: widget.price * itemCount,
//                                   quantity: itemCount,
//                                   postId: widget.postId,
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                         label: 'Buy Now',
//                         startColor: LarosaColors.secondary,
//                         endColor: LarosaColors.purple,
//                       ),
//                     ),
//                     const SizedBox(
//                         width: 70), // Add some spacing between the buttons
//                     Expanded(
//                       child: buildWideGradientButton(
//                         onTap: () {
//                           // Handle add to cart

//                           Product newProduct = Product(
//                             id: '2',
//                             imageUrl: '',
//                             name: 'Product Name',
//                             price: 2500,
//                             shortDescription: 'Some description',
//                             quantity: 20,
//                           );

//                           cartNotifier.addProduct(newProduct);

//                           context.push('/maincart');
//                         },
//                         label: 'Add to Cart',
//                         startColor: LarosaColors.secondary,
//                         endColor: LarosaColors.purple,
//                       ),
//                     ),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildQuantityAdjustmentRow() {
//     return ClipPath(
//       clipper: WavyBorderClipper(),
//       child: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               LarosaColors.secondary,
//               LarosaColors.secondary,
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         padding: const EdgeInsets.only(top: 8.0, bottom: 30),
//         child: Column(
//           children: [
//             const Gap(10),
//             // Decrease Buttons
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount = (itemCount - 1 < 1) ? 1 : itemCount - 1;
//                       });
//                     },
//                     label: '-1',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                   const Gap(6),
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount = (itemCount - 5 < 1) ? 1 : itemCount - 5;
//                       });
//                     },
//                     label: '-5',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                   const Gap(6),
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount = (itemCount - 10 < 1) ? 1 : itemCount - 10;
//                       });
//                     },
//                     label: '-10',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                   const Gap(6),
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount = (itemCount - 20 < 1) ? 1 : itemCount - 20;
//                       });
//                     },
//                     label: '-20',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                   const Gap(6),
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount = (itemCount - 50 < 1) ? 1 : itemCount - 50;
//                       });
//                     },
//                     label: '-50',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                   const Gap(6),
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount = (itemCount - 100 < 1) ? 1 : itemCount - 100;
//                       });
//                     },
//                     label: '-100',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                 ],
//               ),
//             ),
//             const Gap(5),
//             // Increase Buttons
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount++;
//                       });
//                     },
//                     label: '+1',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                   const Gap(6),
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount += 5;
//                       });
//                     },
//                     label: '+5',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                   const Gap(6),
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount += 10;
//                       });
//                     },
//                     label: '+10',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                   const Gap(6),
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount += 20;
//                       });
//                     },
//                     label: '+20',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                   const Gap(6),
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount += 50;
//                       });
//                     },
//                     label: '+50',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                   const Gap(6),
//                   buildGradientButton(
//                     onTap: () {
//                       setState(() {
//                         itemCount += 100;
//                       });
//                     },
//                     label: '+100',
//                     startColor: LarosaColors.primary,
//                     endColor: LarosaColors.purple,
//                   ),
//                 ],
//               ),
//             ),
//             const Gap(10),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:larosa_block/Features/Cart/Models/product_model.dart';
import 'package:larosa_block/Features/Cart/controllers/cart_controller.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../Components/cart_button.dart';
import '../../Components/PaymentModals/payment_method_modal.dart';
import '../../Components/wavy_border_clipper.dart';
import '../../Services/auth_service.dart';
import '../../Utils/colors.dart';
import '../../Utils/links.dart';

class AddToCartScreen extends StatefulWidget {
  final String username;
  final double price;
  final String names;
  final int postId;

  const AddToCartScreen({
    super.key,
    required this.username,
    required this.price,
    required this.names,
    required this.postId,
  });

  @override
  State<AddToCartScreen> createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  int itemCount = 1;
  final TextEditingController _typeAheadController = TextEditingController();
  Position? _currentPosition;
  String? selectedStreetName;
  String? currentStreetName;

  double? latitude;
  double? longitude;

  bool _isLoadingLocation = true; // Add a state to track loading

  String? transportCost;
  String? deliveryDuration;
  // bool _isFetchingTransportCost = false;

  String deliveryCost = 'Calculating...';
  String estimatedTime = 'Calculating...';

  double? _exchangeRate;
  String _deliveryCostTSh = 'Calculating...';

  // Future<void> _getCurrentLocation() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     return Future.error('Location services are disabled.');
  //   }

  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       return Future.error('Location permissions are denied');
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     return Future.error(
  //         'Location permissions are permanently denied, we cannot request permissions.');
  //   }

  //   final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);

  //   setState(() {
  //     _currentPosition = position;
  //   });

  //   // Fetch the full street name using reverse geocoding
  //   try {
  //     List<Placemark> placemarks = await placemarkFromCoordinates(
  //       position.latitude,
  //       position.longitude,
  //     );
  //     if (placemarks.isNotEmpty) {
  //       Placemark place = placemarks[0];
  //       setState(() {
  //         currentStreetName =
  //             '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';
  //       });
  //     }
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }

  // Future<void> _getCurrentLocation() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     return Future.error('Location services are disabled.');
  //   }

  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       return Future.error('Location permissions are denied');
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     return Future.error(
  //         'Location permissions are permanently denied, we cannot request permissions.');
  //   }

  //   final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);

  //   setState(() {
  //     _currentPosition = position;
  //     latitude = position.latitude;
  //     longitude = position.longitude;
  //   });

  //   // Fetch the full street name using reverse geocoding
  //   try {
  //     List<Placemark> placemarks = await placemarkFromCoordinates(
  //       position.latitude,
  //       position.longitude,
  //     );
  //     if (placemarks.isNotEmpty) {
  //       Placemark place = placemarks[0];
  //       final streetName =
  //           '${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}';

  //       setState(() {
  //         currentStreetName = streetName;
  //         selectedStreetName = streetName;

  //         // Update the destination input field
  //         _typeAheadController.text = streetName;
  //       });
  //     }
  //   } catch (e) {
  //     print('Error: $e');
  //   }
  // }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentPosition = position;
        latitude = position.latitude;
        longitude = position.longitude;
        if (placemarks.isNotEmpty) {
          currentStreetName =
              '${placemarks[0].street}, ${placemarks[0].locality}';
          selectedStreetName = currentStreetName;
          _typeAheadController.text = currentStreetName ?? '';
        }
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      LogService.logError('Error fetching location: $e');
    }
  }

  Future<void> fetchTransportCost() async {
    final Uri uri = Uri.https(
      'burnished-core-439210-f6.uc.r.appspot.com',
      '/api/v1/transport-cost/calculate',
    );

    if (latitude == null || longitude == null) {
      setState(() {
        deliveryCost = 'Error: Missing destination data';
        estimatedTime = 'Error: Missing destination data';
      });
      return;
    }

    // Fixed pickup location
    const double pickupLat = -6.125649;
    const double pickupLng = 35.79266299999999;

    // Request body with fixed pickup location
    final Map<String, dynamic> requestBody = {
      "startLat": pickupLat,
      "startLng": pickupLng,
      "endLat": latitude!,
      "endLng": longitude!,
    };

    try {
      String token = AuthService.getToken();

      if (token == null) {
        throw Exception('Token is missing. Please log in again.');
      }

      final http.Response response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final double distance = (data['distance'] as num?)?.toDouble() ?? 0.0;
        final double motorcycleCost =
            (data['motorcycleCost'] as num?)?.toDouble() ?? 0.0;

        setState(() {
          deliveryCost = motorcycleCost > 0
              ? 'Tsh ${motorcycleCost.toStringAsFixed(2)}'
              : 'Unavailable';
          estimatedTime =
              distance > 0 ? '${(distance * 10).toInt()} min' : 'Unavailable';
        });
      } else {
        setState(() {
          deliveryCost = 'Error';
          estimatedTime = 'Error';
        });
      }
    } catch (error) {
      setState(() {
        deliveryCost = 'Error';
        estimatedTime = 'Error';
      });
      LogService.logError('Error in fetchTransportCost: $error');
    }
  }

  // Future<List<Map<String, String>>> _getPlaceSuggestions(String input) async {
  //   final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
  //   const String baseUrl =
  //       'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  //   final url = '$baseUrl?input=$input&key=$apiKey&components=country:tz';

  //   final response = await http.get(Uri.parse(url));
  //   if (response.statusCode == 200) {
  //     final json = jsonDecode(response.body);
  //     final suggestions = (json['predictions'] as List)
  //         .map((prediction) => {
  //               'description': prediction['description'] as String,
  //               'place_id': prediction['place_id'] as String,
  //             })
  //         .toList();
  //     return suggestions;
  //   } else {
  //     throw Exception('Failed to load suggestions');
  //   }
  // }

  Future<List<Map<String, String>>> _getPlaceSuggestions(String input) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
    const String baseUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    final url = '$baseUrl?input=$input&key=$apiKey&components=country:tz';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final suggestions = (json['predictions'] as List)
            .map((prediction) => {
                  'description': prediction['description'] as String,
                  'place_id': prediction['place_id'] as String,
                })
            .toList();
        return suggestions.isNotEmpty
            ? suggestions
            : [
                {'description': 'No results found', 'place_id': ''}
              ];
      } else {
        LogService.logError('Error fetching suggestions: ${response.body}');
        return [
          {
            'description': 'Failed to fetch locations. Please try again.',
            'place_id': ''
          }
        ];
      }
    } catch (e) {
      LogService.logError('Error fetching suggestions: $e');
      return [
        {
          'description':
              'Failed to fetch locations. Please check your connection.',
          'place_id': ''
        }
      ];
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
    const String detailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json';
    final url = '$detailsUrl?place_id=$placeId&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['result'] != null && json['result']['geometry'] != null) {
          final location = json['result']['geometry']['location'];
          final address = json['result']['formatted_address'];
          final lat = location['lat'];
          final lng = location['lng'];

          setState(() {
            latitude = lat;
            longitude = lng;
            selectedStreetName = address;
          });
        }
      }
    } catch (e) {
      LogService.logError('Error: $e');
    }
  }

  Future<void> _fetchExchangeRate() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.exchangerate-api.com/v4/latest/USD')); // API for exchange rates

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if TZS rate is available
        if (data['rates'] != null && data['rates']['TZS'] != null) {
          setState(() {
            _exchangeRate = data['rates']['TZS']; // Extract TZS rate
            print('exchange rate $_exchangeRate');
          });

          // Convert delivery cost to TZS after fetching the rate
          // _convertDeliveryCost();
        } else {
          setState(() {
            _deliveryCostTSh = 'TZS rate unavailable';
          });
        }
      } else {
        setState(() {
          _deliveryCostTSh = 'Error fetching exchange rate';
        });
      }
    } catch (e) {
      setState(() {
        _deliveryCostTSh = 'Error: $e';
      });
    }
  }

  String formatEstimatedTime(String estimatedTime) {
    final int minutes =
        int.tryParse(estimatedTime.replaceAll('min', '').trim()) ?? 0;
    if (minutes >= 60) {
      final int hours = minutes ~/ 60; // Calculate the number of full hours
      final int remainingMinutes = minutes % 60; // Calculate remaining minutes
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}min'; // Return as minutes if less than 60
    }
  }

//   void _convertDeliveryCost() {
//   if (_exchangeRate != null && double.tryParse(deliveryCost) != null) {
//     final double parsedDeliveryCost = double.parse(deliveryCost);

//     final double deliveryCostTSh = parsedDeliveryCost * _exchangeRate!;

//     setState(() {
//       _deliveryCostTSh = NumberFormat.currency(
//         locale: 'sw_TZ',
//         symbol: 'TSh ',
//         decimalDigits: 2,
//       ).format(deliveryCostTSh);
//       print('Converted Delivery Cost: $deliveryCostTSh');
//       print('Exchange Rate: $_exchangeRate');
//     });
//   } else {
//     print('Error: Invalid deliveryCost or exchange rate');
//   }
// }

  @override
  void initState() {
    super.initState();
    // _getCurrentLocation();
    _fetchExchangeRate();
    _getCurrentLocation().then((_) => fetchTransportCost());
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = Provider.of<CartController>(context);
    List<String> imageUrls = widget.names.split(',');
    // double totalPrice = widget.price * itemCount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Iconsax.arrow_left_2,
          ),
        ),
        title: const Text(
          'Add To Cart',
          style: TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: imageUrls.map((imageUrl) {
                return CachedNetworkImage(
                  imageUrl: imageUrl.trim(),
                  height: 500,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      const SpinKitCircle(
                    color: Colors.blue,
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display individual price and count
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Text(
                //       'Unit Price: ${NumberFormat.currency(locale: 'en_US', symbol: 'Tsh ', decimalDigits: 2).format(widget.price)}',
                //       style: const TextStyle(
                //           fontSize: 15, fontWeight: FontWeight.bold),
                //     ),
                //     Text(
                //       'Quantity: $itemCount',
                //       style: const TextStyle(
                //           fontSize: 15, fontWeight: FontWeight.bold),
                //     ),
                //   ],
                // ),
                // const Gap(10),
                // // Total Price Calculation
                // Center(
                //   child: Text(
                //     'Total Price: ${NumberFormat.currency(locale: 'en_US', symbol: 'Tsh ', decimalDigits: 2).format(totalPrice)}',
                //     style: const TextStyle(
                //         fontSize: 15, fontWeight: FontWeight.bold),
                //   ),
                // ),
                const Gap(10),
                // Display current location if available
                // Table for Current Location

                if (_isLoadingLocation)
                  _buildLoadingShimmer(context)
                else if (_currentPosition != null)
                  Table(
                    border: TableBorder.all(
                      width: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[600]!
                          : Colors.grey[400]!,
                    ),
                    children: [
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Delivery Location',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(currentStreetName ?? 'N/A'),
                          ),
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
                            child: Text('$itemCount'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Estimated Time',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              estimatedTime.contains('min')
                                  ? formatEstimatedTime(estimatedTime)
                                  : 'Calculating...',
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Delivery Cost (Tsh)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 4),
                            // child: Text(
                            //   // Display the converted delivery cost
                            //   (deliveryCost.contains('Tsh') &&
                            //           _exchangeRate != null)
                            //       ? 'Tsh ${(double.parse(deliveryCost.replaceAll('Tsh ', '').trim()) * _exchangeRate!).toStringAsFixed(2)}'
                            //       : 'Calculating...',
                            // ),
                            child: Text(
                              // Display the formatted delivery cost
                              (deliveryCost.contains('Tsh') &&
                                      _exchangeRate != null)
                                  ? NumberFormat.currency(
                                      locale: 'sw_TZ',
                                      symbol: '',
                                      decimalDigits: 2, // No decimal points
                                    ).format(
                                      double.parse(deliveryCost
                                              .replaceAll('Tsh ', '')
                                              .trim()) *
                                          _exchangeRate!,
                                    )
                                  : 'Calculating...',
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Item Price (Tsh)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              NumberFormat.currency(
                                      locale: 'en_US',
                                      symbol: '',
                                      decimalDigits: 2)
                                  .format(widget.price * itemCount),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Total Price (Tsh)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 4),
                            child: Text(
                              deliveryCost.contains('Tsh') &&
                                      _exchangeRate != null
                                  ? NumberFormat.currency(
                                      locale: 'sw_TZ',
                                      symbol:
                                          '', // Omit the symbol here to manually add "TSh"
                                      decimalDigits:
                                          2, // Two decimal points for formatting
                                    ).format(
                                      widget.price * itemCount +
                                          double.parse(deliveryCost
                                              .replaceAll('Tsh ', '')
                                              .trim()) + // Add base delivery cost
                                          double.parse(deliveryCost
                                                  .replaceAll('Tsh ', '')
                                                  .trim()) *
                                              _exchangeRate!, // Add exchange-rate-adjusted delivery cost
                                    )
                                  : 'Calculating...',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                const Gap(10),

                // if (latitude != null &&
                //     longitude != null &&
                //     selectedStreetName != null)
                //   Table(
                //     border: TableBorder.all(color: Colors.purple, width: 1),
                //     children: [
                //       const TableRow(
                //         children: [
                //           Padding(
                //             padding: EdgeInsets.all(8.0),
                //             child: Text(
                //               'Delivery Destination',
                //               style: TextStyle(fontWeight: FontWeight.bold),
                //             ),
                //           ),
                //           Padding(
                //             padding: EdgeInsets.all(8.0),
                //             child: Text('Approx 2300, 12 Oct 2024'),
                //           ),
                //         ],
                //       ),
                //       TableRow(
                //         children: [
                //           const Padding(
                //             padding: EdgeInsets.all(8.0),
                //             child: Text('Latitude'),
                //           ),
                //           Padding(
                //             padding: const EdgeInsets.all(8.0),
                //             child: Text('$latitude'),
                //           ),
                //         ],
                //       ),
                //       TableRow(
                //         children: [
                //           const Padding(
                //             padding: EdgeInsets.all(8.0),
                //             child: Text('Longitude'),
                //           ),
                //           Padding(
                //             padding: const EdgeInsets.all(8.0),
                //             child: Text('$longitude'),
                //           ),
                //         ],
                //       ),
                //       TableRow(
                //         children: [
                //           const Padding(
                //             padding: EdgeInsets.all(8.0),
                //             child: Text('Street Name'),
                //           ),
                //           Padding(
                //             padding: const EdgeInsets.all(8.0),
                //             child: Text('$selectedStreetName'),
                //           ),
                //         ],
                //       ),
                //     ],
                //   ),

                // const Gap(5),

                const Divider(),
                const Gap(0),

                // Delivery Destination TextField
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Destination',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.grey),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              title: const Text('Location Information'),
                              content: const Text(
                                'When location permission is granted:\n\n'
                                '1. If no delivery destination is selected, your current location will be used automatically.\n'
                                '2. If both a delivery destination and your current location are available, the delivery destination will be used.\n'
                                '3. If your current location is not available, you will need to search for and select a delivery destination manually.\n\n'
                                'By allowing location permission, the app can auto-fill your location for a seamless experience.',
                                style: TextStyle(fontSize: 14),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                const Gap(10),
                // TypeAheadField<Map<String, String>>(
                //   suggestionsCallback: _getPlaceSuggestions,
                //   itemBuilder: (context, Map<String, String> suggestion) {
                //     return ListTile(
                //       title: Text(suggestion['description']!),
                //     );
                //   },
                //   onSelected: (Map<String, String> suggestion) async {
                //     // Automatically fill the form field with the selected suggestion
                //     _typeAheadController.text = suggestion['description']!;
                //     final placeId = suggestion['place_id']!;
                //     await _getPlaceDetails(placeId);
                //   },
                //   direction: VerticalDirection.up,
                //   builder: (context, controller, focusNode) {
                //     return TextField(
                //       controller: controller,
                //       focusNode: focusNode,
                //       decoration: const InputDecoration(
                //         labelText: 'Enter delivery destination',
                //         border: OutlineInputBorder(),
                //         prefixIcon: Icon(Iconsax.location),
                //       ),
                //     );
                //   },
                //   controller:
                //       _typeAheadController, // Make sure to assign the controller here
                // ),

                // TypeAheadField<Map<String, String>>(
                //   suggestionsCallback: _getPlaceSuggestions,
                //   itemBuilder: (context, Map<String, String> suggestion) {
                //     // Display the suggestion or fallback message
                //     if (suggestion['place_id'] == '') {
                //       // Center the fallback error message
                //       return Center(
                //         child: Padding(
                //           padding: const EdgeInsets.symmetric(vertical: 10.0),
                //           child: Text(
                //             suggestion['description']!,
                //             style: const TextStyle(
                //               fontSize: 14,
                //               color: Colors.grey,
                //               fontStyle: FontStyle.italic,
                //             ),
                //             textAlign: TextAlign.center,
                //           ),
                //         ),
                //       );
                //     }
                //     // Display normal suggestions
                //     return ListTile(
                //       title: Text(suggestion['description']!),
                //     );
                //   },
                //   onSelected: (Map<String, String> suggestion) async {
                //     if (suggestion['place_id'] != '') {
                //       // Automatically fill the form field with the selected suggestion
                //       _typeAheadController.text = suggestion['description']!;
                //       final placeId = suggestion['place_id']!;
                //       await _getPlaceDetails(placeId);
                //     } else {
                //       // Log invalid selection or take no action
                //       LogService.logInfo(
                //           'Invalid selection: ${suggestion['description']}');
                //     }
                //   },
                //   direction: VerticalDirection.up,
                //   builder: (context, controller, focusNode) {
                //     return TextField(
                //       controller: controller,
                //       focusNode: focusNode,
                //       decoration: const InputDecoration(
                //         labelText: 'Enter delivery destination',
                //         border: OutlineInputBorder(),
                //         prefixIcon: Icon(Iconsax.location),
                //       ),
                //     );
                //   },
                //   controller: _typeAheadController,
                // ),

                TypeAheadField<Map<String, String>>(
                  suggestionsCallback: _getPlaceSuggestions,
                  itemBuilder: (context, Map<String, String> suggestion) {
                    if (suggestion['place_id'] == '') {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            suggestion['description']!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return ListTile(
                      title: Text(suggestion['description']!),
                    );
                  },
                  onSelected: (Map<String, String> suggestion) async {
                    if (suggestion['place_id'] != '') {
                      _typeAheadController.text = suggestion['description']!;
                      final placeId = suggestion['place_id']!;
                      await _getPlaceDetails(placeId);

                      setState(() {
                        currentStreetName = suggestion['description'];
                        selectedStreetName = suggestion['description'];
                      });

                      fetchTransportCost(); // Fetch transport cost for the new destination
                    } else {
                      LogService.logInfo(
                          'Invalid selection: ${suggestion['description']}');
                    }
                  },
                  direction: VerticalDirection.up,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Enter delivery destination',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Iconsax.location),
                      ),
                    );
                  },
                  controller: _typeAheadController,
                ),

                const Gap(10),

                const Divider(),

                const Gap(5),

                buildQuantityAdjustmentRow(),

                const Divider(),
                const Gap(5),

                // Confirm Order Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Expanded(
                    //   child: buildWideGradientButton(
                    //     onTap: () {
                    //       showModalBottomSheet(
                    //         context: context,
                    //         shape: const RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.vertical(
                    //             top: Radius.circular(20),
                    //           ),
                    //         ),
                    //         isScrollControlled: true,
                    //         builder: (BuildContext context) {
                    //           return FractionallySizedBox(
                    //             heightFactor: 0.95,
                    //             child: PaymentMethodModal(
                    //               currentPosition: _currentPosition,
                    //               deliveryDestination: selectedStreetName,
                    //               deliveryLatitude: latitude,
                    //               deliveryLongitude: longitude,
                    //               totalPrice: widget.price * itemCount,
                    //               quantity: itemCount,
                    //               postId: widget.postId,
                    //             ),
                    //           );
                    //         },
                    //       );
                    //     },
                    //     label: 'Buy Now',
                    //     startColor: LarosaColors.secondary,
                    //     endColor: LarosaColors.purple,
                    //   ),
                    // ),

                    Expanded(
                      child: deliveryCost.contains('Tsh')
                          ? buildWideGradientButton(
                              onTap: () {
                                final totalPrice = widget.price * itemCount +
                                    double.parse(deliveryCost
                                        .replaceAll('Tsh ', '')
                                        .trim()) +
                                    double.parse(deliveryCost
                                            .replaceAll('Tsh ', '')
                                            .trim()) *
                                        _exchangeRate!; // Total price calculation

                                showModalBottomSheet(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  isScrollControlled: true,
                                  builder: (BuildContext context) {
                                    return FractionallySizedBox(
                                      heightFactor: 0.95,
                                      child: PaymentMethodModal(
                                        currentPosition: _currentPosition,
                                        deliveryDestination: selectedStreetName,
                                        deliveryLatitude: latitude,
                                        deliveryLongitude: longitude,
                                        totalPrice: totalPrice,
                                        quantity: itemCount,
                                        postId: widget.postId,
                                      ),
                                    );
                                  },
                                );
                              },
                              label:
                                  'Buy Now', // Show label when deliveryCost is loaded
                              startColor: LarosaColors.secondary,
                              endColor: LarosaColors.purple,
                            )
                          : const Center(
                              child: CupertinoActivityIndicator(
                                radius: 10.0, // Adjust the size as needed
                              ),
                            ),
                    ),

                    const SizedBox(
                        width: 70), // Add some spacing between the buttons
                    Expanded(
                      child: buildWideGradientButton(
                        onTap: () {
                          // Handle add to cart

                          Product newProduct = Product(
                            id: '2',
                            imageUrl: '',
                            name: 'Product Name',
                            price: 2500,
                            shortDescription: 'Some description',
                            quantity: 20,
                          );

                          cartNotifier.addProduct(newProduct);

                          context.push('/maincart');
                        },
                        label: 'Add to Cart',
                        startColor: LarosaColors.secondary,
                        endColor: LarosaColors.purple,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQuantityAdjustmentRow() {
    return Container(
      decoration: const BoxDecoration(
          // gradient: LinearGradient(
          //   colors: [
          //     LarosaColors.secondary,
          //     LarosaColors.secondary,
          //   ],
          //   begin: Alignment.topLeft,
          //   end: Alignment.bottomRight,
          // ),
          ),
      padding: const EdgeInsets.only(top: 8.0, bottom: 10),
      child: Column(
        children: [
          // const Gap(10),
          // Decrease Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 1 < 1) ? 1 : itemCount - 1;
                    });
                  },
                  label: '-1',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 5 < 1) ? 1 : itemCount - 5;
                    });
                  },
                  label: '-5',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 10 < 1) ? 1 : itemCount - 10;
                    });
                  },
                  label: '-10',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 20 < 1) ? 1 : itemCount - 20;
                    });
                  },
                  label: '-20',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 50 < 1) ? 1 : itemCount - 50;
                    });
                  },
                  label: '-50',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 100 < 1) ? 1 : itemCount - 100;
                    });
                  },
                  label: '-100',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
              ],
            ),
          ),
          const Gap(5),
          // Increase Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount++;
                    });
                  },
                  label: '+1',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount += 5;
                    });
                  },
                  label: '+5',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount += 10;
                    });
                  },
                  label: '+10',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount += 20;
                    });
                  },
                  label: '+20',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount += 50;
                    });
                  },
                  label: '+50',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount += 100;
                    });
                  },
                  label: '+100',
                  startColor: LarosaColors.primary.withOpacity(1),
                  endColor: LarosaColors.purple.withOpacity(1),
                ),
              ],
            ),
          ),
          // const Gap(10),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[300]!,
              highlightColor:
                  isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
