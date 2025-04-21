// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:ionicons/ionicons.dart';
// import 'package:gap/gap.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:larosa_block/Components/bottom_navigation.dart';
// import 'package:larosa_block/Services/auth_service.dart';
// import 'package:larosa_block/Services/log_service.dart';
// import 'package:larosa_block/Utils/helpers.dart';
// import 'package:larosa_block/Utils/links.dart';
// import 'package:stomp_dart_client/stomp_dart_client.dart';

// import '../../Utils/colors.dart';
// import 'explore_services.dart';
// import 'map_service.dart';
// import 'time_estimations_modal_content.dart';
// import 'widgets/ride_history_modal.dart';

// class NewDelivery extends StatefulWidget {
//   const NewDelivery({super.key});

//   @override
//   State<NewDelivery> createState() => _NewDeliveryState();
// }

// class _NewDeliveryState extends State<NewDelivery> {
//   final TextEditingController _sourceController = TextEditingController();
//   final TextEditingController _destinationController = TextEditingController();
//   String? selectedSourceStreetName;
//   double? sourceLatitude;
//   double? sourceLongitude;
//   String? selectedDestinationStreetName;
//   double? destinationLatitude;
//   double? destinationLongitude;
//   bool isLoadingSource = false;
//   bool isLoadingDestination = false;
//   String paymentMethod = 'CASH';
//   String vehicleType = 'MOTORCYCLE';
//   List<dynamic> orders = [];
//   late StompClient stompClient;
//   final String socketChannel =
//       '${LarosaLinks.baseurl}/ws/topic/customer/${AuthService.getProfileId()}';

//   bool isFetchingTimeEstimations = false;

//   bool isLoading = true; // Track loading state

//   Future<void> _asyncInit() async {
//     // await _socketConnection2();
//     // await _updateCurrentCityFromLocation();
//     // _connectToStomp();
//     _loadOrders();
//   }

//   @override
//   void initState() {
//     super.initState();
//     _asyncInit();

//     _loadRideHistory();

//     if (destinationLatitude != null && destinationLongitude != null) {
//       _updateDestinationMarker(destinationLatitude!, destinationLongitude!);
//     }
//   }

//   void _updateMarker(double latitude, double longitude) {
//     setState(() {
//       _markers
//           .removeWhere((marker) => marker.markerId.value == 'dynamic_marker');
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('dynamic_marker'),
//           position: LatLng(latitude, longitude),
//           infoWindow: const InfoWindow(title: 'Driver Location'),
//         ),
//       );
//     });
//   }

//   bool isRequestingRide = false;

//   Future<Map<String, dynamic>> estimateTimeForAllVehicles({
//     required double customerLatitude,
//     required double customerLongitude,
//     required double destinationLatitude,
//     required double destinationLongitude,
//   }) async {
//     const String endpoint =
//         '${LarosaLinks.baseurl}/api/v1/ride-customer/time-estimation';
//     Map<String, String> headers = {
//       "Content-Type": "application/json",
//       "Access-Control-Allow-Origin": "*",
//       'Authorization': 'Bearer ${AuthService.getToken()}',
//     };

//     final Map<String, dynamic> requestBody = {
//       "customerLatitude": customerLatitude,
//       "customerLongitude": customerLongitude,
//       "destinationLatitude": destinationLatitude,
//       "destinationLongitude": destinationLongitude,
//     };

//     try {
//       final response = await http.post(
//         Uri.parse(endpoint),
//         headers: headers,
//         body: jsonEncode(requestBody),
//       );
// // print("frs ${response.statusCode}");
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         LogService.logInfo("Time Estimation Response: ${response.body}");
//         return jsonDecode(response.body);
//       } else {
//         LogService.logError(
//             "Failed to fetch time estimation: ${response.statusCode}");
//         return {
//           "error":
//               "Failed to fetch time estimation. Status code: ${response.statusCode}"
//         };
//       }
//     } catch (e) {
//       LogService.logError("Error estimating time: $e");
//       return {"error": "An error occurred while estimating time: $e"};
//     }
//   }

//   String formatTime(double minutes) {
//     int hours = (minutes / 60).floor();
//     int mins = (minutes % 60).round();
//     if (hours > 0) {
//       return "$hours hr ${mins > 0 ? '$mins min' : ''}";
//     } else {
//       return "$mins min";
//     }
//   }

//   final Set<Marker> _markers = {}; // Holds the map markers

//   void _updateDriverMarker(double latitude, double longitude) {
//     setState(() {
//       _markers.removeWhere((marker) =>
//           marker.markerId.value == 'driver'); // Remove existing driver marker
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('driver'),
//           position: LatLng(latitude, longitude),
//           infoWindow: const InfoWindow(title: 'Driver Location'),
//         ),
//       );
//     });
//   }

//   void _updateDestinationMarker(double latitude, double longitude) {
//     setState(() {
//       _markers.removeWhere((marker) =>
//           marker.markerId.value ==
//           'destination'); // Remove existing destination marker
//       _markers.add(
//         Marker(
//           markerId: const MarkerId('destination'),
//           position: LatLng(latitude, longitude),
//           infoWindow: const InfoWindow(title: 'Destination'),
//         ),
//       );
//     });
//   }

//   void showTimeEstimationsModal(
//       BuildContext context, Map<String, dynamic> estimations) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (BuildContext context) {
//         return TimeEstimationsModalContent(
//           estimations: estimations,
//           sourceLatitude: sourceLatitude!,
//           sourceLongitude: sourceLongitude!,
//           destinationLatitude: destinationLatitude!,
//           destinationLongitude: destinationLongitude!,
//         );
//       },
//     );
//   }

//   Future<Map<String, String>> getCountryAndCity(double latitude, double longitude) async {
//   try {
//     List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
//     if (placemarks.isNotEmpty) {
//       Placemark place = placemarks[0];
//       LogService.logDebug('Geocoding Result: $place');
//       return {
//         "country": place.country ?? "Unknown",
//         // Return locality if available, otherwise fallback to administrativeArea
//         "city": place.locality ?? place.administrativeArea ?? "Unknown",
//       };
//     }
//   } catch (e) {
//     LogService.logError('Error in getCountryAndCity: $e');
//   }
//   return {"country": "Unknown", "city": "Unknown"};
// }

