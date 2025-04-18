import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:geolocator/geolocator.dart';
import '../../Components/cart_button.dart';
import '../../Components/PaymentModals/payment_method_modal.dart';
import '../../Components/loading_shimmer.dart';
import '../../Services/auth_service.dart';
import '../../Utils/colors.dart';
import '../../Utils/links.dart';
import 'prepare_for_payment.dart';
import 'widgets/add_to_cart_table.dart';

class AddToCartScreen extends StatefulWidget {
  final String username;
  final double price;
  final String names;
  final int postId;
  final int? productId;

  final String? reservationType;
  final int? adults;
  final int? children;
  final bool? breakfastIncluded;

  const AddToCartScreen({
    super.key,
    required this.username,
    required this.price,
    required this.names,
    required this.postId,
    this.productId,
    this.reservationType,
    this.adults,
    this.children,
    this.breakfastIncluded,
  });

  @override
  State<AddToCartScreen> createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  int itemCount = 1;
  final TextEditingController _typeAheadController = TextEditingController();
  final DioService _dioService = DioService();
  Position? _currentPosition;
  String? selectedStreetName;
  String? currentStreetName;

  double? latitude;
  double? longitude;

  bool _isLoadingLocation = true;

  String? transportCost;
  String? deliveryDuration;

  String deliveryCost = 'Calculating...';
  String estimatedTime = 'Calculating...';

  double? _exchangeRate;
  String deliveryCostTSh = 'Calculating...';

  int adults = 1;
  int children = 0;

  DateTime? checkInDate;
  DateTime? checkOutDate;

