import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:recase/recase.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../Services/auth_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/colors.dart';
import '../../Utils/helpers.dart';
import '../../Utils/links.dart';
import 'package:http/http.dart' as http;

class TimeEstimationsModalContent extends StatefulWidget {
  final Map<String, dynamic> estimations;
  final double sourceLatitude;
  final double sourceLongitude;
  final double destinationLatitude;
  final double destinationLongitude;

  const TimeEstimationsModalContent({
    Key? key,
    required this.estimations,
    required this.sourceLatitude,
    required this.sourceLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
  }) : super(key: key);

  @override
  _TimeEstimationsModalContentState createState() =>
      _TimeEstimationsModalContentState();
}

class _TimeEstimationsModalContentState
    extends State<TimeEstimationsModalContent> {
  final Set<Marker> _markers = {};

  bool isRequestingRide = false;

  String paymentMethod = 'CASH';

  String? _city; // Holds the current region (city)

  final Set<Polyline> _polylines = {};

  late GoogleMapController _mapController;

  // Fetch current location and city (filtered for administrative region)
  Future<void> _updateCurrentCityFromLocation() async {
    try {
      // Request location permission if necessary
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are denied.');
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Perform reverse geocoding to get the administrative region
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String? administrativeRegion = place.administrativeArea;

        if (administrativeRegion != null) {
          // Remove unwanted terms from the administrative region name
          const List<String> unwantedTerms = ['Mkoa wa', 'Region'];
          for (String term in unwantedTerms) {
            administrativeRegion =
                administrativeRegion?.replaceAll(term, '').trim();
          }

          // Capitalize the region name properly
          administrativeRegion = administrativeRegion
              ?.split(' ')
              .map((word) => word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : '')
              .join(' ');

          setState(() {
            _city = administrativeRegion
                ?.toLowerCase(); // Set the cleaned administrative region as the city
            LogService.logInfo('Current administrative region set to: $_city');
          });

          // Reconnect WebSocket to subscribe to the new city
          // _socketConnection2();
        } else {
          LogService.logWarning('Administrative region is null.');
        }
      }
    } catch (e) {
      LogService.logError(
          'Error fetching administrative region from location: $e');
    }
  }

  bool connectedToSocket = false;

  late StompClient stompClient;

  StompClient? _stompClient;
  void _connectToStomp() {
    _stompClient = StompClient(
      config: StompConfig(
        url: LarosaLinks.baseWsUrl,
        onConnect: _onStompConnect,
        onWebSocketError: (dynamic error) {
          setState(() {
            // isLoading = false; // Stop shimmer on WebSocket failure
          });
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _stompClient!.activate();
  }

  void _onStompConnect(StompFrame frame) {
    print('Connected to WebSocket server: ${frame.headers}');

    // Subscribe to the driver-specific topic
    // _stompClient!.subscribe(
    //   destination: '/topic/driver/$driverId', // Use driverId from Hive
    //   callback: (StompFrame message) {
    //     final messageBody = message.body;
    //     if (messageBody != null) {
    //       print('Update for driver ($driverId): $messageBody');
    //     }
    //   },
    // );

    // Subscribe to the city topic for location updates
    // _stompClient!.subscribe(
    //   destination: '/topic/$_city',
    //   callback: (StompFrame message) {
    //     final messageBody = message.body;
    //     if (messageBody != null) {
    //       print('Location update for city ($_city): $messageBody');
    //       final locationUpdate = _parseLocationUpdate(messageBody);
    //       if (locationUpdate != null) {
    //         print(
    //             'Latitude: ${locationUpdate['latitude']}, Longitude: ${locationUpdate['longitude']}');
    //       }
    //     }
    //   },
    // );

    _stompClient!.subscribe(
      destination: '/topic/$_city}',
      callback: (StompFrame message) {
        final messageBody = message.body;
        // if (messageBody != null) {
        final data = jsonDecode(messageBody!);
        HelperFunctions.larosaLogger('Update for driver larosa : $messageBody');
        // } else {
        //   print('Message body is null.');
        // }
      },
    );

    HelperFunctions.larosaLogger('Successfully subscribed to /topic/$_city');

    // Send the initial driver location update
    // if (_latitude != null && _longitude != null) {
    //   _sendDriverLocationUpdate(_latitude!, _longitude!);
    // }
  }

  Future<void> _requestRide({required String selectedVehicleType}) async {
    if (widget.sourceLatitude == null ||
        widget.sourceLongitude == null ||
        widget.destinationLatitude == null ||
        widget.destinationLongitude == null) {
      HelperFunctions.showToast(
        'Please Enter Pickup and Destination location',
        true,
      );
      LogService.logError("Source or Destination coordinates are missing.");
      return;
    }

    setState(() {
      isRequestingRide = true;
    });

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer ${AuthService.getToken()}',
    };

    String endpoint = '${LarosaLinks.baseurl}/api/v1/ride/request';

    try {
      LogService.logDebug(
          "Fetching country and city for source and destination...");

      // Get country and city for source
      final sourceLocation = await getCountryAndCity(
          widget.sourceLatitude!, widget.sourceLongitude!);
      final destinationLocation = await getCountryAndCity(
          widget.destinationLatitude!, widget.destinationLongitude!);

      LogService.logDebug("Source Location: $sourceLocation");
      LogService.logDebug("Destination Location: $destinationLocation");

      String sourceCity = (() {
        String cityName = sourceLocation['city'] ?? 'Unknown';
        if (cityName == 'Unknown' || cityName.isEmpty) {
          LogService.logWarning(
              'Source city is invalid. Falling back to default.');
          return 'Dodoma';
        }
        const unwantedWords = ['Region', 'Mkoa wa'];
        for (String word in unwantedWords) {
          cityName = cityName.replaceAll(word, '').trim();
        }
        return cityName
            .split(' ')
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
      })();

      final requestBody = {
        "startLat": widget.sourceLatitude,
        "startLng": widget.sourceLongitude,
        "endLat": widget.destinationLatitude,
        "endLng": widget.destinationLongitude,
        "vehicleType": selectedVehicleType,
        "paymentMethod": paymentMethod,
        "country": sourceLocation['country'],
        "city": sourceCity,
      };

      LogService.logDebug("Request Body: ${jsonEncode(requestBody)}");
      LogService.logDebug("Making POST request to $endpoint");

      var response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      LogService.logDebug("Response Status Code: ${response.statusCode}");
      LogService.logDebug("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logInfo('Ride request successful');

        // Trigger success modal
        // showSuccessModal(context, "Your ride request was successful!");

        HelperFunctions.showNotification(
          title: 'Success',
          body: 'Your ride request has been submitted successfully!',
        );

        setState(() {
          isRequestingRide = true;
        });
      } else if (response.statusCode == 400) {
        LogService.logError(
            'Bad Request: ${response.body}. Possible issues with data.');
        HelperFunctions.showToast(
          'Failed to submit the ride request. Please check your input.',
          true,
        );
      } else if (response.statusCode == 401) {
        LogService.logError('Unauthorized: Refreshing token and retrying...');
        await AuthService.refreshToken();
        await _requestRide(selectedVehicleType: selectedVehicleType);
      } else {
        LogService.logError('Ride request failed: ${response.statusCode}');
        HelperFunctions.showToast(
          'Something went wrong. Please try again later.',
          true,
        );
      }
    } catch (e, stackTrace) {
      LogService.logError('Error making ride request: $e');
      LogService.logDebug('Stack Trace: $stackTrace');
      HelperFunctions.showToast('An unexpected error occurred.', true);
    } finally {
      setState(() {
        isRequestingRide = false;
      });
    }
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

  @override
  void initState() {
    super.initState();

    _initializeMarkers();
    _drawRoute();
    _updateCurrentCityFromLocation();
    _connectToStomp();
  }

  void _initializeMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('source'),
        position: LatLng(widget.sourceLatitude, widget.sourceLongitude),
        infoWindow: const InfoWindow(title: 'Source Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position:
            LatLng(widget.destinationLatitude, widget.destinationLongitude),
        infoWindow: const InfoWindow(title: 'Destination Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _drawRoute() async {
    String apiKey =
        dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!; // Replace with your API key
    const String baseUrl =
        'https://maps.googleapis.com/maps/api/directions/json';

    final String request =
        '$baseUrl?origin=${widget.sourceLatitude},${widget.sourceLongitude}&destination=${widget.destinationLatitude},${widget.destinationLongitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(request));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if ((data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0]['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(route);

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: decodedPoints,
                color: Colors.blue,
                width: 5,
              ),
            );
          });

          // Fit both source and destination points in view
          _fitMapToBounds(decodedPoints);
        } else {
          print('No routes found.');
        }
      } else {
        print('Failed to fetch route. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _fitMapToBounds(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    LatLngBounds bounds;
    if (points.length == 1) {
      bounds = LatLngBounds(southwest: points.first, northeast: points.first);
    } else {
      final southwestLat =
          points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
      final southwestLng =
          points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
      final northeastLat =
          points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
      final northeastLng =
          points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

      bounds = LatLngBounds(
        southwest: LatLng(southwestLat, southwestLng),
        northeast: LatLng(northeastLat, northeastLng),
      );
    }

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // Add padding for better view
    );
  }

  Widget getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'motorcycle':
        return const Icon(Icons.motorcycle, color: Colors.blue);
      case 'bajaj':
        return const Icon(Icons.electric_rickshaw, color: Colors.orange);
      case 'larosamini':
        return const Icon(Icons.directions_car, color: Colors.green);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey); // Default icon
    }
  }

  String _formatVehicleType(String vehicleType) {
  if (vehicleType.toLowerCase().contains('mini')) {
    return 'Larosa Mini';
  } else if (vehicleType.toLowerCase().contains('max')) {
    return 'Larosa Max';
  } else {
    return vehicleType.sentenceCase; // Converts to "Sentence case"
  }
}


  @override
  Widget build(BuildContext context) {
    // print('Destination Latitude: ${widget.destinationLatitude}, Destination Longitude: ${widget.destinationLongitude}');
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, // Occupy 90% height
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Modal handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Google Map Section
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.sourceLatitude, widget.sourceLongitude),
                  zoom: 12.0,
                ),
                markers: _markers,
                polylines: _polylines,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
                myLocationEnabled: true,
                mapToolbarEnabled: true,
                indoorViewEnabled: true,
                buildingsEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Fit map bounds once the map is created
                  _fitMapToBounds([
                    LatLng(widget.sourceLatitude, widget.sourceLongitude),
                    LatLng(widget.destinationLatitude,
                        widget.destinationLongitude),
                  ]);
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Expandable Driver Availability Section
          ExpansionTile(
            initiallyExpanded: true,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon(
                    //   Icons.directions_car,
                    //   color: Colors.blueAccent,
                    //   size: 20,
                    // ),
                    // SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Driver Availability and Travel Time",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Divider(thickness: 1, color: Colors.grey),
              ],
            ),
            // children: [
            //   ...widget.estimations.entries.map((entry) {
            //     final vehicleType = entry.key;
            //     final data = entry.value;

            //     if (data.containsKey('message')) {
            //       return Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           Text(
            //             vehicleType
            //                 .sentenceCase, // Converts the text to "Sentence case"
            //             style: const TextStyle(
            //               fontWeight: FontWeight.w600,
            //               fontSize: 14,
            //             ),
            //           ),
            //           Padding(
            //             padding: const EdgeInsets.only(left: 8.0),
            //             child: Text(
            //               data['message'],
            //               style: const TextStyle(
            //                 fontSize: 12,
            //                 color: Colors.red,
            //                 fontStyle: FontStyle.italic,
            //               ),
            //             ),
            //           ),
            //           const Divider(thickness: 0.5),
            //         ],
            //       );
            //     }

            //     return Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           vehicleType
            //               .sentenceCase, // Convert "MOTORCYCLE" to "Motorcycle"
            //           style: const TextStyle(
            //             fontWeight: FontWeight.w600,
            //             fontSize: 14,
            //           ),
            //         ),
            //         Padding(
            //           padding: const EdgeInsets.only(left: 8.0),
            //           child: Column(
            //             children: [
            //               Row(
            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                 children: [
            //                   const Text("Closest Driver:"),
            //                   Text(data['closestDriver']),
            //                 ],
            //               ),
            //               Row(
            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                 children: [
            //                   const Text("Time to Customer:"),
            //                   Text(formatTime(data['timeToCustomer'])),
            //                 ],
            //               ),
            //               Row(
            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                 children: [
            //                   const Text("Travel Time:"),
            //                   Text(formatTime(
            //                       data['timeFromCustomerToDestination'])),
            //                 ],
            //               ),
            //             ],
            //           ),
            //         ),
            //         const SizedBox(height: 8),
            //         Container(
            //           width: double.infinity,
            //           decoration: BoxDecoration(
            //             gradient: const LinearGradient(
            //               colors: [LarosaColors.secondary, LarosaColors.purple],
            //               begin: Alignment.topLeft,
            //               end: Alignment.bottomRight,
            //             ),
            //             borderRadius: BorderRadius.circular(30),
            //           ),
            //           child: FilledButton(
            //             style: ButtonStyle(
            //               backgroundColor:
            //                   WidgetStateProperty.all(Colors.transparent),
            //               padding: WidgetStateProperty.all(
            //                 const EdgeInsets.symmetric(vertical: 10),
            //               ),
            //               shape: WidgetStateProperty.all(
            //                 RoundedRectangleBorder(
            //                   borderRadius: BorderRadius.circular(30),
            //                 ),
            //               ),
            //             ),
            //             onPressed: isRequestingRide
            //                 ? null
            //                 : () =>
            //                     _requestRide(selectedVehicleType: vehicleType),
            //             child: isRequestingRide
            //                 ? const CupertinoActivityIndicator(
            //                     color: Colors.white,
            //                     radius: 10.0,
            //                   )
            //                 : const Text(
            //                     'Confirm Ride Request',
            //                     style: TextStyle(
            //                       color: Colors.white,
            //                       fontWeight: FontWeight.w600,
            //                       letterSpacing: 1.0,
            //                     ),
            //                   ),
            //           ),
            //         ),
            //         const SizedBox(height: 6),
            //       ],
            //     );
            //   }),
            // ],

            children: [
  ...widget.estimations.entries.map((entry) {
    final vehicleType = entry.key;
    final data = entry.value;

    if (data.containsKey('message')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
  children: [
    getVehicleIcon(vehicleType), // Dynamically get the icon
    const SizedBox(width: 8),
    Text(
      _formatVehicleType(vehicleType), // Call a helper method to format the text
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    ),
  ],
),

          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              data['message'],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Divider(thickness: 0.5),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            getVehicleIcon(vehicleType), // Dynamically get the icon
            const SizedBox(width: 8),
            Text(
              vehicleType.sentenceCase, // Convert "MOTORCYCLE" to "Motorcycle"
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Closest Driver:"),
                  Text(data['closestDriver']),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Time to Customer:"),
                  Text(formatTime(data['timeToCustomer'])),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Travel Time:"),
                  Text(formatTime(data['timeFromCustomerToDestination'])),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
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
                const EdgeInsets.symmetric(vertical: 10),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            onPressed: isRequestingRide
                ? null
                : () => _requestRide(selectedVehicleType: vehicleType),
            child: isRequestingRide
                ? const CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: 10.0,
                  )
                : const Text(
                    'Confirm Ride Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }),
],

          ),
        ],
      ),
    );
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
}
