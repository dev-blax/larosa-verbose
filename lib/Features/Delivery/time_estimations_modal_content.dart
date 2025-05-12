import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:recase/recase.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../Services/auth_service.dart';
import '../../Services/fcm_service.dart';
import '../../Services/hive_service.dart';
import '../../Services/log_service.dart';
import '../../Utils/colors.dart';
import '../../Utils/helpers.dart';
import '../../Utils/links.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;

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
  final HiveService hiveService = HiveService();
  String? activeRideType;

  late BitmapDescriptor _driverIcon;

  // new: holds the latest driver-info payload
  Map<String, dynamic>? driverInfo;
  // new: subscription so we can cancel on dispose
  StreamSubscription<Map<String, dynamic>>? _driverInfoSub;

  final Set<Marker> _markers = {};

  bool isRequestingRide = false;

  String paymentMethod = 'CASH';

  // String? _city;

  final Set<Polyline> _polylines = {};

  late GoogleMapController _mapController;

  late StompClient _stompClient;
  String? _city;
  String? _driverId;

  final _currencyFormatter = NumberFormat.decimalPattern();
// or, if you want no decimal digits: NumberFormat('#,##0', 'en_US');

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

  // Future<void> _loadDriverIcon() async {
  //   _driverIcon = await BitmapDescriptor.fromAssetImage(
  //     const ImageConfiguration(size: Size(48, 48)),
  //     'assets/icons/driver_pin.png', // ← your beautifully designed pin
  //   );
  // }

  /// Creates a BitmapDescriptor by drawing your driver icon
  /// and a chat-badge with the given [timeText].
  Future<BitmapDescriptor> _createDriverMarkerWithBadge(
    String assetPath,
    int width,
    String timeText,
  ) async {
    // Load base icon
    final byteData = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      byteData.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    final iconImage = frame.image;

    // Start canvas
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Draw driver icon
    canvas.drawImage(iconImage, Offset.zero, paint);

    // Badge parameters (large, readable)
    const badgePadding = 32.0;
    const badgeHeight = 60.0;
    final fontSize = 28.0;

    // Prepare text
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      maxLines: 1,
    );
    final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(timeText);
    final constraints = ui.ParagraphConstraints(
      width: width.toDouble(),
    );
    final paragraph = paragraphBuilder.build()..layout(constraints);

    // Calculate badge size & position
    final badgeWidth = paragraph.maxIntrinsicWidth + badgePadding * 2;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (width - badgeWidth) / 2, // center horizontally
        iconImage.height + 8, // small gap below icon
        badgeWidth,
        badgeHeight,
      ),
      Radius.circular(badgeHeight / 2), // <-- Fully rounded like a pill
    );

    // 🟦 Draw badge background with LarosaColors.primary
    paint.color = LarosaColors.primary; // Or LarosaColors.primary
    canvas.drawRRect(badgeRect, paint);

    // Draw text inside badge
    canvas.drawParagraph(
      paragraph,
      Offset(
        badgeRect.left +
            (badgeWidth - paragraph.width) / 2, // center text properly
        badgeRect.top + (badgeHeight - paragraph.height) / 2,
      ),
    );

    // End recording & convert
    final picture = recorder.endRecording();
    final img = await picture.toImage(
      width,
      iconImage.height + badgeHeight.toInt() + 8,
    );
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(pngBytes!.buffer.asUint8List());
  }

