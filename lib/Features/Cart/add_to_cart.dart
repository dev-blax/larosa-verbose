import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class AddToCartScreen extends StatefulWidget {
  final String username;
  final double price;
  final String names;

  const AddToCartScreen({
    super.key,
    required this.username,
    required this.price,
    required this.names,
  });

  @override
  State<AddToCartScreen> createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends State<AddToCartScreen> {
  int itemCount = 1;
  final TextEditingController _typeAheadController = TextEditingController();
  String? selectedStreetName;
  double? latitude;
  double? longitude;

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
        print('Response body: ${response.body}'); // Debugging response

        if (json['result'] != null && json['result']['geometry'] != null) {
          final location = json['result']['geometry']['location'];
          final address = json['result']['formatted_address'];
          final lat = location['lat'];
          final lng = location['lng'];

          // Print the latitude, longitude, and street name
          print('Address: $address');
          print('Latitude: $lat');
          print('Longitude: $lng');

          setState(() {
            latitude = lat;
            longitude = lng;
            selectedStreetName = address;
          });
        } else {
          print('Error: Geometry or result field is missing in the response.');
        }
      } else {
        print('Error: Failed to load place details with status code ${response.statusCode}.');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert comma-separated names into a list of image URLs
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
                // Display selected location details if available
                if (selectedStreetName != null && latitude != null && longitude != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Location',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Street: $selectedStreetName',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Latitude: $latitude',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Longitude: $longitude',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                const Gap(10),
                const Text('Description'),
                const Text(
                  'Some cool caption about the above product to make the customer buy',
                ),
                const Gap(20),
                // Decrease Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount = (itemCount - 1 < 1) ? 1 : itemCount - 1;
                        });
                      },
                      child: const Text(
                        '-1',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Gap(4),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount = (itemCount - 5 < 1) ? 1 : itemCount - 5;
                        });
                      },
                      child: const Text(
                        '-5',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Gap(4),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount = (itemCount - 10 < 1) ? 1 : itemCount - 10;
                        });
                      },
                      child: const Text(
                        '-10',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Gap(4),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount = (itemCount - 20 < 1) ? 1 : itemCount - 20;
                        });
                      },
                      child: const Text(
                        '-20',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Gap(4),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount = (itemCount - 50 < 1) ? 1 : itemCount - 50;
                        });
                      },
                      child: const Text(
                        '-50',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Gap(5),
                // Increase Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount++;
                        });
                      },
                      child: const Text(
                        '+1',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Gap(4),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount += 5;
                        });
                      },
                      child: const Text(
                        '+5',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Gap(4),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount += 10;
                        });
                      },
                      child: const Text(
                        '+10',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Gap(4),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount += 20;
                        });
                      },
                      child: const Text(
                        '+20',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Gap(4),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          itemCount += 50;
                        });
                      },
                      child: const Text(
                        '+50',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                if(selectedStreetName == null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            contentPadding: const EdgeInsets.all(8.0), // Reduce padding here
                            title: const Text('Select Destination'),
                            content: ClipRRect(
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
                                  child: TypeAheadField<Map<String, String>>(
                                    suggestionsCallback: _getPlaceSuggestions,
                                    itemBuilder: (context, Map<String, String> suggestion) {
                                      return ListTile(
                                        title: Text(suggestion['description']!),
                                      );
                                    },
                                    onSelected: (Map<String, String> suggestion) async {
                                      _typeAheadController.text = suggestion['description']!;
                                      final placeId = suggestion['place_id']!;
                                      await _getPlaceDetails(placeId);
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
                                          labelText: 'Search for a destination',
                                          labelStyle:
                                              TextStyle(color: Colors.white),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Add logic to process the selected destination and order
                                },
                                child: const Text('Confirm'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Pay Now',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if(selectedStreetName != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: (){
                    showCupertinoModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      height: 400,
                      color: Colors.white,
                      child: Column(
                        children: [
                          Text('Payment Details'),
                          Divider(),
                          Row(
                            children: [
                              Image.asset('assets/images/tigo.png', width: 20,),
                              Image.asset('assets/images/tigo.png', width: 20,),
                              Image.asset('assets/images/tigo.png', width: 20,),
                              Image.asset('assets/images/tigo.png', width: 20,),
                            ],
                          )
                        ],
                      )
                    ),
                  );
                  }, child: Text('Continue'),),
                ),

                
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text(
                      'Add To Cart',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                

              ],
            ),
          )
        ],
      ),
    );
  }
}
