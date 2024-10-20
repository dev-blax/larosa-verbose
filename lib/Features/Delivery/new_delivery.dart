import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:ionicons/ionicons.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:iconsax/iconsax.dart';

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
              _sourceController.text = address; // Auto-fill the input
            } else {
              destinationLatitude = lat;
              destinationLongitude = lng;
              selectedDestinationStreetName = address;
              _destinationController.text = address; // Auto-fill the input
            }
          });
        }
      }
    } catch (e) {
      print('Error: $e');
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
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Iconsax.search_normal,
                          color: Colors.white,
                        ),
                        border: InputBorder.none,
                        labelText: 'Search for a source location',
                        labelStyle: TextStyle(color: Colors.white),
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
                onPressed: () {},
                child: const Text('Request a Ride'),
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
