import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'dart:ui';
import 'package:geolocator/geolocator.dart';

import '../../Components/cart_button.dart';
import '../../Components/PaymentModals/payment_method_modal.dart';
import '../../Components/wavy_border_clipper.dart';
import '../../Utils/colors.dart';

class AddToCartScreen extends StatefulWidget {
  final String username;
  final double price;
  final String names;
  final int postId;

  const AddToCartScreen({
    super.key,
    required this.username,
    required this.price,
    required this.names,
    required this.postId,
  });

  @override
  State<AddToCartScreen> createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  int itemCount = 1;
  final TextEditingController _typeAheadController = TextEditingController();
  Position? _currentPosition;
  String? selectedStreetName;
  String? currentStreetName;

  double? latitude;
  double? longitude;

  Future<void> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

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

  final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

  setState(() {
    _currentPosition = position;
  });

  // Fetch the street name using reverse geocoding
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      setState(() {
        currentStreetName = placemarks[0].street;
      });
    }
  } catch (e) {
    print('Error: $e');
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrls = widget.names.split(',');
    double totalPrice = widget.price * itemCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Iconsax.arrow_left_2,
          ),
        ),
        title: const Text('Add To Cart'),
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
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display individual price and count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Unit Price: ${NumberFormat.currency(locale: 'en_US', symbol: 'Tsh ', decimalDigits: 2).format(widget.price)}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Quantity: $itemCount',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Gap(10),
                // Total Price Calculation
                Center(
                  child: Text(
                    'Total Price: ${NumberFormat.currency(locale: 'en_US', symbol: 'Tsh ', decimalDigits: 2).format(totalPrice)}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const Gap(10),
                // Display current location if available
                // Table for Current Location
                if (_currentPosition != null)
                  Table(
                    border:
                        TableBorder.all(color: LarosaColors.primary, width: 1),
                    children: [
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Current Location',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Now, 12 Jan 2024'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Latitude'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('${_currentPosition!.latitude}'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Longitude'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('${_currentPosition!.longitude}'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Street Name'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(currentStreetName ?? 'N/A'),
                          ),
                        ],
                      ),
                    ],
                  ),

                const Gap(20),

// Table for Delivery Destination
                if (latitude != null &&
                    longitude != null &&
                    selectedStreetName != null)
                  Table(
                    border: TableBorder.all(color: Colors.purple, width: 1),
                    children: [
                      const TableRow(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Delivery Destination',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Approx 2300, 12 Oct 2024'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Latitude'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('$latitude'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Longitude'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('$longitude'),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Street Name'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('$selectedStreetName'),
                          ),
                        ],
                      ),
                    ],
                  ),

                const Gap(15),

                // Delivery Destination TextField
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Delivery Destination',
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    ),
    IconButton(
      icon: const Icon(Icons.info_outline, color: Colors.grey),
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
                TypeAheadField<Map<String, String>>(
                  suggestionsCallback: _getPlaceSuggestions,
                  itemBuilder: (context, Map<String, String> suggestion) {
                    return ListTile(
                      title: Text(suggestion['description']!),
                    );
                  },
                  onSelected: (Map<String, String> suggestion) async {
                    // Automatically fill the form field with the selected suggestion
                    _typeAheadController.text = suggestion['description']!;
                    final placeId = suggestion['place_id']!;
                    await _getPlaceDetails(placeId);
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
                  controller:
                      _typeAheadController, // Make sure to assign the controller here
                ),

                const Gap(25),

                buildQuantityAdjustmentRow(),

                const Gap(20),

                // Confirm Order Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: buildWideGradientButton(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            isScrollControlled:
                                true, // This allows the modal to take more space
                            builder: (BuildContext context) {
                              return FractionallySizedBox(
                                heightFactor:
                                    0.95, // Adjust this value to control the height (0.0 - 1.0)
                                child: PaymentMethodModal(
                                  currentPosition: _currentPosition,
                                  deliveryDestination: selectedStreetName,
                                  deliveryLatitude:
                                      latitude, // Pass the latitude of the delivery destination
                                  deliveryLongitude:
                                      longitude, // Pass the longitude of the delivery destination
                                  totalPrice: widget.price * itemCount,
                                  quantity: itemCount,
                                  postId: widget.postId,
                                ),
                              );
                            },
                          );
                        },
                        label: 'Confirm Order',
                        startColor: LarosaColors.secondary,
                        endColor: LarosaColors.purple,
                      ),
                    ),
                    const SizedBox(
                        width: 70), // Add some spacing between the buttons
                    Expanded(
                      child: buildWideGradientButton(
                        onTap: () {
                          // Handle add to cart
                        },
                        label: 'Add to Cart',
                        startColor: LarosaColors.secondary,
                        endColor: LarosaColors.purple,
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

  Widget buildQuantityAdjustmentRow() {
    return ClipPath(
      clipper: WavyBorderClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LarosaColors.secondary,
              LarosaColors.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.only(top: 8.0, bottom: 30),
        child: Column(
          children: [
            const Gap(10),
            // Decrease Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 1 < 1) ? 1 : itemCount - 1;
                    });
                  },
                  label: '-1',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 5 < 1) ? 1 : itemCount - 5;
                    });
                  },
                  label: '-5',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 10 < 1) ? 1 : itemCount - 10;
                    });
                  },
                  label: '-10',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 20 < 1) ? 1 : itemCount - 20;
                    });
                  },
                  label: '-20',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 50 < 1) ? 1 : itemCount - 50;
                    });
                  },
                  label: '-50',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount = (itemCount - 100 < 1) ? 1 : itemCount - 100;
                    });
                  },
                  label: '-100',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
              ],
            ),
            const Gap(5),
            // Increase Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount++;
                    });
                  },
                  label: '+1',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount += 5;
                    });
                  },
                  label: '+5',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount += 10;
                    });
                  },
                  label: '+10',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount += 20;
                    });
                  },
                  label: '+20',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount += 50;
                    });
                  },
                  label: '+50',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),
                const Gap(6),
                buildGradientButton(
                  onTap: () {
                    setState(() {
                      itemCount += 100;
                    });
                  },
                  label: '+100',
                  startColor: LarosaColors.primary,
                  endColor: LarosaColors.purple,
                ),

                

              ],
            ),
            const Gap(10),
          ],
        ),
      ),
    );
  }
}
