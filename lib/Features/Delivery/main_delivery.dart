import 'dart:convert';
// import 'dart:math';
import 'dart:ui';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';

class MainDeliveryScreen extends StatefulWidget {
  const MainDeliveryScreen({super.key});

  @override
  State<MainDeliveryScreen> createState() => _MainDeliveryScreenState();
}

class _MainDeliveryScreenState extends State<MainDeliveryScreen> {
  Future<Position>? _currentPositionFuture;
  Position? _currentPosition;
  LatLng? _destination;
  final TextEditingController _typeAheadController = TextEditingController();
  List<LatLng> _polylineCoordinates = [];
  // final double _averageSpeed = 50.0;
  GoogleMapController? _mapController;

  double? _distance;
  double? _timeRemaining;

  void _getCurrentLocationAndSetState() async {
    try {
      final position = await _currentPositionFuture;
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // Handle the error
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<String>> _getPlaceSuggestions(String input) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
    const String baseUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    final url = '$baseUrl?input=$input&key=$apiKey&components=country:tz';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final suggestions = (json['predictions'] as List)
          .map((prediction) => prediction['description'] as String)
          .toList();
      return suggestions;
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<void> _moveCameraToPlace(String place) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
    const String baseUrl =
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json';
    final url =
        '$baseUrl?input=$place&inputtype=textquery&fields=geometry&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final location = json['candidates'][0]['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);

      setState(() {
        _destination = latLng;
        _fetchRoute(_currentPosition!, latLng);
      });

      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    } else {
      throw Exception('Failed to load place details');
    }
  }

  Future<void> _fetchRoute(Position start, LatLng end) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineRequest polylineRequest = PolylineRequest(
      origin: PointLatLng(start.latitude, start.longitude),
      destination: PointLatLng(end.latitude, end.longitude),
      mode: TravelMode.driving, // Correct parameter name
    );

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: polylineRequest,
      googleApiKey: apiKey,
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
    }
  }

  // double _calculateDistance(LatLng start, LatLng end) {
  //   const double R = 6371;
  //   double lat1 = start.latitude * (pi / 180.0);
  //   double lon1 = start.longitude * (pi / 180.0);
  //   double lat2 = end.latitude * (pi / 180.0);
  //   double lon2 = end.longitude * (pi / 180.0);

  //   double dLat = lat2 - lat1;
  //   double dLon = lon2 - lon1;

  //   double a = (sin(dLat / 2) * sin(dLat / 2)) +
  //       (cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2));
  //   double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  //   double distance = R * c;
  //   return distance; // Distance in kilometers
  // }

  // double _calculateTime(double distance) {
  //   return distance / _averageSpeed;
  // }

  void _onMapTapped(LatLng position) {
    setState(() {
      _destination = position;
      _polylineCoordinates.clear(); // Clear previous polyline
      _fetchRoute(_currentPosition!, position); // Fetch new route
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(position));
  }

  @override
  void initState() {
    super.initState();
    _currentPositionFuture = _getCurrentLocation();
    _getCurrentLocationAndSetState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              FutureBuilder<Position>(
                future: _currentPositionFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * .9,
                      child: const Center(
                          child: SpinKitCircle(
                        color: Colors.blue,
                        size: 40,
                      )),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  } else if (snapshot.hasData) {
                    final position = snapshot.data!;
                    // Directly update the state variable without using setState
                    _currentPosition = position;

                    return Stack(
                      children: [
                        GoogleMap(
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          initialCameraPosition: CameraPosition(
                            target:
                                LatLng(position.latitude, position.longitude),
                            zoom: 15.0,
                          ),
                          markers: _destination != null
                              ? {
                                  Marker(
                                    markerId: const MarkerId('destination'),
                                    position: _destination!,
                                    infoWindow: const InfoWindow(
                                      title: 'Destination',
                                      snippet: 'You tapped here!',
                                    ),
                                  ),
                                }
                              : {},
                          polylines: _polylineCoordinates.isNotEmpty
                              ? {
                                  Polyline(
                                    polylineId: const PolylineId('route'),
                                    points: _polylineCoordinates,
                                    color: Colors.blue,
                                    width: 5,
                                  ),
                                }
                              : {},
                          onTap: _onMapTapped,
                          //myLocationEnabled: true,
                          // myLocationButtonEnabled: true,
                          compassEnabled: true,
                        ),

                        // Container(
                        //   height: 500,
                        //   color: Colors.blue,
                        // ),
                        Positioned(
                          top: 20.0,
                          left: 10.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10.0,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.0,
                                  ),
                                ),
                                if (_destination != null)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Destination: ${_destination!.latitude}, ${_destination!.longitude}',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                      if (_distance != null &&
                                          _timeRemaining != null)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Distance: ${_distance!.toStringAsFixed(2)} km',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.0,
                                              ),
                                            ),
                                            Text(
                                              'Time Remaining: ${_timeRemaining!.toStringAsFixed(2)} hours',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(
                      child: Text(
                        'No location data available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                          fontSize: 16.0,
                        ),
                      ),
                    );
                  }
                },
              ),
              Positioned(
                top: 10,
                left: 5,
                right: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10,
                      sigmaY: 10,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.2),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: TypeAheadField<String>(
                        suggestionsCallback: _getPlaceSuggestions,
                        itemBuilder: (context, String suggestion) {
                          return ListTile(
                            title: Text(suggestion),
                          );
                        },
                        onSelected: (String suggestion) {
                          _typeAheadController.text = suggestion;
                          _moveCameraToPlace(suggestion);
                        },
                        builder: (context, controller, focusNode) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              // border: OutlineInputBorder(
                              //   borderRadius: BorderRadius.circular(8),
                              // ),
                              prefixIcon: Icon(
                                Iconsax.search_normal,
                                color: Colors.white,
                              ),
                              border: InputBorder.none,
                              labelText: 'Search for a place',
                              labelStyle: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
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
        ),
      ),
    );
  }
}
