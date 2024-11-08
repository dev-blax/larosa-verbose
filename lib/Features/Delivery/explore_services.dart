import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:url_launcher/url_launcher.dart';

import 'map_service.dart';

class ExploreModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: DefaultTabController(
                length: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Explore Nearby',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const TabBar(
                      labelColor: LarosaColors.primary,
                      unselectedLabelColor: Colors.white,
                      isScrollable: true,
                      tabs: [
                        Tab(text: "Hotels"),
                        Tab(text: "Restaurants"),
                        Tab(text: "Transportation"),
                        Tab(text: "Reservations"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: <Widget>[
                          Animate(
                            effects: const [
                              SlideEffect(
                                begin: Offset(0.2, 0),
                                end: Offset(0, 0),
                                curve: Curves.elasticOut,
                                duration: Duration(seconds: 3),
                              ),
                            ],
                            child: const NearbyList(
                              category: 'Hotels',
                              items: [
                                {'name': 'Grand Palace Hotel', 'info': 'Ocean Avenue', 'lat': '34.052235', 'lng': '-118.243683'},
                                {'name': 'The Imperial Suites', 'info': 'Riverside Drive', 'lat': '34.052431', 'lng': '-118.243819'},
                                {'name': 'Parkview Inn', 'info': 'Sunset Boulevard', 'lat': '34.050498', 'lng': '-118.256216'},
                                {'name': 'City Plaza Hotel', 'info': 'Hollywood Street', 'lat': '34.052987', 'lng': '-118.256799'},
                              ],
                            ),
                          ),
                          Animate(
                            effects: const [
                              SlideEffect(
                                begin: Offset(0.2, 0),
                                end: Offset(0, 0),
                                curve: Curves.elasticOut,
                                duration: Duration(seconds: 3),
                              ),
                            ],
                            child: const NearbyList(
                              category: 'Restaurants',
                              items: [
                                {'name': 'Sunshine Bistro', 'info': 'Main Street', 'lat': '34.052431', 'lng': '-118.243681'},
                                {'name': 'Blue Lagoon Seafood', 'info': 'Broadway', 'lat': '34.050821', 'lng': '-118.245716'},
                                {'name': 'Garden Grill', 'info': 'Market Road', 'lat': '34.051776', 'lng': '-118.242187'},
                                {'name': 'Redwood Steakhouse', 'info': '5th Avenue', 'lat': '34.053041', 'lng': '-118.251221'},
                              ],
                            ),
                          ),
                          Animate(
                            effects: const [
                              SlideEffect(
                                begin: Offset(0.2, 0),
                                end: Offset(0, 0),
                                curve: Curves.elasticOut,
                                duration: Duration(seconds: 3),
                              ),
                            ],
                            child: const NearbyList(
                              category: 'Transportation',
                              items: [
                                {'name': 'Green Taxi Services', 'info': 'Central Station', 'lat': '34.052200', 'lng': '-118.244684'},
                                {'name': 'City Bus Line', 'info': 'Highland Park', 'lat': '34.053678', 'lng': '-118.247213'},
                                {'name': 'Downtown Ride Share', 'info': 'Commerce Street', 'lat': '34.051498', 'lng': '-118.249111'},
                                {'name': 'Metro Light Rail', 'info': 'Central Plaza', 'lat': '34.052978', 'lng': '-118.250802'},
                              ],
                            ),
                          ),
                          Animate(
                            effects: const [
                              SlideEffect(
                                begin: Offset(0.2, 0),
                                end: Offset(0, 0),
                                curve: Curves.elasticOut,
                                duration: Duration(seconds: 3),
                              ),
                            ],
                            child: const NearbyList(
                              category: 'Reservations',
                              items: [
                                {'name': 'City Conference Center', 'info': 'Union Square', 'lat': '34.053334', 'lng': '-118.255442'},
                                {'name': 'Sunset Event Hall', 'info': 'Sunset Park', 'lat': '34.051211', 'lng': '-118.253116'},
                                {'name': 'Town Hall Meeting Room', 'info': 'Broadway', 'lat': '34.054990', 'lng': '-118.245200'},
                                {'name': 'Downtown Banquet Hall', 'info': 'Victory Street', 'lat': '34.052276', 'lng': '-118.246813'},
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NearbyList extends StatelessWidget {
  final String category;
  final List<Map<String, String>> items;

  const NearbyList({required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  LarosaColors.secondary,
                  LarosaColors.purple,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Card(
              elevation: 0, // Set elevation to 0 to let gradient shine through
              color: Colors.transparent, // Make card color transparent for gradient
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.asset(
                      'assets/images/banner_business.png',
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 3.0, left: 3, right: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item['info']} - $category',
                              style: const TextStyle(color: Colors.white),
                            ),
                            IconButton(
                              icon: const Icon(Icons.location_on, color: LarosaColors.primary,),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (BuildContext context) {
                                    return MapModal(
                                      latitude: double.parse(item['lat']!),
                                      longitude: double.parse(item['lng']!),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}