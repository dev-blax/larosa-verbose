import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:larosa_block/Features/Cart/controllers/cart_controller.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../Components/cart_button.dart';
import '../../Components/PaymentModals/payment_method_modal.dart';
import '../../Services/auth_service.dart';
import '../../Utils/colors.dart';

class PrepareForPayment extends StatefulWidget {
  final List<int> productIds; // Array of product IDs
  final double totalPrice; // Total price of all items
  final String combinedNames; // Combined names as a single string
  final int totalQuantity;
  final bool reservationType;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> itemsToDisplay;

  const PrepareForPayment({
    super.key,
    required this.productIds,
    required this.totalPrice,
    required this.combinedNames,
    required this.reservationType,
    required this.totalQuantity,
    required this.items,
    required this.itemsToDisplay,
  });

  @override
  State<PrepareForPayment> createState() => _PrepareForPaymentState();
}

class _PrepareForPaymentState extends State<PrepareForPayment> {
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

  int adults = 1; // Default value for adults
  int children = 0; // Default value for children

  DateTime? checkInDate; // Nullable variable for the check-in date
  DateTime? checkOutDate; // Nullable variable for the check-out date

  bool get isReservation => !widget.reservationType;

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
      "country": "Tanzania",
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

      // print('${response.body}');

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

  final TextEditingController _fullNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
    // _getCurrentLocation();
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