//  Future<void> _loadDriverIcon() async {
//   final Uint8List markerBytes =
//       await _getBytesFromAsset('assets/icons/driver_pin.png', 84);
//   _driverIcon = BitmapDescriptor.fromBytes(markerBytes);
//   setState(() {});  // make sure anything depending on _driverIcon rebuilds
// }

  Future<void> _loadDriverIcon() async {
    _driverIcon = await _createDriverMarkerWithBadge(
      'assets/icons/driver_pin.png',
      84,
      '5 M', // placeholder until you wire real-time data
    );
    setState(() {});
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData =
        await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // StompClient? _stompClient;
  // void _connectToStomp() {
  //   _stompClient = StompClient(
  //     config: StompConfig(
  //       url: LarosaLinks.baseWsUrl,
  //       onConnect: _onStompConnect,
  //       onWebSocketError: (dynamic error) {
  //         setState(() {
  //           // isLoading = false; // Stop shimmer on WebSocket failure
  //         });
  //       },
  //       reconnectDelay: const Duration(seconds: 5),
  //     ),
  //   );

  //   _stompClient!.activate();
  // }

  Future<void> _connectToStomp() async {
    final token = await AuthService.getToken();

    _stompClient = StompClient(
      config: StompConfig(
        url: LarosaLinks.baseWsUrl, // e.g. 'wss://…/ws'
        stompConnectHeaders: {
          // send your Bearer token
          'Authorization': 'Bearer $token',
        },
        onConnect: _onStompConnect,
        onWebSocketError: (err) => LogService.logError('WS error: $err'),
        onStompError: (frame) => LogService.logError(
            'STOMP ERROR cmd=${frame.command} hdrs=${frame.headers} body=${frame.body}'),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _stompClient.activate();
  }

  // void _onStompConnect(StompFrame frame) {
  //   print('Connected to WebSocket server: ${frame.headers}');

  //   // Subscribe to the driver-specific topic
  //   // _stompClient!.subscribe(
  //   //   destination: '/topic/driver/$driverId', // Use driverId from Hive
  //   //   callback: (StompFrame message) {
  //   //     final messageBody = message.body;
  //   //     if (messageBody != null) {
  //   //       print('Update for driver ($driverId): $messageBody');
  //   //     }
  //   //   },
  //   // );

  //   // Subscribe to the city topic for location updates
  //   // _stompClient!.subscribe(
  //   //   destination: '/topic/$_city',
  //   //   callback: (StompFrame message) {
  //   //     final messageBody = message.body;
  //   //     if (messageBody != null) {
  //   //       print('Location update for city ($_city): $messageBody');
  //   //       final locationUpdate = _parseLocationUpdate(messageBody);
  //   //       if (locationUpdate != null) {
  //   //         print(
  //   //             'Latitude: ${locationUpdate['latitude']}, Longitude: ${locationUpdate['longitude']}');
  //   //       }
  //   //     }
  //   //   },
  //   // );

  //   _stompClient!.subscribe(
  //     destination: '/topic/$_city}',
  //     callback: (StompFrame message) {
  //       final messageBody = message.body;
  //       // if (messageBody != null) {
  //       final data = jsonDecode(messageBody!);
  //       HelperFunctions.larosaLogger('Update for driver larosa : $messageBody');
  //       // } else {
  //       //   print('Message body is null.');
  //       // }
  //     },
  //   );

  //   HelperFunctions.larosaLogger('Successfully subscribed to /topic/$_city');

  //   // Send the initial driver location update
  //   // if (_latitude != null && _longitude != null) {
  //   //   _sendDriverLocationUpdate(_latitude!, _longitude!);
  //   // }
  // }

  void _onStompConnect(StompFrame frame) {
    LogService.logInfo('STOMP CONNECTED — headers: ${frame.headers}');

    if (_city == null || _city!.isEmpty) {
      LogService.logError('⚠️ City is null or empty, cannot subscribe');
      return;
    }

    // final topic = '/topic/${_city!}';
    final topic = '/topic/dodoma';
    LogService.logInfo('👉 Subscribing to $topic');
    _stompClient.subscribe(
      destination: topic,
      callback: (StompFrame f) {
        try {
          final data = jsonDecode(f.body!);
          LogService.logInfo('⬇️ Message on $topic: $data');

          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          _updateDriverMarker(lat, lng);
        } catch (e) {
          LogService.logError('Failed to parse STOMP message: $e');
        }
      },
    );
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
        // "startLat": widget.sourceLatitude,
        // "startLng": widget.sourceLongitude,
        // "endLat": widget.destinationLatitude,
        // "endLng": widget.destinationLongitude,
        "vehicleType": selectedVehicleType,
        "paymentMethod": paymentMethod,
        // "country": sourceLocation['country'],
        // "city": sourceCity,

        "startLat": -6.1620,
        "startLng": 35.7516,
        "endLat": -6.1750,
        "endLng": 35.7497,
        "country": "Tanzania",
        "city": "Dodoma",
        // "cityName": "Dodoma"
      };

      LogService.logDebug("Request Body: ${jsonEncode(requestBody)}");
      LogService.logDebug("Making POST request to $endpoint");

      var response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('frs 12343242456346452345234 : ${requestBody}');

      LogService.logDebug("frs Response Status Code: ${response.statusCode}");
      LogService.logDebug("frs Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        LogService.logInfo('Ride request successful');

        // Trigger success modal
        // showSuccessModal(context, "Your ride request was successful!");

        hiveService.putData(
            'bookingBox', 'activeRideType', selectedVehicleType);
        setState(() => activeRideType = selectedVehicleType);
        HelperFunctions.showNotification(
          title: 'Booked',
          body: 'Your $selectedVehicleType ride is confirmed!',
        );

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

// And in your widget:
  void _cancelBooking() async {
    // Explicitly tell Dart that this is a Box<String>
    await hiveService.deleteData<String>('bookingBox', 'activeRideType');
    setState(() => activeRideType = null);
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

  // void _updateDriverMarker(double lat, double lng) {
  //   final id = const MarkerId('driver');
  //   // Remove old driver marker (if any)
  //   _markers.removeWhere((m) => m.markerId == id);
  //   // Add new one
  //   _markers.add(
  //     Marker(
  //       markerId: id,
  //       position: LatLng(lat, lng),
  //       icon: _driverIcon,
  //       infoWindow: const InfoWindow(title: 'Your driver'),
  //     ),
  //   );
  //   // Optionally recenter map on driver:
  //   _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  //   setState(() {});
  // }

  void _updateDriverMarker(double lat, double lng) {
    final id = const MarkerId('driver');

    // Remove any old driver marker
    _markers.removeWhere((m) => m.markerId == id);

    // Add the new one
    _markers.add(
      Marker(
        markerId: id,
        position: LatLng(lat, lng),
        icon: _driverIcon,
        infoWindow: const InfoWindow(title: 'Your driver'),
      ),
    );

    // Optionally move the camera
    if (_mapController != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(LatLng(lat, lng)),
      );
    }

    setState(() {});
  }

  // @override
  // void initState() {
  //   super.initState();

  //   // Load any previously booked ride
  //   activeRideType =
  //       hiveService.getData<String>('bookingBox', 'activeRideType');

  //   _initializeMarkers();
  //   _drawRoute();
  //   _updateCurrentCityFromLocation();
  //   // _connectToStomp();

  //   _loadDriverIcon().then((_) {
  //     // 1) Get city, then…
  //     _updateCurrentCityFromLocation().then((_) async {
  //       // 2) Ensure 'userBox' is open, then read profileId
  //       Box box;
  //       if (Hive.isBoxOpen('userBox')) {
  //         box = Hive.box('userBox');
  //       } else {
  //         box = await Hive.openBox('userBox');
  //       }

  //       _driverId = box.get('profileId')?.toString() ??
  //           AuthService.getProfileId().toString();

  //       // 3) Now finally connect
  //       _connectToStomp();
  //     });
  //   });
  // }

  @override
  void initState() {
    super.initState();
    _bootstrap();

    // ─── subscribe to driver-info FCM stream
    _driverInfoSub = FcmService()
        .driverInfoStream
        .listen((payload) => setState(() => driverInfo = payload));

    // ─── rehydrate any cached payload (background case)
    _rehydrateDriverInfo();
  }

  Future<void> _bootstrap() async {
    // 1️⃣ Load your custom driver icon
    await _loadDriverIcon();

    // 2️⃣ Read any previously booked ride
    activeRideType = hiveService.getData<String>(
      'bookingBox',
      'activeRideType',
    );

    // 3️⃣ Add source/destination markers & draw your route
    _initializeMarkers();
    await _drawRoute();

    // 4️⃣ Reverse‐geocode your current city
    await _updateCurrentCityFromLocation();

    // 5️⃣ Open Hive userBox and read profileId
    Box userBox;
    if (Hive.isBoxOpen('userBox')) {
      userBox = Hive.box('userBox');
    } else {
      userBox = await Hive.openBox('userBox');
    }
    _driverId = userBox.get('profileId')?.toString() ??
        AuthService.getProfileId().toString();

    // 6️⃣ Finally connect to STOMP (driver icon is loaded, city & driverId set)
    _connectToStomp();
  }

  Future<void> _rehydrateDriverInfo() async {
    final box = await Hive.openBox('fcmCache');
    final cached = box.get('latest_driver_info');
    if (cached != null) {
      box.delete('latest_driver_info');
      setState(() => driverInfo = Map<String, dynamic>.from(cached));
    }
  }

  @override
  void dispose() {
    _stompClient.deactivate();
    _driverInfoSub?.cancel();
    _stompClient.deactivate();
    super.dispose();
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
        return const Icon(Icons.help_outline,
            color: Colors.grey); // Default icon
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
//     // final vehicles = widget.estimations['vehicleEstimations'] as List<dynamic>;
    final distance = (widget.estimations['distance'] as num).toDouble();
//     final currency = widget.estimations['currency'] as String;

//     // 1) Pull in the raw list
//     final rawVehicles =
//         widget.estimations['vehicleEstimations'] as List<dynamic>;
//     final vehicles = rawVehicles.map((v) => v as Map<String, dynamic>).toList();

// // 2) Sort: available (pickupDuration>0) first, then the rest
//     final sortedVehicles = [
//       ...vehicles.where((v) => (v['pickupDuration'] as num).toDouble() > 0),
//       ...vehicles.where((v) => (v['pickupDuration'] as num).toDouble() == 0),
//     ];

    final rawVehicles =
        widget.estimations['vehicleEstimations'] as List<dynamic>;
    final vehicles = rawVehicles.cast<Map<String, dynamic>>();

// final sortedVehicles = [
//   // available first
//   ...vehicles.where((v) => (v['pickupDuration'] as num) > 0),
//   // then the rest
//   ...vehicles.where((v) => (v['pickupDuration'] as num) == 0),
// ];

// 2’) Sort: booked first, then available, then busy
    final sortedVehicles = [
      // 1) The one the user has already booked
      if (activeRideType != null)
        ...vehicles.where((v) => v['vehicleType'] == activeRideType),
      // 2) All other available rides
      ...vehicles.where((v) =>
          v['vehicleType'] != activeRideType &&
          (v['pickupDuration'] as num).toDouble() > 0),
      // 3) All busy rides
      ...vehicles.where((v) =>
          v['vehicleType'] != activeRideType &&
          (v['pickupDuration'] as num).toDouble() == 0),
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      // decoration: BoxDecoration(
      //   borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      //   boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      //   color: Colors.white,
      // ),
      child: Column(
        children: [
          // ─── Grab‑handle ───
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ─── Map ───
          // Expanded(
          //   flex: 4,
          //   child: ClipRRect(
          //     borderRadius: BorderRadius.circular(12),
          //     child: GoogleMap(
          //       initialCameraPosition: CameraPosition(
          //         target: LatLng(widget.sourceLatitude, widget.sourceLongitude),
          //         zoom: 4,
          //       ),
          //       markers: _markers,
          //       polylines: _polylines,
          //       onMapCreated: (c) {
          //         _mapController = c;
          //         _fitMapToBounds([
          //           LatLng(widget.sourceLatitude, widget.sourceLongitude),
          //           LatLng(widget.destinationLatitude,
          //               widget.destinationLongitude),
          //         ]);
          //       },
          //     ),
          //   ),
          // ),

          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.sourceLatitude, widget.sourceLongitude),
                  zoom: 12,
                ),

                // ─── New flags added here ───
                zoomControlsEnabled: true, // shows + / – buttons
                zoomGesturesEnabled: true, // pinch to zoom
                compassEnabled: true, // little compass icon
                mapToolbarEnabled:
                    true, // Android map toolbar (open in Maps, StreetView)
                myLocationButtonEnabled: true, // “go to my location” button
                myLocationEnabled:
                    true, // actually draws your blue dot (requires permission)
                indoorViewEnabled: true, // 3D indoor view
                rotateGesturesEnabled: true, // two-finger rotate
                tiltGesturesEnabled: true, // two-finger tilt
                scrollGesturesEnabled: true, // pan

                markers: _markers,
                polylines: _polylines,
                onMapCreated: (c) {
                  _mapController = c;
                  _fitMapToBounds([
                    LatLng(widget.sourceLatitude, widget.sourceLongitude),
                    LatLng(widget.destinationLatitude,
                        widget.destinationLongitude),
                  ]);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ─── Distance Header ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.straighten,
                  size: 18, color: LarosaColors.primary),
              const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Route Distance ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: LarosaColors.textSecondary,
                      ),
                    ),
                    TextSpan(
                      text: '${distance.toStringAsFixed(2)} ',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: LarosaColors.primary,
                      ),
                    ),
                    const TextSpan(
                      text: 'km',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: LarosaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text('Driver ID: ${driverInfo?['driverId'] ?? ''}'),
          Text('Driver Token: ${driverInfo?['driverToken'] ?? ''}'),
          Text('Driver Latitude: ${driverInfo?['lat'] ?? ''}'),
          Text('Driver Longitude: ${driverInfo?['lng'] ?? ''}'),
          const SizedBox(height: 12),

          const SizedBox(height: 12),

          // ─── Vehicle Options ───
          // Expanded(
          //   flex: 6,
          //   child: ListView.builder(
          //     itemCount: vehicles.length,
          //     itemBuilder: (ctx, i) {
          //       final data = vehicles[i] as Map<String, dynamic>;
          //       return _buildVehicleRow(data, 'TZS', context);
          //     },
          //   ),
          // ),

          Expanded(
            flex: 6,
            child: ListView.builder(
              itemCount: sortedVehicles.length, // ← vehicles → sortedVehicles
              itemBuilder: (ctx, i) {
                final data =
                    sortedVehicles[i]; // ← vehicles[i] → sortedVehicles[i]
                return _buildVehicleRow(data, 'TZS', context);
              },
            ),
          ),

          // ─── All busy fallback ───
          // if (vehicles.every((v) => (v as Map<String, dynamic>)['pickupDuration'] == 0))
          //   Padding(
          //     padding: const EdgeInsets.symmetric(vertical: 16),
          //     child: Column(
          //       children: const [
          //         Icon(Icons.bus_alert, size: 36, color: Colors.green),
          //         SizedBox(height: 8),
          //         Text(
          //           'All LaRosa rides are currently engaged.\nPlease hold on—we’ll get you a driver asap.',
          //           textAlign: TextAlign.center,
          //           style: TextStyle(fontSize: 14),
          //         ),
          //       ],
          //     ),
          //   ),
        ],
      ),
    );
  }

  // Widget _buildVehicleRow(
  //     Map<String, dynamic> data, String currency, BuildContext context) {
  //   final rawType = (data['vehicleType'] as String);
  //   final cost = (data['cost'] as num).toDouble();
  //   final offerCost = (data['costAfterOffer'] as num).toDouble();
  //   final pickupMin = (data['pickupDuration'] as num).toDouble();
  //   final travelMin = (data['routeDuration'] as num).toDouble();
  //   final available = pickupMin > 0;

  //   final isBooked = data['vehicleType'] == activeRideType;

  //   final isDark = Theme.of(context).brightness == Brightness.dark;
  //   final cardColor = isDark ? LarosaColors.dark : LarosaColors.light;

  //   final hasDiscount = offerCost < cost;
  //   final displayPrice = hasDiscount ? offerCost : cost;

  //   final icon = _getVehicleIcon(rawType);
  //   final type = _formatVehicleType(rawType);

  //   return Container(
  //     // color: cardColor,
  //     margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: cardColor,
  //       border: const Border(
  //         top: BorderSide(
  //           color: LarosaColors.borderPrimary,
  //           width: 1,
  //         ),
  //         bottom: BorderSide(
  //           color: LarosaColors.borderPrimary,
  //           width: 1,
  //         ),
  //       ),
  //       borderRadius: BorderRadius.circular(12), // optional
  //     ),
  //     // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
  //       child: Stack(
  //         children: [
  //           // 🔘 Status indicator
  //           Positioned(
  //             top: 2,
  //             right: 2,
  //             child: Icon(
  //               Icons.circle,
  //               size: 10,
  //               color: available ? LarosaColors.success : LarosaColors.warning,
  //             ),
  //           ),

  //           Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               // 🚘 Vehicle Icon + Type
  //               Row(
  //                 children: [
  //                   CircleAvatar(
  //                     radius: 18,
  //                     backgroundColor: LarosaColors.primary.withOpacity(0.1),
  //                     child: Icon(
  //                       icon,
  //                       size: 18,
  //                       color: LarosaColors.primary,
  //                     ),
  //                   ),
  //                   const SizedBox(width: 8),
  //                   Text(
  //                     type,
  //                     style: TextStyle(
  //                       fontSize: 13,
  //                       fontWeight: FontWeight.w600,
  //                       color: isDark ? LarosaColors.white : LarosaColors.black,
  //                     ),
  //                   ),
  //                 ],
  //               ),

  //               const SizedBox(height: 10),

  //               // 🛒 Price Display
  //               Row(
  //                 children: [
  //                   const Icon(Icons.local_offer_outlined,
  //                       size: 16, color: LarosaColors.success),
  //                   const SizedBox(width: 6),
  //                   if (hasDiscount) ...[
  //                     Text(
  //                       '${cost.toStringAsFixed(0)} $currency',
  //                       style: TextStyle(
  //                         fontSize: 12,
  //                         color: LarosaColors.darkGrey,
  //                         decoration: TextDecoration.lineThrough,
  //                       ),
  //                     ),
  //                     const SizedBox(width: 6),
  //                     Text(
  //                       '${offerCost.toStringAsFixed(0)} $currency',
  //                       style: const TextStyle(
  //                         fontSize: 13.5,
  //                         color: LarosaColors.secondary,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   ] else ...[
  //                     Text(
  //                       '${displayPrice.toStringAsFixed(0)} $currency',
  //                       style: TextStyle(
  //                         fontSize: 13,
  //                         fontWeight: FontWeight.w600,
  //                         color: isDark
  //                             ? LarosaColors.white
  //                             : LarosaColors.primary,
  //                       ),
  //                     ),
  //                   ]
  //                 ],
  //               ),

  //               const SizedBox(height: 8),

  //               // 📊 Info Row
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   _tinyInfo(Icons.access_time, formatTime(pickupMin)),
  //                   _tinyInfo(Icons.route_rounded, formatTime(travelMin)),
  //                 ],
  //               ),

  //               const SizedBox(height: 10),

  //               // ✅ Select or Busy
  //               Align(
  //                 alignment: Alignment.centerRight,
  //                 child: available
  //                     ? Container(
  //                         decoration: BoxDecoration(
  //                           gradient: LarosaColors.blueGradient,
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                         child: TextButton.icon(
  //                           onPressed: isRequestingRide
  //                               ? null
  //                               : () =>
  //                                   _requestRide(selectedVehicleType: rawType),
  //                           icon: isRequestingRide
  //                               ? const SizedBox(
  //                                   width: 14,
  //                                   height: 14,
  //                                   child: CircularProgressIndicator(
  //                                     strokeWidth: 2,
  //                                     color: Colors.white,
  //                                   ),
  //                                 )
  //                               : const Icon(Icons.local_taxi,
  //                                   size: 14, color: Colors.white),
  //                           label: Text(
  //                             isRequestingRide ? '' : 'Select',
  //                             style: const TextStyle(
  //                                 fontSize: 11,
  //                                 fontWeight: FontWeight.bold,
  //                                 color: Colors.white),
  //                           ),
  //                           style: TextButton.styleFrom(
  //                             backgroundColor: Colors.transparent,
  //                             shadowColor: Colors.transparent,
  //                             padding: const EdgeInsets.symmetric(
  //                                 horizontal: 20, vertical: 8),
  //                             minimumSize: const Size(
  //                                 0, 28), // <-- enforce a smaller height
  //                             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  //                             shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(8)),
  //                           ),
  //                         ),
  //                       )
  //                     : Row(
  //                         mainAxisSize: MainAxisSize.min,
  //                         children: const [
  //                           Icon(Icons.warning_amber_rounded,
  //                               size: 14, color: LarosaColors.warning),
  //                           SizedBox(width: 4),
  //                           Text(
  //                             'Busy',
  //                             style: TextStyle(
  //                               fontSize: 11,
  //                               color: LarosaColors.warning,
  //                               fontWeight: FontWeight.w500,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildVehicleRow(
    Map<String, dynamic> data,
    String currency,
    BuildContext context,
  ) {
    final rawType = data['vehicleType'] as String;
    final cost = (data['cost'] as num).toDouble();
    final offerCost = (data['costAfterOffer'] as num).toDouble();
    final pickupMin = (data['pickupDuration'] as num).toDouble();
    final travelMin = (data['routeDuration'] as num).toDouble();
    final available = pickupMin > 0;

    // isBooked comes from your State: activeRideType
    final isBooked = rawType == activeRideType;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? LarosaColors.dark : null;

    final hasDiscount = offerCost < cost;
    final displayPrice = hasDiscount ? offerCost : cost;

    final icon = _getVehicleIcon(rawType);
    final type = _formatVehicleType(rawType);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        border: const Border(
          top: BorderSide(color: LarosaColors.borderPrimary, width: 1),
          bottom: BorderSide(color: LarosaColors.borderPrimary, width: 1),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Icon + Type
            // Row(
            //   children: [
            //     CircleAvatar(
            //       radius: 18,
            //       backgroundColor: LarosaColors.primary.withOpacity(0.1),
            //       child: Icon(icon, size: 18, color: LarosaColors.primary),
            //     ),
            //     const SizedBox(width: 8),
            //     Text(
            //       type,
            //       style: TextStyle(
            //         fontSize: 13,
            //         fontWeight: FontWeight.w600,
            //         color: isDark ? LarosaColors.white : LarosaColors.black,
            //       ),
            //     ),
            //   ],
            // ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // your existing avatar + text
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: LarosaColors.primary.withOpacity(0.1),
                      child: Icon(icon, size: 18, color: LarosaColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? LarosaColors.white : LarosaColors.black,
                      ),
                    ),
                  ],
                ),

                // the call icon on the right
                if (isBooked || available)
                  GestureDetector(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            LarosaColors.primary,
                            LarosaColors.secondary
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.phone,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Price Display
            Row(
              children: [
                const Icon(Icons.local_offer_outlined,
                    size: 16, color: LarosaColors.success),
                const SizedBox(width: 6),
                if (hasDiscount) ...[
                  Text(
                    '${cost.toStringAsFixed(0)} $currency',
                    style: TextStyle(
                      fontSize: 12,
                      color: LarosaColors.darkGrey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  // '${displayPrice.toStringAsFixed(0)} $currency',
                  '${_currencyFormatter.format(displayPrice)} $currency',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: hasDiscount
                        ? LarosaColors.secondary
                        : (isDark ? LarosaColors.white : LarosaColors.primary),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Info Row
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     _tinyInfo(Icons.access_time, formatTime(pickupMin)),
            //     _tinyInfo(Icons.route_rounded, formatTime(travelMin)),
            //   ],
            // ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tinyInfo(Icons.access_time, 'Arrival:', formatTime(pickupMin)),
                _tinyInfo(Icons.route_rounded, 'Route:', formatTime(travelMin)),
              ],
            ),

            const SizedBox(height: 10),

            // Action Button: Cancel / Select / Busy
            Align(
              alignment: Alignment.centerRight,
              child: isBooked
                  // Already booked → show Cancel
                  // ? TextButton.icon(
                  //     onPressed: _cancelBooking,
                  //     icon: const Icon(Icons.local_taxi,
                  //         size: 14, color: Colors.white),
                  //     label: const Text(
                  //       'Cancel',
                  //       style: TextStyle(
                  //           fontSize: 11,
                  //           fontWeight: FontWeight.bold,
                  //           color: Colors.white),
                  //     ),
                  //     style: TextButton.styleFrom(
                  //       backgroundColor: Colors.redAccent,
                  //       padding: const EdgeInsets.symmetric(
                  //           horizontal: 20, vertical: 6),
                  //       minimumSize: const Size(0, 28),
                  //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  //       shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(8)),
                  //     ),
                  //   )

                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 0),
                      child: Row(
                        children: [
                          // ─── Animated “Driver is on the way” ───
                          AvatarGlow(
                            glowColor: Colors.greenAccent,
                            glowRadiusFactor: .5,
                            duration: const Duration(milliseconds: 1500),
                            repeat: true,
                            // showTwoGlows: true,
                            child: Icon(
                              // Icons.local_taxi,
                              icon,
                              size: 24,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Driver is on the way',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),

                          const Spacer(),

                          // ─── Cancel Button ───
                          Container(
                            decoration: BoxDecoration(
                              gradient: LarosaColors.dangerGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextButton.icon(
                              onPressed: _cancelBooking,
                              icon: Icon(
                                icon,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                minimumSize: const Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : (available
                      // Available → gradient Select
                      ? Container(
                          decoration: BoxDecoration(
                            gradient: LarosaColors.blueGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton.icon(
                            onPressed: isRequestingRide
                                ? null
                                : () =>
                                    _requestRide(selectedVehicleType: rawType),
                            icon: isRequestingRide
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: CupertinoActivityIndicator(
                                        radius: 8,
                                        color: Colors.white,
                                        animating: true,
                                      ),
                                    ))
                                : Icon(icon, size: 18, color: Colors.white),
                            label: Text(
                              isRequestingRide ? '' : 'Select',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        )
                      // Busy → no action
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 14, color: LarosaColors.warning),
                            SizedBox(width: 4),
                            Text(
                              'Busy',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: LarosaColors.warning,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        )),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'motorcycle':
        return Icons.motorcycle;
      case 'bajaj':
        return Icons.electric_rickshaw;
      case 'larosamini':
      case 'larosa mini':
        return Icons.directions_car;
      default:
        return Icons.help_outline;
    }
  }

  // Widget _tinyInfo(IconData icon, String value) {
  //   return Row(
  //     children: [
  //       Icon(icon, size: 14, color: LarosaColors.mediumGray),
  //       const SizedBox(width: 4),
  //       Text(
  //         value,
  //         style: const TextStyle(fontSize: 12),
  //       ),
  //     ],
  //   );
  // }

  Widget _tinyInfo(IconData icon, String label, String? value) {
    // parse “5 min” → 5, or null/invalid → 0
    final minutes = int.tryParse(value!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    // nothing to show for zero minutes
    if (minutes == 0) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(icon, size: 14, color: LarosaColors.mediumGray),
        const SizedBox(width: 4),
        Text(
          '$label $value',
          style: const TextStyle(fontSize: 12),
        ),
      ],
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
