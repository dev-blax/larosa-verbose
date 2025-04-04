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

  bool isLoading = true; // Track loading state

  Future<void> _asyncInit() async {
    // await _socketConnection2();
    // await _updateCurrentCityFromLocation();
    // _connectToStomp();
    _loadOrders();
  }

  @override
  void initState() {
    super.initState();
    _asyncInit();

    _loadRideHistory();

    if (destinationLatitude != null && destinationLongitude != null) {
      _updateDestinationMarker(destinationLatitude!, destinationLongitude!);
    }
  }

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
            "Failed to fetch time estimation: ${response.statusCode}");
        return {
          "error":
              "Failed to fetch time estimation. Status code: ${response.statusCode}"
        };
      }
    } catch (e) {
      LogService.logError("Error estimating time: $e");
      return {"error": "An error occurred while estimating time: $e"};
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

  void _updateDriverMarker(double latitude, double longitude) {
    setState(() {
      _markers.removeWhere((marker) =>
          marker.markerId.value == 'driver'); // Remove existing driver marker
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(latitude, longitude),
          infoWindow: const InfoWindow(title: 'Driver Location'),
        ),
      );
    });
  }

  void _updateDestinationMarker(double latitude, double longitude) {
    setState(() {
      _markers.removeWhere((marker) =>
          marker.markerId.value ==
          'destination'); // Remove existing destination marker
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(latitude, longitude),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    });
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

  Future<Map<String, String>> getCountryAndCity(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        LogService.logDebug('Geocoding Result: $place');
        return {
          "country": place.country ?? "Unknown",
          "city": place.administrativeArea ??
              "Unknown", // Use administrativeArea for region
        };
      }
    } catch (e) {
      LogService.logError('Error in getCountryAndCity: $e');
    }
    return {"country": "Unknown", "city": "Unknown"};
  }

  Future<void> fetchTimeEstimations() async {
    if (sourceLatitude == null ||
        sourceLongitude == null ||
        destinationLatitude == null ||
        destinationLongitude == null) {
      HelperFunctions.showToast(
        "Please enter pickup and destination locations",
        true,
      );
      return;
    }

    setState(() {
      isFetchingTimeEstimations = true; // Start loading
    });

    final estimations = await estimateTimeForAllVehicles(
      customerLatitude: sourceLatitude!,
      customerLongitude: sourceLongitude!,
      destinationLatitude: destinationLatitude!,
      destinationLongitude: destinationLongitude!,
    );

    setState(() {
      isFetchingTimeEstimations = false; // Stop loading
    });

    if (estimations.containsKey('error')) {
      HelperFunctions.showToast(estimations['error'], true);
    } else {
      showTimeEstimationsModal(context, estimations);
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
        final json = jsonDecode(response.body);

        // Parse the predictions and ensure all values are strings
        final suggestions = (json['predictions'] as List)
            .map((prediction) {
              // Extract region from the terms
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
            .cast<
                Map<String,
                    String>>(); // Ensure the type is List<Map<String, String>>

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
        final json = jsonDecode(response.body);

        if (json['result'] != null && json['result']['geometry'] != null) {
          final location = json['result']['geometry']['location'];
          final address = json['result']['formatted_address'];
          final lat = location['lat'];
          final lng = location['lng'];

          setState(() {
            if (isSource) {
              sourceLatitude = lat;
              sourceLongitude = lng;
              selectedSourceStreetName = address;
              // Don't overwrite _sourceController.text here
              isLoadingSource = false;
            } else {
              destinationLatitude = lat;
              destinationLongitude = lng;
              selectedDestinationStreetName = address;
              // Don't overwrite _destinationController.text here
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
      LogService.logError('Error: $e');
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
      final response = await http.get(
        url,
        headers: headers,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logFatal('success');
        LogService.logInfo(response.body);
        setState(() {
          orders = jsonDecode(response.body);
          // Reverse the orders
          orders = orders.reversed.toList();
        });
        return;
      }

      LogService.logError('error: ${response.statusCode}');
    } catch (e) {
      LogService.logError('failed $e');
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
      final response = await http.get(
        url,
        headers: headers,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logFatal('Ride history fetch successful');
        LogService.logInfo(response.body);

        setState(() {
          rideHistory = jsonDecode(response.body);
        });

        return;
      }

      LogService.logError(
          'Error fetching ride history: ${response.statusCode}');
    } catch (e) {
      LogService.logError('Failed to fetch ride history: $e');
    }
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
      LogService.logError('Error: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Delivery',
          style: TextStyle(fontSize: 16),
        ),
        // centerTitle: true,
        actions: [
          // Other action buttons can go here
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
                icon: const Icon(
                  Icons.explore,
                  color: Colors.white,
                ),
                onPressed: () {
                  // When clicked, open the explore modal
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TypeAheadField<Map<String, String>>(
                  suggestionsCallback: _getPlaceSuggestions,
                  itemBuilder: (context, Map<String, String> suggestion) {
                    // Display the suggestion or fallback message
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
                      await _getPlaceDetails(
                          placeId, true); // Fetch source details
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TypeAheadField<Map<String, String>>(
                  suggestionsCallback: _getPlaceSuggestions,
                  itemBuilder: (context, Map<String, String> suggestion) {
                    // Display the suggestion or fallback message
                    if (suggestion['place_id'] == '') {
                      // Center the fallback error message
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
                      await _getPlaceDetails(
                          placeId, false); 
                    } else {
                      LogService.logInfo(
                          'Invalid selection: ${suggestion['description']}');
                    }
                  },
                  direction: VerticalDirection
                      .down, // Force suggestions to face downwards
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
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
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
                          color: Colors.white,
                          radius: 10.0,
                        )
                      : const Text(
                          'Initiate Ride Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
              const Gap(10),
              const Divider(),
              const Gap(10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  // crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Orders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Show modal to display ride history
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              builder: (BuildContext context) {
                                return RideHistoryModal(
                                    rideHistory: rideHistory);
                              },
                            );
                          },
                          child: Text(
                            'Ride History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(5),
                    orders.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "No current orders",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "It looks like you haven't placed any orders yet.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to the page where users can make a new order
                                  Navigator.of(context).push(_createRoute());
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LarosaColors
                                      .purple, // Use your theme colors
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                ),
                                child: const Text(
                                  "Make a New Order",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            shrinkWrap:
                                true, // Ensures ListView takes only required space
                            physics:
                                const NeverScrollableScrollPhysics(), // Disable scrolling
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              final deliveryLocation =
                                  order['deliveryLocation'];
                              final driver = order['driver'];

                              // Helper function to format numbers with commas
                              String formatAmount(num amount) {
                                return amount
                                    .toStringAsFixed(0)
                                    .replaceAllMapped(
                                        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                        (Match m) => '${m[1]},');
                              }

                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order ID: ${order['id']}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),

                                      const Divider(),
                                      const Gap(12),

                                      // Full-width row with justified alignment
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Total Amount:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                  'Tsh ${formatAmount(order['totalAmount'])}'),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'Order Amount:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                  'Tsh ${formatAmount(order['orderAmount'])}'),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Gap(8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Delivery Amount:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                  'Tsh ${formatAmount(order['deliveryAmount'])}'),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'Status:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text(
                                                '${order['status']}',
                                                style: TextStyle(
                                                  color: order['status'] ==
                                                          'PENDING'
                                                      ? Colors.orange
                                                      : Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Gap(8),
                                      if (deliveryLocation != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'City:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                    '${deliveryLocation['city']}'),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  'Zip Code:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text(
                                                    '${deliveryLocation['zipCode']}'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      const Gap(8),
                                      if (driver != null &&
                                          driver['name'] != null)
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Driver:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Text('${driver['name']}'),
                                              ],
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.location_on,
                                                // color: LarosaColors.primary
                                              ),
                                              onPressed: () {
                                                if (deliveryLocation != null) {
                                                  // Open the Map Modal
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    builder:
                                                        (BuildContext context) {
                                                      return StatefulBuilder(
                                                          builder: (BuildContext
                                                                  context,
                                                              StateSetter
                                                                  setState) {
                                                        return MapModal(
                                                          latitude:
                                                              deliveryLocation[
                                                                      'latitude'] ??
                                                                  0.0,
                                                          longitude:
                                                              deliveryLocation[
                                                                      'longitude'] ??
                                                                  0.0,
                                                        );
                                                      });
                                                    },
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      if (driver == null ||
                                          driver['name'] == null)
                                        const Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Driver:',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text('Not assigned'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            Gap(5),
                                            Divider(),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              );
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

// Route for the animated modal
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

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