//   Future<void> fetchTimeEstimations() async {
//   if (sourceLatitude == null ||
//       sourceLongitude == null ||
//       destinationLatitude == null ||
//       destinationLongitude == null) {
//     HelperFunctions.showToast(
//       "Please enter pickup and destination locations",
//       true,
//     );
//     return;
//   }

//   setState(() {
//     isFetchingTimeEstimations = true; // Start loading
//   });

//   // Get country and city name from source coordinates for the API request.
//   final placeDetails = await getCountryAndCity(sourceLatitude!, sourceLongitude!);
//   final String country = placeDetails["country"] ?? "Unknown";
//   final String cityName = placeDetails["city"] ?? "Unknown";

//   const String endpoint = '${LarosaLinks.baseurl}/api/v1/transport-cost/calculate';
//   Map<String, String> headers = {
//     "Content-Type": "application/json",
//     "Access-Control-Allow-Origin": "*",
//     'Authorization': 'Bearer ${AuthService.getToken()}',
//   };

//   final Map<String, dynamic> requestBody = {
//     "startLat": sourceLatitude,
//     "startLng": sourceLongitude,
//     "endLat": destinationLatitude,
//     "endLng": destinationLongitude,
//     "country": country,
//     "cityName": cityName,
//   };
// print("frs 123 : $requestBody");
//   try {
//     final response = await http.post(
//       Uri.parse(endpoint),
//       headers: headers,
//       body: jsonEncode(requestBody),
//     );

//     setState(() {
//       isFetchingTimeEstimations = false; // Stop loading
//     });

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       final Map<String, dynamic> estimations = jsonDecode(response.body);

//       // Check if pickupDuration is 0 for all vehicle types
//       bool allDriversBusy = estimations["vehicleEstimations"]
//           .every((estimation) => estimation["pickupDuration"] == 0);

//       if (allDriversBusy) {
//         // HelperFunctions.showToast(
//         //   "Drivers are currently busy. Please refresh the request after a minute for updated pricing and availability.",
//         //   true,
//         // );

//         HelperFunctions.displayInfo(
//   context,
//   "Our system is experiencing high demand at the moment. Please hold on while we secure the best available driver for you. Your comfort and safety are our top priority."
// );

//       } else {
//         showTimeEstimationsModal(context, estimations);
//       }
//     } else {
//       HelperFunctions.showToast(
//         "Failed to fetch transport cost. Status code: ${response.statusCode}",
//         true,
//       );
//     }
//   } catch (e) {
//     setState(() {
//       isFetchingTimeEstimations = false;
//     });
//     LogService.logError("Error calculating transport cost: $e");
//     HelperFunctions.showToast("An error occurred while calculating transport cost", true);
//   }
// }

//   Future<List<Map<String, String>>> _getPlaceSuggestions(String input) async {
//     final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
//     const String baseUrl =
//         'https://maps.googleapis.com/maps/api/place/autocomplete/json';
//     final url = '$baseUrl?input=$input&key=$apiKey&components=country:tz';

//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final json = jsonDecode(response.body);

//         // Parse the predictions and ensure all values are strings
//         final suggestions = (json['predictions'] as List)
//             .map((prediction) {
//               // Extract region from the terms
//               final terms = prediction['terms'] as List;
//               final region =
//                   terms.length > 1 ? terms[1]['value'] as String : '';

//               return {
//                 'description': prediction['description'] as String,
//                 'place_id': prediction['place_id'] as String,
//                 'region': region,
//               };
//             })
//             .toList()
//             .cast<
//                 Map<String,
//                     String>>(); // Ensure the type is List<Map<String, String>>

//         return suggestions.isNotEmpty
//             ? suggestions
//             : [
//                 {
//                   'description': 'No results found.',
//                   'place_id': '',
//                   'region': ''
//                 }
//               ];
//       } else {
//         return [
//           {
//             'description': 'Failed to fetch locations. Please try again.',
//             'place_id': '',
//             'region': ''
//           }
//         ];
//       }
//     } catch (e) {
//       LogService.logError('Error fetching suggestions: $e');
//       return [
//         {
//           'description':
//               'Failed to fetch locations. Please check your connection.',
//           'place_id': '',
//           'region': ''
//         }
//       ];
//     }
//   }

//   Future<void> _getPlaceDetails(String placeId, bool isSource) async {
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
//             if (isSource) {
//               sourceLatitude = lat;
//               sourceLongitude = lng;
//               selectedSourceStreetName = address;
//               // Don't overwrite _sourceController.text here
//               isLoadingSource = false;
//             } else {
//               destinationLatitude = lat;
//               destinationLongitude = lng;
//               selectedDestinationStreetName = address;
//               // Don't overwrite _destinationController.text here
//               isLoadingDestination = false;
//             }
//           });
//         }
//       }
//     } catch (e) {
//       setState(() {
//         isLoadingSource = false;
//         isLoadingDestination = false;
//       });
//       LogService.logError('Error: $e');
//     }
//   }

//   Future<void> _loadOrders() async {
//     String token = AuthService.getToken();
//     LogService.logDebug('token $token');
//     Map<String, String> headers = {
//       "Content-Type": "application/json",
//       "Access-Control-Allow-Origin": "*",
//       'Authorization': 'Bearer $token',
//     };

//     var url = Uri.parse('${LarosaLinks.baseurl}/api/v1/orders/history');

//     try {
//       final response = await http.get(
//         url,
//         headers: headers,
//       );
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         LogService.logFatal('success');
//         LogService.logInfo(response.body);
//         setState(() {
//           orders = jsonDecode(response.body);
//           // Reverse the orders
//           orders = orders.reversed.toList();
//         });
//         return;
//       }

