import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
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
import 'package:shimmer/shimmer.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../Utils/colors.dart';
import '../../Utils/wavy_border_painter.dart';
import 'explore_services.dart';
import 'time_estimations_modal_content.dart';

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
  // bool connectedToSocket = false;
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

    // Initialize destination marker if known
    if (destinationLatitude != null && destinationLongitude != null) {
      _updateDestinationMarker(destinationLatitude!, destinationLongitude!);
    }

    // Subscribe to updates from the WebSocket
    // if (_stompClient != null) {
    // _stompClient!.subscribe(
    //   destination: '/topic/$_city',
    //   callback: (StompFrame message) {
    //     final messageBody = message.body;
    //     if (messageBody != null) {
    //       final data = jsonDecode(messageBody);
    //       print('Update for driver larosa $messageBody');

    //       if (data.containsKey('latitude') && data.containsKey('longitude')) {
    //         final driverLatitude = data['latitude'];
    //         final driverLongitude = data['longitude'];

    //         // Update the driver marker
    //         _updateDriverMarker(driverLatitude, driverLongitude);
    //       }
    //     }
    //   },
    // );

    // _stompClient!.subscribe(
    //   destination: '/topic/your_channel', // Replace with your topic/channel
    //   callback: (StompFrame message) {
    //     if (message.body != null) {
    //       final data = jsonDecode(message.body!);
    //       final double latitude = data['latitude'];
    //       final double longitude = data['longitude'];
    //       _updateMarker(latitude, longitude);
    //     }
    //   },
    // );
    // }
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

  // Future<void> _requestRide({required String selectedVehicleType}) async {

  //   if (sourceLatitude == null ||
  //       sourceLongitude == null ||
  //       destinationLatitude == null ||
  //       destinationLongitude == null) {
  //     HelperFunctions.showToast(
  //       'Please Enter Pickup and Destination location',
  //       true,
  //     );
  //     LogService.logError("Source or Destination coordinates are missing.");
  //     return;
  //   }

  //   setState(() {
  //     isRequestingRide = true;
  //   });

  //   Map<String, String> headers = {
  //     "Content-Type": "application/json",
  //     "Access-Control-Allow-Origin": "*",
  //     'Authorization': 'Bearer ${AuthService.getToken()}',
  //   };

  //   String endpoint = '${LarosaLinks.baseurl}/api/v1/ride/request';

  //   try {
  //     LogService.logDebug(
  //         "Fetching country and city for source and destination...");

  //     // Get country and city for source
  //     final sourceLocation =
  //         await getCountryAndCity(sourceLatitude!, sourceLongitude!);
  //     final destinationLocation =
  //         await getCountryAndCity(destinationLatitude!, destinationLongitude!);

  //     LogService.logDebug("Source Location: $sourceLocation");
  //     LogService.logDebug("Destination Location: $destinationLocation");

  //     String sourceCity = (() {
  //       // Retrieve the city name from the sourceLocation map or default to 'Unknown'
  //       String cityName = sourceLocation['city'] ?? 'Unknown';

  //       // Check if the city is 'Unknown' or empty, and log a warning if necessary
  //       if (cityName == 'Unknown' || cityName.isEmpty) {
  //         LogService.logWarning(
  //             'Source city is invalid. Falling back to default.');
  //         return 'Dodoma'; // Default fallback city
  //       }

  //       // Sanitize the city name by removing unwanted words like 'Region' or 'Mkoa wa'
  //       const unwantedWords = ['Region', 'Mkoa wa'];
  //       for (String word in unwantedWords) {
  //         cityName = cityName.replaceAll(word, '').trim();
  //       }

  //       // Ensure the city name is properly capitalized
  //       return cityName.split(' ').map((word) {
  //         if (word.isNotEmpty) {
  //           return word[0].toUpperCase() + word.substring(1).toLowerCase();
  //         }
  //         return word;
  //       }).join(' ');
  //     })();

  //     // String destinationCity =
  //     //     _sanitizeCityName(destinationLocation['city'] ?? 'Unknown');

  //     final requestBody = {
  //       "startLat": sourceLatitude,
  //       "startLng": sourceLongitude,
  //       "endLat": destinationLatitude,
  //       "endLng": destinationLongitude,
  //       "vehicleType": selectedVehicleType,
  //       "paymentMethod": paymentMethod,
  //       "country": sourceLocation['country'],
  //       "city": sourceCity,
  //     };

  //     LogService.logDebug("Request Body 123 : ${jsonEncode(requestBody)}");
  //     LogService.logDebug("Making POST request to $endpoint");

  //     var response = await http.post(
  //       Uri.parse(endpoint),
  //       headers: headers,
  //       body: jsonEncode(requestBody),
  //     );

  //     LogService.logDebug("Response Status Code: ${response.statusCode}");
  //     LogService.logDebug("Response Body: ${response.body}");

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       LogService.logInfo('Ride request successful');
  //       // HelperFunctions.showToast(
  //       //   'Your ride request has been submitted successfully!',
  //       //   true,
  //       // );
  // HelperFunctions.showNotification(
  //   title: 'Success',
  //   body: 'Your ride request has been submitted successfully!',
  // );

  //       setState(() {
  //         isRequestingRide = false;
  //       });
  //     } else if (response.statusCode == 400) {
  //       LogService.logError(
  //           'Bad Request: ${response.body}. Possible issues with data.');
  //       HelperFunctions.showToast(
  //         'Failed to submit the ride request. Please check your input.',
  //         true,
  //       );
  //     } else if (response.statusCode == 401) {
  //       LogService.logError('Unauthorized: Refreshing token and retrying...');
  //       await AuthService.refreshToken();
  //       await _requestRide(selectedVehicleType: selectedVehicleType);
  //     } else {
  //       LogService.logError('Ride request failed: ${response.statusCode}');
  //       HelperFunctions.showToast(
  //         'Something went wrong. Please try again later.',
  //         true,
  //       );
  //     }
  //   } catch (e, stackTrace) {
  //     LogService.logError('Error making ride request: $e');
  //     LogService.logDebug('Stack Trace: $stackTrace');
  //     HelperFunctions.showToast('An unexpected error occurred.', true);
  //   } finally {
  //     setState(() {
  //       isRequestingRide = false;
  //     });
  //   }
  // }

  // Future<void> _requestRide({required String selectedVehicleType}) async {
  //   if (sourceLatitude == null ||
  //       sourceLongitude == null ||
  //       destinationLatitude == null ||
  //       destinationLongitude == null) {
  //     HelperFunctions.showToast(
  //       'Please Enter Pickup and Destination location',
  //       true,
  //     );
  //     LogService.logError("Source or Destination coordinates are missing.");
  //     return;
  //   }

  //   setState(() {
  //     isRequestingRide = true;
  //   });

  //   Map<String, String> headers = {
  //     "Content-Type": "application/json",
  //     "Access-Control-Allow-Origin": "*",
  //     'Authorization': 'Bearer ${AuthService.getToken()}',
  //   };

  //   String endpoint = '${LarosaLinks.baseurl}/api/v1/ride/request';

  //   try {
  //     LogService.logDebug(
  //         "Fetching country and city for source and destination...");

  //     // Get country and city for source
  //     final sourceLocation =
  //         await getCountryAndCity(sourceLatitude!, sourceLongitude!);
  //     final destinationLocation =
  //         await getCountryAndCity(destinationLatitude!, destinationLongitude!);

  //     LogService.logDebug("Source Location: $sourceLocation");
  //     LogService.logDebug("Destination Location: $destinationLocation");

  //     String sourceCity = (() {
  //       String cityName = sourceLocation['city'] ?? 'Unknown';
  //       if (cityName == 'Unknown' || cityName.isEmpty) {
  //         LogService.logWarning(
  //             'Source city is invalid. Falling back to default.');
  //         return 'Dodoma';
  //       }
  //       const unwantedWords = ['Region', 'Mkoa wa'];
  //       for (String word in unwantedWords) {
  //         cityName = cityName.replaceAll(word, '').trim();
  //       }
  //       return cityName
  //           .split(' ')
  //           .map((word) =>
  //               word[0].toUpperCase() + word.substring(1).toLowerCase())
  //           .join(' ');
  //     })();

  //     final requestBody = {
  //       "startLat": sourceLatitude,
  //       "startLng": sourceLongitude,
  //       "endLat": destinationLatitude,
  //       "endLng": destinationLongitude,
  //       "vehicleType": selectedVehicleType,
  //       "paymentMethod": paymentMethod,
  //       "country": sourceLocation['country'],
  //       "city": sourceCity,
  //     };

  //     LogService.logDebug("Request Body: ${jsonEncode(requestBody)}");
  //     LogService.logDebug("Making POST request to $endpoint");

  //     var response = await http.post(
  //       Uri.parse(endpoint),
  //       headers: headers,
  //       body: jsonEncode(requestBody),
  //     );

  //     LogService.logDebug("Response Status Code: ${response.statusCode}");
  //     LogService.logDebug("Response Body: ${response.body}");

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       LogService.logInfo('Ride request successful');

  //       // Trigger success modal
  //       // showSuccessModal(context, "Your ride request was successful!");

  //       HelperFunctions.showNotification(
  //         title: 'Success',
  //         body: 'Your ride request has been submitted successfully!',
  //       );

  //       setState(() {
  //         isRequestingRide = true;
  //       });
  //     } else if (response.statusCode == 400) {
  //       LogService.logError(
  //           'Bad Request: ${response.body}. Possible issues with data.');
  //       HelperFunctions.showToast(
  //         'Failed to submit the ride request. Please check your input.',
  //         true,
  //       );
  //     } else if (response.statusCode == 401) {
  //       LogService.logError('Unauthorized: Refreshing token and retrying...');
  //       await AuthService.refreshToken();
  //       await _requestRide(selectedVehicleType: selectedVehicleType);
  //     } else {
  //       LogService.logError('Ride request failed: ${response.statusCode}');
  //       HelperFunctions.showToast(
  //         'Something went wrong. Please try again later.',
  //         true,
  //       );
  //     }
  //   } catch (e, stackTrace) {
  //     LogService.logError('Error making ride request: $e');
  //     LogService.logDebug('Stack Trace: $stackTrace');
  //     HelperFunctions.showToast('An unexpected error occurred.', true);
  //   } finally {
  //     setState(() {
  //       isRequestingRide = false;
  //     });
  //   }
  // }

  // void showSuccessModal(BuildContext context, String message) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (BuildContext context) {
  //       return Container(
  //         padding: const EdgeInsets.all(20),
  //         decoration: const BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             const Icon(
  //               Icons.check_circle,
  //               color: Colors.green,
  //               size: 60,
  //             ),
  //             const SizedBox(height: 20),
  //             Text(
  //               message,
  //               textAlign: TextAlign.center,
  //               style: const TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //             ElevatedButton(
  //               onPressed: () {
  //                 Navigator.pop(context); // Close the modal
  //               },
  //               child: const Text('Okay'),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // String _sanitizeCityName(String cityName) {
  //   // Remove "Mkoa wa" if it exists in the city name
  //   if (cityName.startsWith('Mkoa wa')) {
  //     return cityName.replaceFirst('Mkoa wa', '').trim();
  //   }
  //   return cityName;
  // }

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

  Widget buildShimmerOrderCard(context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID Placeholder
            Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
              highlightColor:
                  isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                height: 20,
                width: 200,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // Total Amount Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 120,
                    color: Colors.white,
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 80,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Delivery Amount Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 120,
                    color: Colors.white,
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 80,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Driver Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 100,
                    color: Colors.white,
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                  highlightColor:
                      isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                  child: Container(
                    height: 16,
                    width: 100,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Button Placeholder
            Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
              highlightColor:
                  isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                height: 40,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
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
                    // Display normal suggestions
                    return ListTile(
                      title: Text(suggestion['description']!),
                    );
                  },
                  onSelected: (Map<String, String> suggestion) async {
                    if (suggestion['place_id'] != '') {
                      // Automatically fill the form field with the selected suggestion
                      _destinationController.text = suggestion['description']!;
                      final placeId = suggestion['place_id']!;
                      await _getPlaceDetails(
                          placeId, false); // Fetch destination place details
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
                    horizontal: 20), // Adjust horizontal padding
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
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          30, // Ensures button shape matches container
                        ),
                      ),
                    ),
                  ),
                  onPressed: isRequestingRide ? null : fetchTimeEstimations,
                  // : _requestRide, // Disable button during loading
                  // child: isRequestingRide
                  //     ? const CupertinoActivityIndicator(
                  //         color: Colors.white,
                  //         radius: 10.0, // Adjust the size as needed
                  //       )
                  //     : const Text(
                  //         'Request a Ride',
                  //         style: TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 14,
                  //         ), // Ensures text is readable
                  //       ),
                  child: isFetchingTimeEstimations
                      ? const CupertinoActivityIndicator(
                          color: Colors.white,
                          radius: 10.0,
                        )
                      : const Text(
                          'Initiate Ride Request',
                          style: TextStyle(
                            color: Colors.white,
                            // fontSize: 16, // Slightly larger text for readability
                            fontWeight:
                                FontWeight.w600, // Semi-bold for emphasis
                            letterSpacing:
                                1.0, // Add slight spacing for a clean look
                          ),
                        ),
                ),
              ),

              const Gap(10),
              // if (selectedSourceStreetName != null &&
              //     sourceLatitude != null &&
              //     sourceLongitude != null)
              //   Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         const Text('Source Location'),
              //         Text('Street: $selectedSourceStreetName'),
              //         Text('Latitude: $sourceLatitude'),
              //         Text('Longitude: $sourceLongitude'),
              //       ],
              //     ),
              //   ),
              // if (selectedDestinationStreetName != null &&
              //     destinationLatitude != null &&
              //     destinationLongitude != null)
              //   Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         const Text('Destination Location'),
              //         Text('Street: $selectedDestinationStreetName'),
              //         Text('Latitude: $destinationLatitude'),
              //         Text('Longitude: $destinationLongitude'),
              //       ],
              //     ),
              //   ),

              const Divider(),
              const Gap(10),

              // List of Order Tiles
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  // crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const Center(
                    //   child: Text(
                    //     'Your Orders',
                    //     style: TextStyle(
                    //         fontSize: 16, fontWeight: FontWeight.bold),
                    //   ),
                    // ),
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
                    // orders.isEmpty
                    //     ? SizedBox(
                    //         height: MediaQuery.of(context).size.height *
                    //             0.6, // Adjust the height as needed
                    //         child: ListView.builder(
                    //           itemCount: 5, // Number of shimmer cards
                    //           itemBuilder: (context, index) =>
                    //               buildShimmerOrderCard(context),
                    //         ),
                    //       )

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
                                                // IconButton(
                                                //   icon: const Icon(
                                                //     Icons.location_on,
                                                //     // color: LarosaColors.primary
                                                //   ),
                                                //   onPressed: () {
                                                //     if (deliveryLocation !=
                                                //         null) {
                                                //       // Open the Map Modal
                                                //       showModalBottomSheet(
                                                //         context: context,
                                                //         isScrollControlled:
                                                //             true,
                                                //         backgroundColor:
                                                //             Colors.transparent,
                                                //         builder: (BuildContext
                                                //             context) {
                                                //           return MapModal(
                                                //             latitude:
                                                //                 deliveryLocation[
                                                //                         'latitude'] ??
                                                //                     0.0,
                                                //             longitude:
                                                //                 deliveryLocation[
                                                //                         'longitude'] ??
                                                //                     0.0,
                                                //           );
                                                //         },
                                                //       );
                                                //     }
                                                //   },
                                                // ),
                                              ],
                                            ),
                                            Gap(5),
                                            Divider(),
                                            // const Gap(5),
                                            // Container(
                                            //   width: double.infinity,
                                            //   padding: const EdgeInsets
                                            //       .symmetric(
                                            //       horizontal:
                                            //           10), // Adjust horizontal padding
                                            //   decoration: BoxDecoration(
                                            //     gradient: const LinearGradient(
                                            //       colors: [
                                            //         LarosaColors.secondary,
                                            //         LarosaColors.purple
                                            //       ],
                                            //       begin: Alignment.topLeft,
                                            //       end: Alignment.bottomRight,
                                            //     ),
                                            //     borderRadius:
                                            //         BorderRadius.circular(
                                            //             30), // Rounded corners
                                            //   ),
                                            //   child: FilledButton(
                                            //     style: ButtonStyle(
                                            //       backgroundColor:
                                            //           WidgetStateProperty.all(
                                            //               Colors.transparent),
                                            //       padding:
                                            //           WidgetStateProperty.all(
                                            //         const EdgeInsets.symmetric(
                                            //             vertical: 12,
                                            //             horizontal: 24),
                                            //       ),
                                            //       shape:
                                            //           WidgetStateProperty.all(
                                            //         RoundedRectangleBorder(
                                            //           borderRadius:
                                            //               BorderRadius.circular(
                                            //                   30), // Ensures button shape matches container
                                            //         ),
                                            //       ),
                                            //     ),
                                            //     onPressed: () {
                                            //       // Assign driver logic here
                                            //     },
                                            //     child: const Text(
                                            //       'Assign Driver to Delivery',
                                            //       style: TextStyle(
                                            //         color: Colors.white,
                                            //         // fontSize: 16, // Slightly larger font for emphasis
                                            //         fontWeight: FontWeight
                                            //             .w600, // Semi-bold for a balanced professional look
                                            //         letterSpacing:
                                            //             0.8, // Slight spacing for readability
                                            //         height:
                                            //             1.3, // Line height for clean vertical spacing
                                            //       ),
                                            //     ),
                                            //   ),
                                            // ),
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

          // Positioned Floating Action Button in the middle right of the screen
          // Positioned(
          //   right: 20, // Adjust the right padding as needed
          //   top: MediaQuery.of(context).size.height / 2 -
          //       28, // Center vertically
          //   child: Container(
          //     decoration: const BoxDecoration(
          //       gradient: LinearGradient(
          //         colors: [LarosaColors.secondary, LarosaColors.purple],
          //         begin: Alignment.topLeft,
          //         end: Alignment.bottomRight,
          //       ),
          //       shape: BoxShape.circle,
          //     ),
          //     child: FloatingActionButton(
          //       onPressed: () {
          //         // When clicked, open the explore modal
          //         Navigator.of(context).push(_createRoute());
          //       }, // Explore icon instead of add icon
          //       backgroundColor:
          //           Colors.transparent, // Make FAB background transparent
          //       elevation: 0,
          //       child: const Icon(Icons
          //           .explore), // Optional: removes shadow to make the gradient stand out
          //     ),
          //   ),
          // ),

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

