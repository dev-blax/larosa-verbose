import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:iconsax/iconsax.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:http/http.dart' as http;

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
  bool _connectedToSocket = false;
  late StompClient stompClient;
  final String socketChannel =
      '${LarosaLinks.baseurl}/ws/topic/customer/${AuthService.getProfileId()}';

  Future<void> _socketConnection2() async {
    const String wsUrl = 'https://exploretest.uc.r.appspot.com/ws';
    // final channel =
    //     IOWebSocketChannel.connect('https://exploretest.uc.r.appspot.com/ws');

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
      _connectedToSocket = true;
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

  @override
  void initState() {
    super.initState();
    // _stompController();
    _socketConnection2();
  }

  bool isRequestingRide = false;
  Future<void> _requestRide() async {
    setState(() {
      isRequestingRide = true;
    });
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer ${AuthService.getToken()}',
    };

    String endpoint =
        'https://exploretest.uc.r.appspot.com/api/v1/ride/request';

    try {
      var response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode({
          "startLat": -6.2395265,
          "startLng": 35.8273295,
          "endLat": -6.169613300000001,
          "endLng": 35.7774005,
          "vehicleType": "MOTORCYCLE",
          "paymentMethod": "CASH",
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Delivery'),
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
                          Iconsax.search_normal,
                          color: Colors.white,
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
                        border: InputBorder.none,
                        labelText: 'Search for a source location',
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              const Gap(10),
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
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Iconsax.search_normal,
                          color: Colors.white,
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
                        border: InputBorder.none,
                        labelText: 'Search for a destination',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              const Gap(10),
              FilledButton(
                onPressed: _requestRide,
                child: isRequestingRide
                    ? const SpinKitCircle(
                        color: Colors.white,
                        size: 20,
                      )
                    : const Text(
                        'Request a Ride',
                      ),
              ),
              const Gap(20),
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
              const Gap(20),
              const Text('Your Orders'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://images.pexels.com/photos/28975090/pexels-photo-28975090/free-photo-of-tranquil-boat-ride-on-yamuna-river-at-dusk.jpeg?auto=compress&cs=tinysrgb&w=600&lazy=load',
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const Gap(10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('MENS GRENET TITANIUM WATCH'),
                          const Gap(5),
                          Row(
                            children: [
                              Text(
                                'Mitra Collections',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: Colors.white),
                              ),
                              const Gap(5),
                              SvgPicture.asset(
                                SvgIconsPaths.sharpVerified,
                                colorFilter: const ColorFilter.mode(
                                  Colors.blue,
                                  BlendMode.srcIn,
                                ),
                                height: 18,
                              )
                            ],
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.location_searching),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://images.pexels.com/photos/28975090/pexels-photo-28975090/free-photo-of-tranquil-boat-ride-on-yamuna-river-at-dusk.jpeg?auto=compress&cs=tinysrgb&w=600&lazy=load',
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const Gap(10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('MENS GRENET TITANIUM WATCH'),
                          const Gap(5),
                          Row(
                            children: [
                              Text(
                                'Mitra Collections',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(color: Colors.white),
                              ),
                              const Gap(5),
                              SvgPicture.asset(
                                SvgIconsPaths.sharpVerified,
                                colorFilter: const ColorFilter.mode(
                                  Colors.blue,
                                  BlendMode.srcIn,
                                ),
                                height: 18,
                              )
                            ],
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.location_searching),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(100),
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