//       LogService.logError('error: ${response.statusCode}');
//     } catch (e) {
//       LogService.logError('failed $e');
//     }
//   }

//   List<dynamic> rideHistory = [];

//   Future<void> _loadRideHistory() async {
//     String token = AuthService.getToken();
//     LogService.logDebug('token $token');
//     Map<String, String> headers = {
//       "Content-Type": "application/json",
//       "Access-Control-Allow-Origin": "*",
//       'Authorization': 'Bearer $token',
//     };

//     var url = Uri.parse('${LarosaLinks.baseurl}/api/v1/ride-customer/rides');

//     try {
//       final response = await http.get(
//         url,
//         headers: headers,
//       );
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         LogService.logFatal('Ride history fetch successful');
//         LogService.logInfo(response.body);

//         setState(() {
//           rideHistory = jsonDecode(response.body);
//         });

//         return;
//       }

//       LogService.logError(
//           'Error fetching ride history: ${response.statusCode}');
//     } catch (e) {
//       LogService.logError('Failed to fetch ride history: $e');
//     }
//   }

//   Future<void> _getCurrentLocation(bool isSource) async {
//     setState(() {
//       if (isSource) {
//         isLoadingSource = true;
//       } else {
//         isLoadingDestination = true;
//       }
//     });

//     try {
//       LocationPermission permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         setState(() {
//           isLoadingSource = false;
//           isLoadingDestination = false;
//         });
//         return;
//       }

//       Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high);

//       List<Placemark> placemarks =
//           await placemarkFromCoordinates(position.latitude, position.longitude);

//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks[0];
//         String region = place.administrativeArea ?? 'Unknown Region';
//         String country = place.country ?? 'Unknown Country';
//         String address = '${place.name}, $region, $country';

