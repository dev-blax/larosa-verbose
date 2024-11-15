import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
import '../../Utils/wavy_border_painter.dart';
import 'explore_services.dart';

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
  bool connectedToSocket = false;
  String paymentMethod = 'CASH';
  String vehicleType = 'MOTORCYCLE';
  List<dynamic> orders = [];
  late StompClient stompClient;
  final String socketChannel =
      '${LarosaLinks.baseurl}/ws/topic/customer/${AuthService.getProfileId()}';

Future<void> _socketConnection2() async {
    const String wsUrl = 'https://exploretest.uc.r.appspot.com/ws';
    stompClient = StompClient(
      config: StompConfig.sockJS(
        url: wsUrl,
        onConnect: onConnect,
        onWebSocketError: (dynamic error) =>
            LogService.logError('WebSocket error: $error'),
        onStompError: (StompFrame frame) =>
            LogService.logWarning('Stomp error: ${frame.body}'),
        onDisconnect: (StompFrame frame) =>
            LogService.logFatal('Disconnected from WebSocket'),
      ),
    );
    stompClient.activate();
  }

  // Callback for handling successful connection
  void onConnect(StompFrame frame) {
    setState(() {
      connectedToSocket = true;
    });
    LogService.logInfo('Connected to WebSocket server: $frame');

    stompClient.subscribe(
      destination: '/topic/customer/${AuthService.getProfileId()}',
      callback: (StompFrame message) {
        LogService.logInfo(
          'Received message from /topic/customer/${AuthService.getProfileId()}: ${message.body}',
        );

        HelperFunctions.showToast(
          message.body.toString(),
          true,
        );
      },
    );

    LogService.logInfo('Successfully subscribed to /topic/customer/48');
  }

  Future<void> _asyncInit() async {
    await _socketConnection2();
    _loadOrders();
  }

  @override
  void initState() {
    super.initState();
    _asyncInit();
  }

  bool isRequestingRide = false;
  Future<void> _requestRide() async {
    if (sourceLatitude == null ||
        sourceLongitude == null ||
        destinationLatitude == null ||
        destinationLongitude == null) {
      HelperFunctions.showToast(
        'Please Enter Pickup and Destination location',
        true,
      );
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
      var response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode({
          "startLat": sourceLatitude,
          "startLng": sourceLongitude,
          "endLat": destinationLatitude,
          "endLng": destinationLongitude,
          "vehicleType": vehicleType,
          "paymentMethod": paymentMethod,
          "country": "Tanzania",
          "city": "Dodoma"
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logInfo('Cool');
        HelperFunctions.showToast(
          'We received your ride request',
          true,
        );
        return;
      }

      if (response.statusCode == 401) {
        await AuthService.refreshToken();
        await _requestRide();
      }

      LogService.logError('Not cool, response: ${response.statusCode} ');
    } catch (e) {
      LogService.logError('error $e');
    } finally {
      setState(() {
        isRequestingRide = false;
      });
    }
  }

  Future<List<Map<String, String>>> _getPlaceSuggestions(String input) async {
    final String apiKey = dotenv.env['GOOGLE_MAPS_PLACES_API_KEY']!;
    const String baseUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    final url = '$baseUrl?input=$input&key=$apiKey&components=country:tz';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final suggestions = (json['predictions'] as List)
          .map((prediction) => {
                'description': prediction['description'] as String,
                'place_id': prediction['place_id'] as String,
              })
          .toList();
      return suggestions;
    } else {
      throw Exception('Failed to load suggestions');
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
              _sourceController.text = address;
              isLoadingSource = false;
            } else {
              destinationLatitude = lat;
              destinationLongitude = lng;
              selectedDestinationStreetName = address;
              _destinationController.text = address;
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
        });
        return;
      }

      LogService.logError('error: ${response.statusCode}');
    } catch (e) {
      LogService.logError('failed $e');
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
        String address = '${place.name}, ${place.locality}, ${place.country}';

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
        automaticallyImplyLeading: false,
        title: const Text('Delivery'),
        centerTitle: true,
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
                    return ListTile(
                      title: Text(suggestion['description']!),
                    );
                  },
                  onSelected: (Map<String, String> suggestion) async {
                    _sourceController.text = suggestion['description']!;
                    final placeId = suggestion['place_id']!;
                    await _getPlaceDetails(placeId, true);
                  },
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          CupertinoIcons.pin,
                          // color: Colors.white,
                        ),
                        suffixIcon: isLoadingSource
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 1,
                                  width: 1,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Ionicons.locate),
                                onPressed: () => _getCurrentLocation(true),
                              ),
                        // border: InputBorder.none,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8.0), // Rounded border
                          borderSide: const BorderSide(
                            color: LarosaColors.primary, // Border color
                            width: 1.0, // Border width
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: LarosaColors
                                .primary, // Border color when enabled
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: LarosaColors
                                .primary, // Border color when focused
                            width: 2.0,
                          ),
                        ),
                        labelText: 'Pickup location',
                        // labelStyle: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              const Gap(5),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TypeAheadField<Map<String, String>>(
                  suggestionsCallback: _getPlaceSuggestions,
                  itemBuilder: (context, Map<String, String> suggestion) {
                    return ListTile(
                      title: Text(suggestion['description']!),
                    );
                  },
                  onSelected: (Map<String, String> suggestion) async {
                    _destinationController.text = suggestion['description']!;
                    final placeId = suggestion['place_id']!;
                    await _getPlaceDetails(placeId, false);
                  },
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          CupertinoIcons.location_circle,
                          // color: Colors.white,
                        ),
                        suffixIcon: isLoadingSource
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 1,
                                  width: 1,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Ionicons.locate),
                                onPressed: () => _getCurrentLocation(true),
                              ),
                        // suffixIcon: isLoadingDestination
                        //     ? const Padding(
                        //         padding: EdgeInsets.all(8.0),
                        //         child: SpinKitCircle(
                        //           color: Colors.blue,
                        //         ),
                        //       )
                        //     : IconButton(
                        //         icon: const Icon(Ionicons.locate),
                        //         onPressed: () => _getCurrentLocation(false),
                        //       ),
                        // border: InputBorder.none,

                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(8.0), // Rounded border
                          borderSide: const BorderSide(
                            color: LarosaColors.primary, // Border color
                            width: 1.0, // Border width
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: LarosaColors
                                .primary, // Border color when enabled
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(
                            color: LarosaColors
                                .primary, // Border color when focused
                            width: 2.0,
                          ),
                        ),

                        labelText: 'Destination',
                        // labelStyle: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              const Gap(5),
              isRequestingRide
                  ? SpinKitCircle(
                      color: Theme.of(context).colorScheme.primary,
                      size: 40,
                    )
                  : Container(
  padding: const EdgeInsets.symmetric(horizontal: 10), // Adjust horizontal padding
  decoration: BoxDecoration(
    gradient: const LinearGradient(
      colors: [LarosaColors.secondary, LarosaColors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(30), // Rounded corners
  ),
  child: FilledButton(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(Colors.transparent),
      padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Ensures button shape matches container
        ),
      ),
    ),
    onPressed: _requestRide,
    child: const Text(
      'Request a Ride',
      style: TextStyle(color: Colors.white, fontSize: 14), // Ensures text is readable
    ),
  ),
),
              const Gap(10),
              if (selectedSourceStreetName != null &&
                  sourceLatitude != null &&
                  sourceLongitude != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Source Location'),
                      Text('Street: $selectedSourceStreetName'),
                      Text('Latitude: $sourceLatitude'),
                      Text('Longitude: $sourceLongitude'),
                    ],
                  ),
                ),
              if (selectedDestinationStreetName != null &&
                  destinationLatitude != null &&
                  destinationLongitude != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Destination Location'),
                      Text('Street: $selectedDestinationStreetName'),
                      Text('Latitude: $destinationLatitude'),
                      Text('Longitude: $destinationLongitude'),
                    ],
                  ),
                ),
              const Gap(5),

              // List of Order Tiles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Orders',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Gap(5),
                    ListView.builder(
                      shrinkWrap: true, // Ensures ListView takes only required space
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        String status = order['status'];
                        return Padding(
  padding: const EdgeInsets.symmetric(horizontal: 1.0), // Adjust the padding as needed
  child: Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 5),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 5.0), // Adjust inner padding
      title: Text('Order ID: ${order['orderId']}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pickup: ${order['pickup']}'),
          Text('Destination: ${order['destination']}'),
          Text('Status: ${order['status']}'),
        ],
      ),
      trailing: Icon(
        order['status'] == 'Completed'
            ? CupertinoIcons.check_mark_circled_solid
            : CupertinoIcons.clock,
        color: order['status'] == 'Completed' ? Colors.green : Colors.orange,
      ),
    ),
  ),
);

                      },
                    ),

                    const SizedBox(height: 70,)
                  ],
                ),
              ),
            ],
          ),

          // Positioned Floating Action Button in the middle right of the screen
          Positioned(
  right: 20, // Adjust the right padding as needed
  top: MediaQuery.of(context).size.height / 2 - 28, // Center vertically
  child: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [LarosaColors.secondary, LarosaColors.purple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shape: BoxShape.circle,
    ),
    child: FloatingActionButton(
      onPressed: () {
        // When clicked, open the explore modal
        Navigator.of(context).push(_createRoute());
      }, // Explore icon instead of add icon
      backgroundColor: Colors.transparent, // Make FAB background transparent
      elevation: 0,
      child: const Icon(Icons.explore), // Optional: removes shadow to make the gradient stand out
    ),
  ),),
          
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