class MapModal extends StatelessWidget {
  final double latitude;
  final double longitude;

  const MapModal({super.key, required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height * 0.6, // 60% of the screen height
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20), // Rounded top corners
        ),
      ),
      child: Column(
        children: [
          // Modal handle or close button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(latitude, longitude),
                zoom: 14.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('driverLocation'),
                  position: LatLng(latitude, longitude),
                  infoWindow: const InfoWindow(title: 'Driver Location'),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RideHistoryModal extends StatelessWidget {
  final List<dynamic> rideHistory;

  const RideHistoryModal({Key? key, required this.rideHistory})
      : super(key: key);

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
      padding: const EdgeInsets.only(top: 18, left: 8, right: 8),
      child: Column(
        children: [
          // Close button at the top
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // const Text(
              //   "Ride History",
              //   style: TextStyle(
              //     fontSize: 18,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              const Text(''),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop(); // Closes the modal
                },
              ),
            ],
          ),
          const Divider(), // Separates the header from the list
          Expanded(
            child: rideHistory.isEmpty
                ? const Center(
                    child: Text(
                      "No ride history available",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  )
                : ListView.builder(
                    itemCount: rideHistory.length,
                    itemBuilder: (context, index) {
                      final ride = rideHistory[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Ride ID: ${ride['rideId']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ride['rideStatus'] == 'COMPLETED'
                                          ? Colors.green
                                          : Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      ride['rideStatus'],
                                      style: TextStyle(
                                        color: ride['rideStatus'] == 'COMPLETED'
                                            ? Colors.white
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.person,
                                      size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${ride['driverFirstName']} ${ride['driverLastName']}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.directions_car,
                                      size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "${ride['vehicleType']} (${ride['licensePlate']})",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.attach_money,
                                      size: 20, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Total Fare: \$${ride['totalFare']}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              // Row(
                              //   children: [
                              //     const Icon(Icons.location_on,
                              //         size: 20, color: Colors.grey),
                              //     const SizedBox(width: 8),
                              //     Expanded(
                              //       child: Column(
                              //         crossAxisAlignment: CrossAxisAlignment.start,
                              //         children: [
                              //           Text(
                              //             "Pickup: ${ride['pickupLatitude']}, ${ride['pickupLongitude']}",
                              //             style: const TextStyle(fontSize: 13),
                              //           ),
                              //           const SizedBox(height: 4),
                              //           Text(
                              //             "Dropoff: ${ride['dropoffLatitude']}, ${ride['dropoffLongitude']}",
                              //             style: const TextStyle(fontSize: 13),
                              //           ),
                              //         ],
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              if (ride['startTime'] != null ||
                                  ride['endTime'] != null)
                                Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    const Divider(),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 20, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (ride['startTime'] != null)
                                                Text(
                                                  "Start Time: ${formatDateTime(ride['startTime'])}",
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                              if (ride['endTime'] != null)
                                                Text(
                                                  "End Time: ${formatDateTime(ride['endTime'])}",
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
