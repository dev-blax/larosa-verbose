import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:larosa_block/Services/log_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:larosa_block/Utils/links.dart';

import '../../Components/cart_button.dart';
import '../../Services/auth_service.dart';
import '../../Services/geo_service.dart';
import '../../Utils/colors.dart';
import '../../Utils/svg_paths.dart';
import 'widgets/media_gallery_view.dart';
import 'widgets/payment_proceed_table.dart';
import 'widgets/payment_shimmer.dart';
import 'widgets/payment_summary_card.dart';
import 'payment_method_screen.dart';

class PrepareForPayment extends StatefulWidget {
  final List<int> productIds;
  final double totalPrice;
  final String combinedNames;
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
  Map<String, String> supplierLocations = {};
  int itemCount = 1;
  final TextEditingController _typeAheadController = TextEditingController();
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

  bool get isReservation => !widget.reservationType;

  // Store delivery costs for each product
  Map<int, String> productDeliveryCosts = {};
  String totalDeliveryCost = 'Calculating...';

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
      LarosaLinks.nakedBaseUrl,
      '/api/v1/delivery-cost/calculate',
    );

    if (latitude == null || longitude == null) {
      setState(() {
        totalDeliveryCost = 'Error: Missing destination data';
        estimatedTime = 'Error: Missing destination data';
      });
      return;
    }

    try {
      String token = AuthService.getToken();
      double totalCost = 0;

      // show alert with loading activity indicator
      // showCupertinoDialog(context: context, builder: (context) => CupertinoAlertDialog(
      //   title: Text('Loading...'),
      //   content: CupertinoActivityIndicator(),
      // ));

      // Fetch delivery cost for each product
      for (int productId in widget.productIds) {
        final Map<String, dynamic> requestBody = {
          "productId": productId,
          "customerLongitude": longitude!,
          "customerLatitude": latitude!,
          "country": "Tanzania",
          "city": "Dodoma"
        };

        final http.Response response = await http.post(
          uri,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(requestBody),
        );

        LogService.logFatal(
            'Transport Cost for product $productId: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          LogService.logFatal(
              'Transport Cost for product $productId: ${data['cost']}');
          final double cost = (data['cost'] as num).toDouble();

          setState(() {
            productDeliveryCosts[productId] = 'Tsh ${cost.toStringAsFixed(2)}';
            totalCost += cost;
          });
        } else {
          setState(() {
            productDeliveryCosts[productId] = 'Error';
          });
        }
      }

      setState(() {
        totalDeliveryCost = 'Tsh ${totalCost.toStringAsFixed(2)}';
        deliveryCost = totalDeliveryCost;
      });

      // hide alert
      // Navigator.of(context).pop();
    } catch (error) {
      setState(() {
        totalDeliveryCost = 'Error';
        estimatedTime = 'Error';
      });
      LogService.logError('Error in fetchTransportCost: $error');
    }
  }

  Future<void> _fetchExchangeRate() async {
    try {
      final response = await http.get(Uri.parse(
        'https://api.exchangerate-api.com/v4/latest/USD',
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['rates'] != null && data['rates']['TZS'] != null) {
          setState(() {
            _exchangeRate = data['rates']['TZS']; // Extract TZS rate
            print('exchange rate $_exchangeRate');
          });
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
      final int hours = minutes ~/ 60; // Calculate the number of full hours
      final int remainingMinutes = minutes % 60; // Calculate remaining minutes
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${minutes}min'; // Return as minutes if less than 60
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
  void initState() {
    super.initState();
    LogService.logInfo('Items: ${widget.itemsToDisplay}');
    _fetchExchangeRate();
    _getCurrentLocation().then((_) => fetchTransportCost());
    _getSupplierLocations();

    checkInDate = DateTime.now();
    checkOutDate = DateTime.now().add(const Duration(days: 1));
  }

  List<String?> _supplierLocationNames = [];
  void _getSupplierLocations() async {
    final latitudes = widget.itemsToDisplay
        .map((item) => (item['supplierLatitude'] as num).toDouble())
        .toList();
    final longitudes = widget.itemsToDisplay
        .map((item) => (item['supplierLongitude'] as num).toDouble())
        .toList();
    final locationNames = await GeoService.getLocationsNamesFromCoordinates(
        latitudes, longitudes);
    setState(() {
      _supplierLocationNames = locationNames;
    });

    LogService.logInfo('Supplier locations: $_supplierLocationNames');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            CupertinoIcons.back,
          ),
        ),
        title: const Text(
          'Proceed To Payment',
          style: TextStyle(fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: widget.itemsToDisplay.length,
              itemBuilder: (context, index) {
                final item = widget.itemsToDisplay[index];

                final imageUrls = (item['names'] ?? '').split(',');

                return Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? CupertinoColors.darkBackgroundGray
                            .withValues(alpha: 0.8)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    PageView.builder(
                                      itemCount: imageUrls.length,
                                      itemBuilder: (context, imgIndex) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    MediaGalleryView(
                                                  urls: imageUrls,
                                                  initialIndex: imgIndex,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Hero(
                                              tag:
                                                  '${item['productId']}_$imgIndex',
                                              child: CachedNetworkImage(
                                                imageUrl: imageUrls[imgIndex],
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorWidget: (context, error,
                                                        stackTrace) =>
                                                    Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: Icon(
                                                        CupertinoIcons.photo,
                                                        size: 40,
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                              )),
                                        );
                                      },
                                    ),
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Quantity ${item['quantity']} @ Tsh ${NumberFormat('#,##0', 'en_US').format(item['price'])} ',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.tag_solid,
                                            size: 20,
                                          ),
                                          Gap(4),
                                          Text(
                                            NumberFormat.currency(
                                              locale: 'sw_TZ',
                                              symbol: 'Tsh ',
                                              decimalDigits: 2,
                                            ).format(item['price'] *
                                                item['quantity']),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!widget.reservationType)
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            SvgIconsPaths.deliveryTruck,
                                            width: 24,
                                            height: 24,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[300]!
                                                  : Colors.grey[700]!,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const Gap(4),
                                          Text(
                                            productDeliveryCosts[
                                                    widget.productIds[index]] ??
                                                'Calculating...',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.location_solid,
                                            size: 20,
                                          ),
                                          Gap(5),
                                          Text(_supplierLocationNames.length >
                                                  index
                                              ? (_supplierLocationNames[
                                                      index] ??
                                                  'Location not available')
                                              : 'Loading location...')
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(8),
                if (_isLoadingLocation)
                  const PaymentShimmer()
                else if (_currentPosition != null)
                  PaymentSummaryCard(
                    isReservation: isReservation,
                    totalPrice: widget.totalPrice,
                    itemCount: itemCount,
                    deliveryCost: deliveryCost,
                    onViewDetails: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => DraggableScrollableSheet(
                          initialChildSize: 0.7,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          builder: (_, controller) => Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  height: 4,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[600]
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Expanded(
                                  child: ListView(
                                    controller: controller,
                                    padding: const EdgeInsets.all(16),
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Payment Details',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge,
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      PaymentProceedTable(
                                        isReservation: isReservation,
                                        currentStreetName: currentStreetName,
                                        totalQuantity: widget.totalQuantity,
                                        adults: adults,
                                        children: children,
                                        checkInDate: checkInDate,
                                        checkOutDate: checkOutDate,
                                        estimatedTime: estimatedTime,
                                        deliveryCost: deliveryCost,
                                        totalPrice: widget.totalPrice,
                                        itemCount: itemCount,
                                        exchangeRate: _exchangeRate,
                                        onAdultsChanged: (value) {
                                          setState(() {
                                            adults = value;
                                          });
                                        },
                                        onChildrenChanged: (value) {
                                          setState(() {
                                            children = value;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const Gap(10),
                const Divider(),
                const Gap(0),
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

                                    return;
                                  } else {
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  }
                                }

                                final totalPrice =
                                    widget.totalPrice * itemCount +
                                        double.parse(deliveryCost
                                            .replaceAll('Tsh ', '')
                                            .trim());

                                // check in data and checkout data
                                LogService.logInfo(
                                    'Check In Date: ${checkInDate}');
                                LogService.logInfo(
                                    'Check Out Date: ${checkOutDate}');

                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => PaymentMethodScreen(
                                      totalPrice: isReservation
                                          ? totalPrice
                                          : widget.totalPrice * itemCount,
                                      //paymentMethod: widget.paymentMethod,
                                      postId: widget.productIds,
                                      items: widget.items,
                                      quantity: widget.totalQuantity,
                                      deliveryDestination: selectedStreetName,
                                      deliveryLatitude: latitude,
                                      deliveryLongitude: longitude,
                                      adults: adults,
                                      children: children,
                                      fullName: _fullNameController.text.trim(),
                                      checkInDate: checkInDate,
                                      checkOutDate: checkOutDate,
                                      isReservation: !isReservation,
                                    ),
                                  ),
                                );
                              },
                              label: 'Pay Now',
                              startColor: LarosaColors.secondary,
                              endColor: LarosaColors.purple,
                            )
                          : const Center(
                              child: CupertinoActivityIndicator(
                                radius: 10.0, // Adjust the size as needed
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