//         setState(() {
//           if (isSource) {
//             sourceLatitude = position.latitude;
//             sourceLongitude = position.longitude;
//             selectedSourceStreetName = address;
//             _sourceController.text = address;
//             isLoadingSource = false;
//           } else {
//             destinationLatitude = position.latitude;
//             destinationLongitude = position.longitude;
//             selectedDestinationStreetName = address;
//             _destinationController.text = address;
//             isLoadingDestination = false;
//           }
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoadingSource = false;
//         isLoadingDestination = false;
//       });
//       LogService.logError('Error: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         automaticallyImplyLeading: false,
//         title: const Text(
//           'Delivery',
//           style: TextStyle(fontSize: 18),
//         ),
//         // centerTitle: true,
//         actions: [
//           // Other action buttons can go here
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Container(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [LarosaColors.secondary, LarosaColors.purple],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 shape: BoxShape.circle,
//               ),
//               child: IconButton(
//                 icon: const Icon(
//                   Icons.explore,
//                   color: Colors.white,
//                 ),
//                 onPressed: () {
//                   // When clicked, open the explore modal
//                   Navigator.of(context).push(_createRoute());
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           ListView(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: TypeAheadField<Map<String, String>>(
//                   suggestionsCallback: _getPlaceSuggestions,
//                   itemBuilder: (context, Map<String, String> suggestion) {
//                     // Display the suggestion or fallback message
//                     if (suggestion['place_id'] == '') {
//                       return Center(
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 10.0),
//                           child: Text(
//                             suggestion['description']!,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey,
//                               fontStyle: FontStyle.italic,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       );
//                     }
//                     return ListTile(
//                       title: Text(suggestion['description']!),
//                     );
//                   },
//                   onSelected: (Map<String, String> suggestion) async {
//                     if (suggestion['place_id'] != '') {
//                       _sourceController.text = suggestion['description']!;
//                       final placeId = suggestion['place_id']!;
//                       await _getPlaceDetails(
//                           placeId, true); // Fetch source details
//                     } else {
//                       LogService.logInfo(
//                           'Invalid selection: ${suggestion['description']}');
//                     }
//                   },
//                   direction: VerticalDirection.down,
//                   builder: (context, controller, focusNode) {
//                     return TextField(
//                       controller: controller,
//                       focusNode: focusNode,
//                       decoration: InputDecoration(
//                         labelText: 'Pickup location',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8.0),
//                         ),
//                         prefixIcon: const Icon(CupertinoIcons.pin),
//                         suffixIcon: isLoadingSource
//                             ? const Padding(
//                                 padding: EdgeInsets.all(8.0),
//                                 child:
//                                     CircularProgressIndicator(strokeWidth: 2),
//                               )
//                             : IconButton(
//                                 icon: const Icon(Ionicons.locate),
//                                 onPressed: () => _getCurrentLocation(true),
//                               ),
//                       ),
//                     );
//                   },
//                   controller: _sourceController,
//                 ),
//               ),
//               const Gap(5),
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: TypeAheadField<Map<String, String>>(
//                   suggestionsCallback: _getPlaceSuggestions,
//                   itemBuilder: (context, Map<String, String> suggestion) {
//                     // Display the suggestion or fallback message
//                     if (suggestion['place_id'] == '') {
//                       // Center the fallback error message
//                       return Center(
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 10.0),
//                           child: Text(
//                             suggestion['description']!,
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey,
//                               fontStyle: FontStyle.italic,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       );
//                     }
//                     return ListTile(
//                       title: Text(suggestion['description']!),
//                     );
//                   },
//                   onSelected: (Map<String, String> suggestion) async {
//                     if (suggestion['place_id'] != '') {
//                       _destinationController.text = suggestion['description']!;
//                       final placeId = suggestion['place_id']!;
//                       await _getPlaceDetails(
//                           placeId, false);
//                     } else {
//                       LogService.logInfo(
//                           'Invalid selection: ${suggestion['description']}');
//                     }
//                   },
//                   direction: VerticalDirection
//                       .down, // Force suggestions to face downwards
//                   builder: (context, controller, focusNode) {
//                     return TextField(
//                       controller: controller,
//                       focusNode: focusNode,
//                       decoration: InputDecoration(
//                         labelText: 'Destination',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8.0),
//                         ),
//                         prefixIcon: const Icon(CupertinoIcons.location_circle),
//                         suffixIcon: isLoadingDestination
//                             ? const Padding(
//                                 padding: EdgeInsets.all(8.0),
//                                 child:
//                                     CircularProgressIndicator(strokeWidth: 2),
//                               )
//                             : IconButton(
//                                 icon: const Icon(Ionicons.locate),
//                                 onPressed: () => _getCurrentLocation(false),
//                               ),
//                       ),
//                     );
//                   },
//                   controller: _destinationController,
//                 ),
//               ),
//               const Gap(5),
//               Container(
//                 margin: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                 ),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [LarosaColors.secondary, LarosaColors.purple],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 child: FilledButton(
//                   style: ButtonStyle(
//                     backgroundColor:
//                         WidgetStateProperty.all(Colors.transparent),
//                     padding: WidgetStateProperty.all(
//                       const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//                     ),
//                     shape: WidgetStateProperty.all(
//                       RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                   ),
//                   onPressed: isRequestingRide ? null : fetchTimeEstimations,
//                   child: isFetchingTimeEstimations
//                       ? const CupertinoActivityIndicator(
//                           color: Colors.white,
//                           radius: 10.0,
//                         )
//                       : const Text(
//                           'Initiate Ride Request',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 1.0,
//                             fontSize: 15
//                           ),
//                         ),
//                 ),
//               ),
//               const Gap(10),
//               const Divider(),
//               const Gap(10),
//               Padding(
//   padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
//   child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       // Header with creative gradient title and "Ride History" action
//       Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // Gradient text header
//           ShaderMask(
//             shaderCallback: (bounds) => const LinearGradient(
//               colors: [LarosaColors.secondary, LarosaColors.purple],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ).createShader(bounds),
//             child: const Text(
//               'Your Orders',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white, // This is masked by the gradient shader.
//               ),
//             ),
//           ),
//           Container(
//   decoration: BoxDecoration(
//     gradient: const LinearGradient(
//       colors: [LarosaColors.secondary, LarosaColors.purple],
//       begin: Alignment.centerLeft,
//       end: Alignment.centerRight,
//     ),
//     borderRadius: BorderRadius.circular(20),
//   ),
//   child: TextButton(
//     onPressed: () {
//       // Show modal to display ride history
//       showModalBottomSheet(
//   context: context,
//   isScrollControlled: true,
//   backgroundColor: Colors.transparent, // Ensure transparency for custom design
//   builder: (BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             LarosaColors.secondary.withOpacity(0.55),
//             LarosaColors.purple.withOpacity(0.4),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       padding: const EdgeInsets.all(8),
//       // Optionally wrap the content in a ClipRRect if you want to enforce the rounded corners on inner content.
//       child: ClipRRect(
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//         child: RideHistoryModal(rideHistory: rideHistory),
//       ),
//     );
//   },
// );

//     },
//     style: TextButton.styleFrom(
//       backgroundColor: Colors.transparent, // Make it transparent so the gradient shows
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//     ),
//     child: Text(
//       'Ride History',
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: Theme.of(context).brightness == Brightness.dark
//             ? Colors.white
//             : LarosaColors.light, // use a light color that contrasts with the gradient
//       ),
//     ),
//   ),
// ),

//         ],
//       ),
//       const SizedBox(height: 10),
//       // If no orders, show empty state creatively
//       orders.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.shopping_cart_outlined,
//                     size: 80,
//                     color: LarosaColors.mediumGray,
//                   ),
//                   const SizedBox(height: 20),
//                   const Text(
//                     "No current orders",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   const Text(
//                     "It looks like you haven't placed any orders yet.",
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey,
//                       height: 1.4,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       // Navigate to the page where users can make a new order
//                       Navigator.of(context).push(_createRoute());
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: LarosaColors.purple,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(25),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 28,
//                         vertical: 14,
//                       ),
//                       elevation: 5,
//                       shadowColor: LarosaColors.primary.withOpacity(0.5),
//                     ),
//                     child: const Text(
//                       "Make a New Order",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           // When orders exist, display them in creatively styled cards.
//           : ListView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: orders.length,
//         itemBuilder: (context, index) {
//           return creativeOrderCard(orders[index]);
//         },
//       ),
//       const SizedBox(height: 70),
//     ],
//   ),
// ),

//             ],
//           ),
//           const Positioned(
//             bottom: 10,
//             left: 10,
//             right: 10,
//             child: BottomNavigation(
//               activePage: ActivePage.delivery,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

// // Route for the animated modal
//   Route _createRoute() {
//     return PageRouteBuilder(
//       pageBuilder: (context, animation, secondaryAnimation) => ExploreModal(),
//       transitionsBuilder: (context, animation, secondaryAnimation, child) {
//         const begin = Offset(0.0, 1.0);
//         const end = Offset.zero;
//         const curve = Curves.easeInOut;

//         var tween =
//             Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
//         var offsetAnimation = animation.drive(tween);

//         return SlideTransition(
//           position: offsetAnimation,
//           child: child,
//         );
//       },
//     );
//   }

// Widget creativeOrderCard(Map order) {
//   // Extract required information from the order map.
//   final deliveryLocation = order['deliveryLocation'];
//   final driver = order['driver'];

//   // Helper function to format numbers with commas.
//   String formatAmount(num amount) {
//     return amount
//         .toStringAsFixed(0)
//         .replaceAllMapped(
//             RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
//             (Match m) => '${m[1]},');
//   }

//   return Container(
//     margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
//     // Outer gradient border for creative flair.
//     decoration: BoxDecoration(
//       gradient: LinearGradient(
//         colors: [
//           LarosaColors.primary.withOpacity(0.4),
//           LarosaColors.purple.withOpacity(0.4)
//         ],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//       borderRadius: BorderRadius.circular(20),
//       boxShadow: [
//         BoxShadow(
//           color: LarosaColors.dark.withOpacity(0.1),
//           blurRadius: 10,
//           offset: const Offset(0, 4),
//         )
//       ],
//     ),
//     child: ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         color: LarosaColors.light, // Card background
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Decorative header bar for order ID.
//             Container(
//               width: double.infinity,
//               padding:
//                   const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                     colors: [LarosaColors.secondary, LarosaColors.purple],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 'Order ID: ${order['id']}',
//                 style: const TextStyle(
//                   fontSize: 17,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             // Order detail rows with creative spacing.
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Total Amount:',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       'Tsh ${formatAmount(order['totalAmount'])}',
//                       style: TextStyle(color: LarosaColors.primary),
//                     ),
//                   ],
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     const Text(
//                       'Order Amount:',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       'Tsh ${formatAmount(order['orderAmount'])}',
//                       style: TextStyle(color: LarosaColors.primary),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Delivery Amount:',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       'Tsh ${formatAmount(order['deliveryAmount'])}',
//                       style: TextStyle(color: LarosaColors.primary),
//                     ),
//                   ],
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     const Text(
//                       'Status:',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       '${order['status']}',
//                       style: TextStyle(
//                         color: order['status'] == 'PENDING'
//                             ? Colors.orange
//                             : Colors.green,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             // Delivery location details.
//             if (deliveryLocation != null)
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         'City:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         '${deliveryLocation['city']}',
//                         style: const TextStyle(fontSize: 15),
//                       ),
//                     ],
//                   ),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       const Text(
//                         'Zip Code:',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                       Text(
//                         '${deliveryLocation['zipCode']}',
//                         style: const TextStyle(fontSize: 15),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             const SizedBox(height: 12),
//             // Driver information or a button to view location on map.
//             if (driver != null && driver['name'] != null)
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Driver: ${driver['name']}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: Icon(
//                       Icons.location_on,
//                       color: LarosaColors.primary,
//                     ),
//                     onPressed: () {
//                       if (deliveryLocation != null) {
//                         showModalBottomSheet(
//                           context: context,
//                           isScrollControlled: true,
//                           backgroundColor: Colors.transparent,
//                           builder: (BuildContext context) {
//                             return StatefulBuilder(
//                               builder: (BuildContext context, StateSetter setState) {
//                                 return MapModal(
//                                   latitude: deliveryLocation['latitude'] ?? 0.0,
//                                   longitude: deliveryLocation['longitude'] ?? 0.0,
//                                 );
//                               },
//                             );
//                           },
//                         );
//                       }
//                     },
//                   ),
//                 ],
//               )
//             else
//               Padding(
//                 padding: const EdgeInsets.only(top: 8.0),
//                 child: const Text(
//                   'Driver: Not assigned',
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     ),
//   );
// }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ionicons/ionicons.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../Utils/colors.dart';
import 'explore_services.dart';
import 'map_service.dart';
import 'time_estimations_modal_content.dart';
import 'widgets/ride_history_modal.dart';

class NewDelivery extends StatefulWidget {
  const NewDelivery({super.key});

  @override
  State<NewDelivery> createState() => _NewDeliveryState();
}

class _NewDeliveryState extends State<NewDelivery> {
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  String? selectedSourceStreetName;
  double? sourceLatitude;
  double? sourceLongitude;
  String? selectedDestinationStreetName;
  double? destinationLatitude;
  double? destinationLongitude;
  bool isLoadingSource = false;
  bool isLoadingDestination = false;
  String paymentMethod = 'CASH';
  String vehicleType = 'MOTORCYCLE';
  List<dynamic> orders = [];
  late StompClient stompClient;
  final String socketChannel =
      '${LarosaLinks.baseurl}/ws/topic/customer/${AuthService.getProfileId()}';

  bool isFetchingTimeEstimations = false;
  bool isLoading = true; // Track overall loading state

  // Variables for driver offer functionality.
  Map<String, dynamic>? driverOffer;
  bool isLoadingDriverOffer = false;

  Future<void> _asyncInit() async {
    // Uncomment or add any additional asynchronous initialization as needed.
    _loadOrders();
  }

  @override
  void initState() {
    super.initState();
    _asyncInit();
    _loadRideHistory();
    // Delay driver offer loading until after the pickup location is set.
    _loadDriverOffer();
    if (destinationLatitude != null && destinationLongitude != null) {
      _updateDestinationMarker(destinationLatitude!, destinationLongitude!);
    }
  }

  Future<void> _loadDriverOffer() async {
    print('123');
    setState(() {
      isLoadingDriverOffer = true;
    });

    // If source location is not set, attempt to retrieve the current location.
    if (sourceLatitude == null || sourceLongitude == null) {
      print('Source location not set, attempting to get current location');
      await _getCurrentLocation(true);
      // Recheck whether location is available.
      if (sourceLatitude == null || sourceLongitude == null) {
        print('Source location is still null after attempting to retrieve it.');
        setState(() {
          isLoadingDriverOffer = false;
        });
        return;
      }
    }

    // Get the city name using the source location.
    final placeDetails =
        await getCountryAndCity(sourceLatitude!, sourceLongitude!);
    print('Place details: $placeDetails');
    final cityName = placeDetails["city"] ?? "";
    print('City name: $cityName');
    if (cityName.isEmpty) {
      print('City name is empty.');
      setState(() {
        isLoadingDriverOffer = false;
      });
      return;
    }

    print('fred'); // Debug point: Proceeding to call driver offer endpoint.

    // final String endpoint =
    //     '${LarosaLinks.baseurl}/api/v1/ride-offers/driver/best-offer?cityName=$cityName';

    final String endpoint =
        '${LarosaLinks.baseurl}/api/v1/ride-offers/ustomer/best-offer?cityName=Dodoma';
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer ${AuthService.getToken()}',
    };

    try {
      final response = await http.get(Uri.parse(endpoint), headers: headers);
      print('frs : ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          driverOffer = jsonDecode(response.body);
          isLoadingDriverOffer = false;
        });
      } else {
        LogService.logError(
            "Failed to fetch driver offer: ${response.statusCode}");
        setState(() {
          isLoadingDriverOffer = false;
        });
      }
    } catch (e) {
      LogService.logError("Error fetching driver offer: $e");
      setState(() {
        isLoadingDriverOffer = false;
      });
    }
  }

  String formatTime(double minutes) {
    int hours = (minutes / 60).floor();
    int mins = (minutes % 60).round();
    if (hours > 0) {
      return "$hours hr ${mins > 0 ? '$mins min' : ''}";
    } else {
      return "$mins min";
    }
  }

  final Set<Marker> _markers = {}; // Holds the map markers

  void _updateMarker(double latitude, double longitude) {
    setState(() {
      _markers
          .removeWhere((marker) => marker.markerId.value == 'dynamic_marker');
      _markers.add(
        Marker(
          markerId: const MarkerId('dynamic_marker'),
          position: LatLng(latitude, longitude),
          infoWindow: const InfoWindow(title: 'Driver Location'),
        ),
      );
    });
  }

  bool isRequestingRide = false;

  Future<Map<String, dynamic>> estimateTimeForAllVehicles({
    required double customerLatitude,
    required double customerLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    const String endpoint =
        '${LarosaLinks.baseurl}/api/v1/ride-customer/time-estimation';
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer ${AuthService.getToken()}',
    };

    final Map<String, dynamic> requestBody = {
      "customerLatitude": customerLatitude,
      "customerLongitude": customerLongitude,
      "destinationLatitude": destinationLatitude,
      "destinationLongitude": destinationLongitude,
    };

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logInfo("Time Estimation Response: ${response.body}");
        return jsonDecode(response.body);
      } else {
        LogService.logError(
            "frs Failed to fetch time estimation: ${response.statusCode}");
        return {
          "error":
              "123 Failed to fetch time estimation. Status code: ${response.statusCode}"
        };
      }
    } catch (e) {
      LogService.logError("Error estimating time: $e");
      return {"error": "An error occurred while estimating time: $e"};
    }
  }

  Future<List<Map<String, String>>> _getPlaceSuggestions(String input) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
    const String baseUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    final url = '$baseUrl?input=$input&key=$apiKey&components=country:tz';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final suggestions = (jsonData['predictions'] as List)
            .map((prediction) {
              final terms = prediction['terms'] as List;
              final region =
                  terms.length > 1 ? terms[1]['value'] as String : '';
              return {
                'description': prediction['description'] as String,
                'place_id': prediction['place_id'] as String,
                'region': region,
              };
            })
            .toList()
            .cast<Map<String, String>>();
        return suggestions.isNotEmpty
            ? suggestions
            : [
                {
                  'description': 'No results found.',
                  'place_id': '',
                  'region': ''
                }
              ];
      } else {
        return [
          {
            'description': 'Failed to fetch locations. Please try again.',
            'place_id': '',
            'region': ''
          }
        ];
      }
    } catch (e) {
      LogService.logError('Error fetching suggestions: $e');
      return [
        {
          'description':
              'Failed to fetch locations. Please check your connection.',
          'place_id': '',
          'region': ''
        }
      ];
    }
  }

  Future<void> _getPlaceDetails(String placeId, bool isSource) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
    const String detailsUrl =
        'https://maps.googleapis.com/maps/api/place/details/json';
    final url = '$detailsUrl?place_id=$placeId&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData['result'] != null &&
            jsonData['result']['geometry'] != null) {
          final location = jsonData['result']['geometry']['location'];
          final address = jsonData['result']['formatted_address'];
          final lat = location['lat'];
          final lng = location['lng'];

          setState(() {
            if (isSource) {
              sourceLatitude = lat;
              sourceLongitude = lng;
              selectedSourceStreetName = address;
              isLoadingSource = false;
            } else {
              destinationLatitude = lat;
              destinationLongitude = lng;
              selectedDestinationStreetName = address;
              isLoadingDestination = false;
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoadingSource = false;
        isLoadingDestination = false;
      });
      LogService.logError('Error fetching place details: $e');
    }
  }

  Future<void> _loadOrders() async {
    String token = AuthService.getToken();
    LogService.logDebug('token $token');
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.parse('${LarosaLinks.baseurl}/api/v1/orders/history');

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logFatal('Orders fetch successful');
        LogService.logInfo(response.body);
        setState(() {
          orders = jsonDecode(response.body);
          orders = orders.reversed.toList();
        });
      } else {
        LogService.logError('Error fetching orders: ${response.statusCode}');
      }
    } catch (e) {
      LogService.logError('Failed to fetch orders: $e');
    }
  }

  List<dynamic> rideHistory = [];

  Future<void> _loadRideHistory() async {
    String token = AuthService.getToken();
    LogService.logDebug('token $token');
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.parse('${LarosaLinks.baseurl}/api/v1/ride-customer/rides');

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logFatal('Ride history fetch successful');
        LogService.logInfo(response.body);
        setState(() {
          rideHistory = jsonDecode(response.body);
        });
      } else {
        LogService.logError(
            'Error fetching ride history: ${response.statusCode}');
      }
    } catch (e) {
      LogService.logError('Failed to fetch ride history: $e');
    }
  }

  Future<Map<String, String>> getCountryAndCity(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // LogService.logDebug('Geocoding Result: $place');
        return {
          "country": place.country ?? "Unknown",
          "city": place.locality ?? place.administrativeArea ?? "Unknown",
        };
      }
    } catch (e) {
      LogService.logError('Error in getCountryAndCity: $e');
    }
    return {"country": "Unknown", "city": "Unknown"};
  }

  // Future<void> fetchTimeEstimations() async {
  //   if (sourceLatitude == null ||
  //       sourceLongitude == null ||
  //       destinationLatitude == null ||
  //       destinationLongitude == null) {
  //     HelperFunctions.showToast("Please enter pickup and destination locations", true);
  //     return;
  //   }
  //   setState(() {
  //     isFetchingTimeEstimations = true;
  //   });
  //   final placeDetails = await getCountryAndCity(sourceLatitude!, sourceLongitude!);
  //   final String country = placeDetails["country"] ?? "Unknown";
  //   final String cityName = placeDetails["city"] ?? "Unknown";

  //   const String endpoint = '${LarosaLinks.baseurl}/api/v1/transport-cost/calculate';
  //   Map<String, String> headers = {
  //     "Content-Type": "application/json",
  //     "Access-Control-Allow-Origin": "*",
  //     'Authorization': 'Bearer ${AuthService.getToken()}',
  //   };

  //   final Map<String, dynamic> requestBody = {
  //     "startLat": sourceLatitude,
  //     "startLng": sourceLongitude,
  //     "endLat": destinationLatitude,
  //     "endLng": destinationLongitude,
  //     "country": country,
  //     "cityName": cityName,
  //     // "City": cityName,
  //     "City": "Dodoma",
  //     "city": "dodoma"
  //   };

  //   try {
  //     final response = await http.post(
  //       Uri.parse(endpoint),
  //       headers: headers,
  //       body: jsonEncode(requestBody),
  //     );
  //     setState(() {
  //       isFetchingTimeEstimations = false;
  //     });
  //     // print("frs : ${response.body}");
  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       final Map<String, dynamic> estimations = jsonDecode(response.body);
  //       bool allDriversBusy = estimations["vehicleEstimations"]
  //           .every((estimation) => estimation["pickupDuration"] == 0);
  //       if (allDriversBusy) {
  //         HelperFunctions.displayInfo(
  //           context,
  //           "Our system is experiencing high demand at the moment. Please hold on while we secure the best available driver for you. Your comfort and safety are our top priority."
  //         );
  //       } else {
  //         showTimeEstimationsModal(context, estimations);
  //       }
  //     } else {
  //       print("frs : ${AuthService.getToken()}");
  //       HelperFunctions.showToast("xyz Failed to fetch transport cost. Status code: ${response.statusCode}", true);
  //     }
  //   } catch (e) {
  //     setState(() {
  //       isFetchingTimeEstimations = false;
  //     });
  //     LogService.logError("Error calculating transport cost: $e");
  //     HelperFunctions.showToast("An error occurred while calculating transport cost", true);
  //   }
  // }

  Future<void> fetchTimeEstimations() async {
    if (sourceLatitude == null ||
        sourceLongitude == null ||
        destinationLatitude == null ||
        destinationLongitude == null) {
      HelperFunctions.showToast(
          "Please enter pickup and destination locations", true);
      return;
    }

    setState(() => isFetchingTimeEstimations = true);

    // Get country + city from reverse‐geocoding
    final placeDetails =
        await getCountryAndCity(sourceLatitude!, sourceLongitude!);
    final String country = placeDetails["country"] ?? "Unknown";
    final String rawCity = placeDetails["city"] ?? "Unknown";

    // Ensure title‐case (in case API is case‐sensitive)
    String city = rawCity
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');

    // Build request body with BOTH keys
    final Map<String, dynamic> requestBody = {
      // "startLat": sourceLatitude,
      // "startLng": sourceLongitude,
      // "endLat": destinationLatitude,
      // "endLng": destinationLongitude,
      // "country": country,
      // "city": city,
      // "cityName": city,


      
  "startLat": -6.1620,
  "startLng": 35.7516,
  "endLat":   -6.1750,
  "endLng":   35.7497,
  "country":  "Tanzania",
  "city":     "Dodoma",
  "cityName": "Dodoma"
    };

    print('→ Payload: ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse('${LarosaLinks.baseurl}/api/v1/transport-cost/calculate'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AuthService.getToken()}",
        },
        body: jsonEncode(requestBody),
      );

      setState(() => isFetchingTimeEstimations = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Succeeded frs : ${response.body}");

        final estimations = jsonDecode(response.body);
        bool allBusy = (estimations["vehicleEstimations"] as List)
            .every((e) => e["pickupDuration"] == 0);

        if (allBusy) {
          // HelperFunctions.displayInfo(
          //     context,
          //     "Our system is experiencing high demand at the moment. "
          //     "Please hold on while we secure the best available driver...");


              showTimeEstimationsModal(context, estimations);

        } else {
          showTimeEstimationsModal(context, estimations);
        }
      } else {
        print("Failed frs : ${response.body}");
        HelperFunctions.showToast(
            "Failed to fetch transport cost "
            "(status ${response.statusCode})",
            true);
      }
    } catch (e) {
      setState(() => isFetchingTimeEstimations = false);
      LogService.logError("Error calculating transport cost: $e");
      HelperFunctions.showToast(
          "An error occurred while calculating transport cost", true);
    }
  }

  void showTimeEstimationsModal(
      BuildContext context, Map<String, dynamic> estimations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return TimeEstimationsModalContent(
          estimations: estimations,
          sourceLatitude: sourceLatitude!,
          sourceLongitude: sourceLongitude!,
          destinationLatitude: destinationLatitude!,
          destinationLongitude: destinationLongitude!,
        );
      },
    );
  }

  Future<void> _getCurrentLocation(bool isSource) async {
    setState(() {
      if (isSource) {
        isLoadingSource = true;
      } else {
        isLoadingDestination = true;
      }
    });
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          isLoadingSource = false;
          isLoadingDestination = false;
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String region = place.administrativeArea ?? 'Unknown Region';
        String country = place.country ?? 'Unknown Country';
        String address = '${place.name}, $region, $country';
        setState(() {
          if (isSource) {
            sourceLatitude = position.latitude;
            sourceLongitude = position.longitude;
            selectedSourceStreetName = address;
            _sourceController.text = address;
            isLoadingSource = false;
          } else {
            destinationLatitude = position.latitude;
            destinationLongitude = position.longitude;
            selectedDestinationStreetName = address;
            _destinationController.text = address;
            isLoadingDestination = false;
          }
        });
      }
    } catch (e) {
      setState(() {
        isLoadingSource = false;
        isLoadingDestination = false;
      });
      LogService.logError('Error fetching current location: $e');
    }
  }

  void _updateDestinationMarker(double latitude, double longitude) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'destination');
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(latitude, longitude),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    });
  }

  Route _createRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ExploreModal(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  Widget creativeOrderCard(Map order) {
    final deliveryLocation = order['deliveryLocation'];
    final driver = order['driver'];
    String formatAmount(num amount) {
      return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LarosaColors.primary.withOpacity(0.4),
            LarosaColors.purple.withOpacity(0.4)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: LarosaColors.dark.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: LarosaColors.light,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LarosaColors.secondary, LarosaColors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Order ID: ${order['id']}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tsh ${formatAmount(order['totalAmount'])}',
                        style: TextStyle(color: LarosaColors.primary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Order Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tsh ${formatAmount(order['orderAmount'])}',
                        style: TextStyle(color: LarosaColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tsh ${formatAmount(order['deliveryAmount'])}',
                        style: TextStyle(color: LarosaColors.primary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${order['status']}',
                        style: TextStyle(
                          color: order['status'] == 'PENDING'
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (deliveryLocation != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'City:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${deliveryLocation['city']}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Zip Code:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${deliveryLocation['zipCode']}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              if (driver != null && driver['name'] != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Driver: ${driver['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.location_on,
                        color: LarosaColors.primary,
                      ),
                      onPressed: () {
                        if (deliveryLocation != null) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (BuildContext context) {
                              return StatefulBuilder(
                                builder: (BuildContext context,
                                    StateSetter setState) {
                                  return MapModal(
                                    latitude:
                                        deliveryLocation['latitude'] ?? 0.0,
                                    longitude:
                                        deliveryLocation['longitude'] ?? 0.0,
                                  );
                                },
                              );
                            },
                          );
                        }
                      },
                    ),
                  ],
                )
              else
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Driver: Not assigned',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        // title: const Text(
        //   'Delivery',
        //   style: TextStyle(fontSize: 18),
        // ),
        title: GestureDetector(
          onTap: _loadDriverOffer,
          child: const Text(
            'Delivery',
            style: TextStyle(fontSize: 18),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [LarosaColors.secondary, LarosaColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.explore, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(_createRoute());
                },
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // Pickup location input.
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TypeAheadField<Map<String, String>>(
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
                      _sourceController.text = suggestion['description']!;
                      final placeId = suggestion['place_id']!;
                      await _getPlaceDetails(placeId, true);
                      // Optionally reload the driver offer after updating source location.
                      await _loadDriverOffer();
                    } else {
                      LogService.logInfo(
                          'Invalid selection: ${suggestion['description']}');
                    }
                  },
                  direction: VerticalDirection.down,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Pickup location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(CupertinoIcons.pin),
                        suffixIcon: isLoadingSource
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Ionicons.locate),
                                onPressed: () => _getCurrentLocation(true),
                              ),
                      ),
                    );
                  },
                  controller: _sourceController,
                ),
              ),
              const Gap(5),
              // Destination location input.
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TypeAheadField<Map<String, String>>(
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
                      _destinationController.text = suggestion['description']!;
                      final placeId = suggestion['place_id']!;
                      await _getPlaceDetails(placeId, false);
                    } else {
                      LogService.logInfo(
                          'Invalid selection: ${suggestion['description']}');
                    }
                  },
                  direction: VerticalDirection.down,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        prefixIcon: const Icon(CupertinoIcons.location_circle),
                        suffixIcon: isLoadingDestination
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Ionicons.locate),
                                onPressed: () => _getCurrentLocation(false),
                              ),
                      ),
                    );
                  },
                  controller: _destinationController,
                ),
              ),
              const Gap(5),
              // Initiate Ride Request button.
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LarosaColors.secondary, LarosaColors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: FilledButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  onPressed: isRequestingRide ? null : fetchTimeEstimations,
                  child: isFetchingTimeEstimations
                      ? const CupertinoActivityIndicator(
                          color: Colors.white, radius: 10.0)
                      : const Text(
                          'Initiate Ride Request',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              fontSize: 15),
                        ),
                ),
              ),
              const Gap(10),
              // Display Driver Offer (Driver Side)
              if (isLoadingDriverOffer)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (driverOffer != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [LarosaColors.secondary, LarosaColors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Driver Offer",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        // Adjust these keys based on your actual API response.
                        Text("Offer ID: ${driverOffer!['offerId']}",
                            style: const TextStyle(color: Colors.white)),
                        Text("Driver: ${driverOffer!['driverName']}",
                            style: const TextStyle(color: Colors.white)),
                        Text("Amount: Tsh ${driverOffer!['offerAmount']}",
                            style: const TextStyle(color: Colors.white)),
                        Text("City: ${driverOffer!['cityName']}",
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              const Gap(10),
              const Divider(),
              const Gap(10),
              // Orders section.
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              LarosaColors.secondary,
                              LarosaColors.purple
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Text(
                            'Your Orders',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                LarosaColors.secondary,
                                LarosaColors.purple
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (BuildContext context) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          LarosaColors.secondary
                                              .withOpacity(0.55),
                                          LarosaColors.purple.withOpacity(0.4),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                      child: RideHistoryModal(
                                          rideHistory: rideHistory),
                                    ),
                                  );
                                },
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              'Ride History',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : LarosaColors.light,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    orders.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 80,
                                  color: LarosaColors.mediumGray,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "No current orders",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "It looks like you haven't placed any orders yet.",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(_createRoute());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: LarosaColors.purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 14,
                                    ),
                                    elevation: 5,
                                    shadowColor:
                                        LarosaColors.primary.withOpacity(0.5),
                                  ),
                                  child: const Text(
                                    "Make a New Order",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              return creativeOrderCard(orders[index]);
                            },
                          ),
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ],
          ),
          const Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: BottomNavigation(
              activePage: ActivePage.delivery,
            ),
          ),
        ],
      ),
    );
  }
}