  Future<void> addItemToCart(
      int profileId, List<Map<String, dynamic>> items) async {
    final Uri uri = Uri.https(
      'burnished-core-439210-f6.uc.r.appspot.com',
      '/cart/add-item',
    );

    try {
      String token = AuthService.getToken();

      if (token == null) {
        throw Exception('Token is missing. Please log in again.');
      }

      final Map<String, dynamic> requestBody = {
        "profileId": profileId,
        "items": items,
      };

      final http.Response response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(requestBody),
      );
      print(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LogService.logInfo('Item added to cart successfully: $data');
      } else {
        LogService.logError(
            'Failed to add item to cart. Status Code: ${response.statusCode}');
      }
    } catch (error) {
      // LogService.logError('Error in addItemToCart: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = Provider.of<CartController>(context);
    List<String> imageUrls = widget.combinedNames.split(',');
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
          'Proceed To Payment',
          style: TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //   child: Row(
          //     children: imageUrls.map((imageUrl) {
          //       return CachedNetworkImage(
          //         imageUrl: imageUrl.trim(),
          //         height: 500,
          //         progressIndicatorBuilder: (context, url, downloadProgress) =>
          //             const SpinKitCircle(
          //           color: Colors.blue,
          //         ),
          //         errorWidget: (context, url, error) => const Icon(Icons.error),
          //       );
          //     }).toList(),
          //   ),
          // ),

          SingleChildScrollView(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Other widgets above the ListView.builder
      SizedBox(
        height: 300, // Specify the height as per your requirement
        child: ListView.builder(
          itemCount: widget.itemsToDisplay.length,
          itemBuilder: (context, index) {
            final item = widget.itemsToDisplay[index];
            final imageUrls = (item['names'] ?? '').split(',');

            return Card(
              color: Theme.of(context).brightness == Brightness.dark
      ? Colors.black
      : Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8.0, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 100, // Height for the image row
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        itemBuilder: (context, imgIndex) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrls[imgIndex],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 100),
                            ),
                          );
                        },
                        separatorBuilder: (context, _) =>
                            const SizedBox(width: 8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity: ${item['quantity']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    Text(
                      'Price: Tsh ${NumberFormat('#,##0', 'en_US').format(item['price'])}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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
)
,

const Divider(),
    
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(8),
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
                      if (isReservation)
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
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              isReservation ? 'Quantity' : 'Rooms',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('${widget.totalQuantity}'),
                          ),
                        ],
                      ),
                      if (!isReservation)
                        // Adults
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Adults',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: adults.toDouble(),
                                    min: 1,
                                    max: 20,
                                    divisions: 20,
                                    label: adults.toString(),
                                    activeColor: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors
                                            .black, // Set active color based on theme
                                    inactiveColor: Theme.of(context)
                                                .brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.black.withOpacity(
                                            0.5), // Set inactive color based on theme
                                    thumbColor: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors
                                            .black, // Set thumb color based on theme
                                    onChanged: (value) {
                                      setState(() {
                                        adults = value.toInt();
                                      });

                                      // Trigger haptic feedback on value change
                                      HapticFeedback.vibrate();
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text('$adults'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      if (!isReservation)
                        // Children
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Children',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: children.toDouble(),
                                    min: 0,
                                    max: 20,
                                    divisions: 20,
                                    label: children.toString(),
                                    activeColor: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors
                                            .black, // Active color based on theme
                                    inactiveColor: Theme.of(context)
                                                .brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.black.withOpacity(
                                            0.5), // Inactive color based on theme
                                    thumbColor: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors
                                            .black, // Thumb color based on theme
                                    onChanged: (value) {
                                      setState(() {
                                        children = value.toInt();
                                      });

                                      // Trigger haptic feedback on value change
                                      HapticFeedback.vibrate();
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text('$children'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      if (!isReservation)
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Check-In Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InkWell(
                                onTap: () => _pickCheckInDate(context),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      // color: checkInDate == null ? Colors.blue : Colors.black,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      checkInDate == null
                                          ? 'Tap to Set'
                                          : getFormattedDate(checkInDate),
                                      style: const TextStyle(
                                        // color: checkInDate == null ? Colors.blue : Colors.black,
                                        fontSize: 14,
                                        // fontWeight: checkInDate == null ? FontWeight.bold : FontWeight.normal,
                                        // decoration: checkInDate == null
                                        //     ? TextDecoration.underline
                                        //     : TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (!isReservation)
                        TableRow(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Check-Out Date',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: InkWell(
                                onTap: () => _pickCheckOutDate(context),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      // color: checkOutDate == null ? Colors.white : Colors.black,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      checkOutDate == null
                                          ? 'Tap to Set'
                                          : getFormattedDate(checkOutDate),
                                      style: const TextStyle(
                                        // color: checkOutDate == null ? Colors.white : Colors.black,
                                        fontSize: 14,
                                        // fontWeight: checkOutDate == null ? FontWeight.bold : FontWeight.normal,
                                        // decoration: checkOutDate == null
                                        //     ? TextDecoration.underline
                                        //     : TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (isReservation)
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
                      if (isReservation)
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
                                      ).format(double.parse(deliveryCost
                                            .replaceAll('Tsh ', '')
                                            .trim())
                                        //     *
                                        // _exchangeRate!,
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
                                  .format(widget.totalPrice * itemCount),
                            ),
                          ),
                        ],
                      ),
                      if (isReservation)
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
                                      ).format(widget.totalPrice * itemCount +
                                            double.parse(deliveryCost
                                                .replaceAll('Tsh ', '')
                                                .trim()) // Add base delivery cost
                                        // double.parse(deliveryCost
                                        //         .replaceAll('Tsh ', '')
                                        // .trim())
                                        //     *
                                        // _exchangeRate!, // Add exchange-rate-adjusted delivery cost
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
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.info_outline, color: Colors.grey),
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

                // buildQuantityAdjustmentRow(),

                if (!isReservation) const Divider(),
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
                                  // Validate Full Name for at least two words
                                  final fullName =
                                      _fullNameController.text.trim();
                                  if (fullName.isEmpty ||
                                      fullName.split(' ').length < 2) {
                                    setState(() {
                                      _errorMessage =
                                          "Please enter your full name (first and last name).";
                                    });

                                    // Optionally show a SnackBar for better feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please provide your full name before proceeding.',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );

                                    return; // Exit the function if validation fails
                                  } else {
                                    setState(() {
                                      _errorMessage =
                                          null; // Clear error message if validation passes
                                    });
                                  }
                                }

                                final totalPrice =
                                    widget.totalPrice * itemCount +
                                        double.parse(deliveryCost
                                            .replaceAll('Tsh ', '')
                                            .trim());
                                // double.parse(deliveryCost
                                //         .replaceAll('Tsh ', ''));
                                //     .trim()) *
                                // _exchangeRate!; // Total price calculation

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
                                          deliveryDestination:
                                              selectedStreetName,
                                          deliveryLatitude: latitude,
                                          deliveryLongitude: longitude,
                                          totalPrice: isReservation
                                              ? totalPrice
                                              : widget.totalPrice * itemCount,
                                          quantity: widget.totalQuantity,
                                          postId: widget.productIds,
                                          items: widget.items,
                                          adults: adults, // Pass adults
                                          children: children, // Pass children
                                          fullName: _fullNameController.text
                                              .trim(), // Pass full name
                                              checkInDate: isReservation ? checkInDate : null, // Conditionally include checkInDate
      checkOutDate: isReservation ? checkOutDate : null, // Conditionally include checkOutDate
                                          isReservation: !isReservation),
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

                    // const SizedBox(
                    //     width: 70), // Add some spacing between the buttons

                    // Expanded(
                    //   child: buildWideGradientButton(
                    //     onTap: () async {
                    //       try {
                    //         // Fetch the user's profile ID dynamically
                    //         int? profileId = AuthService
                    //             .getProfileId(); // Ensure this returns an actual int value
                    //         if (profileId == null) {
                    //           throw Exception(
                    //               'Profile ID is null. Please log in again.');
                    //         }

                    //         // Replace `itemCount` and `widget.postId` with actual dynamic values
                    //         List<Map<String, dynamic>> items = [
                    //           {
                    //             "postId": widget
                    //                 .productIds, // Ensure `widget.postId` is a valid int
                    //             "quantity":
                    //                 itemCount, // Ensure `itemCount` is a valid int
                    //           }
                    //         ];

                    //         await addItemToCart(profileId, items);

                    //         // Navigate to the cart screen
                    //         // context.push('/maincart');
                    //       } catch (error) {
                    //         LogService.logError('Error in Add to Cart: $error');
                    //       }
                    //     },
                    //     label: 'Add to Cart',
                    //     startColor: LarosaColors.secondary,
                    //     endColor: LarosaColors.purple,
                    //   ),
                    // ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget buildQuantityAdjustmentRow() {
  //   return Container(
  //     decoration: const BoxDecoration(),
  //     padding: const EdgeInsets.only(top: 8.0, bottom: 10),
  //     child: Column(
  //       children: [
  //         // const Gap(10),
  //         // Decrease Buttons
  //         SingleChildScrollView(
  //           scrollDirection: Axis.horizontal,
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount = (itemCount - 1 < 1) ? 1 : itemCount - 1;
  //                   });
  //                 },
  //                 label: '-1',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //               const Gap(6),
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount = (itemCount - 5 < 1) ? 1 : itemCount - 5;
  //                   });
  //                 },
  //                 label: '-5',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //               const Gap(6),
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount = (itemCount - 10 < 1) ? 1 : itemCount - 10;
  //                   });
  //                 },
  //                 label: '-10',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //               const Gap(6),
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount = (itemCount - 20 < 1) ? 1 : itemCount - 20;
  //                   });
  //                 },
  //                 label: '-20',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //               const Gap(6),
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount = (itemCount - 50 < 1) ? 1 : itemCount - 50;
  //                   });
  //                 },
  //                 label: '-50',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //               const Gap(6),
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount = (itemCount - 100 < 1) ? 1 : itemCount - 100;
  //                   });
  //                 },
  //                 label: '-100',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const Gap(5),
  //         // Increase Buttons
  //         SingleChildScrollView(
  //           scrollDirection: Axis.horizontal,
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount++;
  //                   });
  //                 },
  //                 label: '+1',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //               const Gap(6),
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount += 5;
  //                   });
  //                 },
  //                 label: '+5',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //               const Gap(6),
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount += 10;
  //                   });
  //                 },
  //                 label: '+10',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //               const Gap(6),
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount += 20;
  //                   });
  //                 },
  //                 label: '+20',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //               const Gap(6),
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount += 50;
  //                   });
  //                 },
  //                 label: '+50',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //               const Gap(6),
  //               buildGradientButton(
  //                 onTap: () {
  //                   setState(() {
  //                     itemCount += 100;
  //                   });
  //                 },
  //                 label: '+100',
  //                 startColor: LarosaColors.primary.withOpacity(1),
  //                 endColor: LarosaColors.purple.withOpacity(1),
  //               ),
  //             ],
  //           ),
  //         ),
  //         // const Gap(10),
  //       ],
  //     ),
  //   );
  // }

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

Widget fullNameInput({
  required TextEditingController controller,
  required Function(String) onChanged,
  String? errorMessage,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Full Name",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Enter your full name",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          prefixIcon: const Icon(Icons.person),
          // errorText: errorMessage,
        ),
        onChanged: onChanged,
      ),
      if (errorMessage != null)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
    ],
  );
}