  bool get isReservation => widget.reservationType == null;

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
      "country": "Tanzania",
      "cityName": "Dodoma"
    };

    try {
      LogService.logInfo('Fetching transport cost...');

      final response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/api/v1/transport-cost/calculate',
        data: requestBody,
      );

      LogService.logInfo('Transport cost response: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final double distance = (data['distance'] as num?)?.toDouble() ?? 0.0;
        final double motorcycleCost =
            (data['vehicleEstimations'][0]['cost'] as num?)?.toDouble() ?? 0.0;

        setState(() {
          deliveryCost = motorcycleCost > 0
              ? 'Tsh ${motorcycleCost.toStringAsFixed(2)}'
              : 'Unavailable';
          estimatedTime =
              distance > 0 ? '${(distance * 10).toInt()} min' : 'Unavailable';
        });

        LogService.logInfo('Delivery cost: $deliveryCost');
        LogService.logInfo('Estimated time: $estimatedTime');
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
      final response = await http.get(
        Uri.parse(
          'https://api.exchangerate-api.com/v4/latest/USD',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if TZS rate is available
        if (data['rates'] != null && data['rates']['TZS'] != null) {
          setState(() {
            _exchangeRate = data['rates']['TZS']; // Extract TZS rate
            LogService.logInfo('exchange rate $_exchangeRate');
          });

          // Convert delivery cost to TZS after fetching the rate
          // _convertDeliveryCost();
        } else {
          setState(() {
            deliveryCostTSh = 'TZS rate unavailable';
          });
        }
      } else {
        setState(() {
          deliveryCostTSh = 'Error fetching exchange rate';
        });
      }
    } catch (e) {
      setState(() {
        deliveryCostTSh = 'Error: $e';
      });
    }
  }

  String formatEstimatedTime(String estimatedTime) {
    final int minutes =
        int.tryParse(estimatedTime.replaceAll('min', '').trim()) ?? 0;
    if (minutes >= 60) {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}min';
    }
  }

  final TextEditingController _fullNameController = TextEditingController();
  String? _errorMessage;

  void _validateAndSetFullName(String value) {
    if (value.trim().split(' ').length < 2) {
      setState(() {
        _errorMessage = "Please enter both first and last name.";
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    LogService.logError('initState, adults: ${widget.adults}, children: ${widget.children}');

    _fetchExchangeRate();
    _getCurrentLocation().then((_) => fetchTransportCost());

    // Optionally, set default values
    checkInDate = DateTime.now();
    checkOutDate = DateTime.now().add(const Duration(days: 1));
  }

  Future<void> _pickCheckInDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: checkInDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        checkInDate = picked;

        // Adjust check-out date if it lags behind the new check-in date
        if (checkOutDate == null || checkOutDate!.isBefore(checkInDate!)) {
          checkOutDate = checkInDate!.add(const Duration(days: 1));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Check-Out Date adjusted to ${getFormattedDate(checkOutDate)} to ensure it follows Check-In Date.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 9),
            ),
          );
        }
      });
    }
  }

  Future<void> _pickCheckOutDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: checkOutDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: checkInDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (picked.isBefore(checkInDate!)) {
          // Ensure check-out date is at least 1 day after the check-in date
          checkOutDate = checkInDate!.add(const Duration(days: 1));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Check-Out Date must be after Check-In Date. Adjusted to ${getFormattedDate(checkOutDate)}.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          checkOutDate = picked;
        }
      });
    }
  }

  String getFormattedDate(DateTime? date) {
    if (date == null) return 'Not Set';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<Map<String, String>> calculateTimeAndDistance(
      LatLng pickup, LatLng destination) async {
    const String apiKey = 'AIzaSyA30rAh34FrfL-71H0wdZpdtNB-MkZ8u3A';
    final String url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?origins=${pickup.latitude},${pickup.longitude}&destinations=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final distanceText = data['rows'][0]['elements'][0]['distance']['text'];
        final durationText = data['rows'][0]['elements'][0]['duration']['text'];

        return {
          'distance': distanceText,
          'duration': durationText,
        };
      } else {
        throw Exception('Failed to fetch distance and duration');
      }
    } catch (e) {
      print('Error calculating distance and duration: $e');
      return {
        'distance': 'N/A',
        'duration': 'N/A',
      };
    }
  }

  Future<bool> addItemToCart(
      int profileId, List<Map<String, dynamic>> items) async {
    final Uri uri = Uri.https(
      LarosaLinks.nakedBaseUrl,
      '/cart/add-item',
    );

    try {
      String token = AuthService.getToken();

      if (token.isEmpty) {
        throw Exception('Token is missing. Please log in again.');
      }

      final Map<String, dynamic> requestBody = {
        "items": items,
      };

      LogService.logInfo('request body ${requestBody.toString()}');

      final http.Response response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );
      LogService.logFatal(response.body);
      if (response.statusCode == 200) {
        LogService.logInfo('Item added to cart successfully');
        return true;
      } else {
        LogService.logError(
            'Failed to add item to cart. Status Code: ${response.statusCode}  ${response.body}');
      }
      return false;
    } catch (error) {
      LogService.logError('Error in addItemToCart: $error');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrls = widget.names.split(',');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            CupertinoIcons.back,
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
                const Gap(10),

                if (_isLoadingLocation)
                  const LoadingShimmer()
                else if (_currentPosition != null)
                  AddToCartTable(
                    isReservation: isReservation,
                    currentStreetName: currentStreetName,
                    itemCount: itemCount,
                    adults: adults,
                    children: children,
                    price: widget.price,
                    checkInDate: checkInDate,
                    checkOutDate: checkOutDate,
                    deliveryCost: deliveryCost,
                    estimatedTime: estimatedTime,
                    transportCost: transportCost,
                    deliveryDuration: deliveryDuration,
                    exchangeRate: _exchangeRate,
                    onQuantityChanged: (value) {
                      setState(() {
                        itemCount = value.toInt();
                      });
                    },
                    onAdultQuantityChanged: (value) {
                      setState(() {
                        adults = value.toInt();
                      });
                    },
                    onChildQuantityChanged: (value) {
                      setState(() {
                        children = value.toInt();
                      });
                    },
                    pickCheckInDate: _pickCheckInDate,
                    pickCheckOutDate: _pickCheckOutDate,
                    getFormattedDate: getFormattedDate,
                    getFormattedTime: formatEstimatedTime,
                    productId: widget.postId, // Add this line
                  ),
                const Gap(10),

                const Divider(),
                const Gap(0),
                if (isReservation)
                  // Delivery Destination TextField
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Destination',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                        ),
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
                if (isReservation)
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
                if (isReservation) const Gap(10),
                if (isReservation) const Divider(),
                if (isReservation) const Gap(5),
                if (!isReservation)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: fullNameInput(
                      controller: _fullNameController,
                      onChanged: _validateAndSetFullName,
                      errorMessage: _errorMessage,
                    ),
                  ),
                if (!isReservation) const Divider(),

                const Divider(),
                const Gap(5),

                // Confirm Order Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: deliveryCost.contains('Tsh')
                          ? buildWideGradientButton(
                              onTap: () {
                                if (!isReservation) {
                                  final fullName =
                                      _fullNameController.text.trim();
                                  if (fullName.isEmpty ||
                                      fullName.split(' ').length < 2) {
                                    setState(() {
                                      _errorMessage =
                                          "Please enter your full name (first and last name).";
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please provide your full name before proceeding.',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );

                                    return;
                                  } else {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  }
                                }

                                final totalPrice = widget.price * itemCount +
                                    double.parse(deliveryCost
                                        .replaceAll('Tsh ', '')
                                        .trim());
                                List<Map<String, dynamic>> items = [
                                  {
                                    "productId": widget.postId,
                                    "quantity": itemCount
                                  }
                                ];

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
                                      heightFactor: 0.90,
                                      child: PaymentMethodModal(
                                        currentPosition: _currentPosition,
                                        deliveryDestination: selectedStreetName,
                                        deliveryLatitude: latitude,
                                        deliveryLongitude: longitude,
                                        totalPrice: isReservation
                                            ? totalPrice
                                            : widget.price * itemCount,
                                        quantity: itemCount,
                                        postId: [widget.postId],
                                        adults: adults, // Pass adults
                                        children: children, // Pass children
                                        fullName: _fullNameController.text
                                            .trim(), // Pass full name
                                        checkInDate: checkInDate,
                                        checkOutDate: checkOutDate,
                                        isReservation: !isReservation,
                                        items: items,
                                      ),
                                    );
                                  },
                                );
                              },
                              label:
                                  'Pay Now', // Show label when deliveryCost is loaded
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
                      width: 70,
                    ),
                    Expanded(
                      child: deliveryCost.contains('Tsh')
                          ? buildWideGradientButton(
                              onTap: () async {
                                try {
                                  int? profileId = AuthService.getProfileId();
                                  if (profileId == null) {
                                    throw Exception(
                                        'Profile ID is null. Please log in again.');
                                  }

                                  List<Map<String, dynamic>> items = [
                                    {
                                      "postId": widget.postId,
                                      "quantity": itemCount,
                                    }
                                  ];

                                  LogService.logTrace(
                                      'product Id ${widget.postId}');

                                  bool success =
                                      await addItemToCart(profileId, items);

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Item successfully added to the cart!"),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );

                                    // Navigate to the cart screen
                                    context.pushReplacement('/maincart');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cannot Add Item to Cart! Please Try again',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (error) {
                                  LogService.logError(
                                      'Error in Add to Cart: $error');
                                }
                              },
                              label: 'Add to Cart',
                              startColor: LarosaColors.secondary,
                              endColor: LarosaColors.purple,
                            )
                          : const Center(
                              child: CupertinoActivityIndicator(
                                radius: 10.0,
                              ),
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
}
