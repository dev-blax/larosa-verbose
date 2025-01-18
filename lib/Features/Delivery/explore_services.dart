import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:larosa_block/Utils/colors.dart';

import 'map_service.dart';

class ExploreModal extends StatelessWidget {
  const ExploreModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: GestureDetector(
          onTap: () {},
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: DefaultTabController(
              length: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Explore Nearby',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  const TabBar(
                    labelColor: LarosaColors.primary,
                    unselectedLabelColor: Colors.grey,
                    isScrollable: true,
                    tabs: [
                      Tab(
                        child: Text(
                          "Hotels",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Tab(
                        child: Text(
                          "Restaurants",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Tab(
                        child: Text(
                          "Transportation",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Tab(
                        child: Text(
                          "Reservations",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
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
                              {
                                'name': 'Grand Palace Hotel',
                                'info': 'Ocean Avenue',
                                'lat': '34.052235',
                                'lng': '-118.243683'
                              },
                              {
                                'name': 'The Imperial Suites',
                                'info': 'Riverside Drive',
                                'lat': '34.052431',
                                'lng': '-118.243819'
                              },
                              {
                                'name': 'Parkview Inn',
                                'info': 'Sunset Boulevard',
                                'lat': '34.050498',
                                'lng': '-118.256216'
                              },
                              {
                                'name': 'City Plaza Hotel',
                                'info': 'Hollywood Street',
                                'lat': '34.052987',
                                'lng': '-118.256799'
                              },
                              {
                                'name': 'Luxury Residence Hotel',
                                'info': 'Hilltop Road',
                                'lat': '34.054123',
                                'lng': '-118.255321'
                              },
                              {
                                'name': 'Skyline Lodge',
                                'info': 'Mountain Street',
                                'lat': '34.052741',
                                'lng': '-118.254613'
                              },
                              {
                                'name': 'Paradise Inn',
                                'info': 'Pine Avenue',
                                'lat': '34.053422',
                                'lng': '-118.252116'
                              },
                              {
                                'name': 'Urban Stay Suites',
                                'info': 'Lake Boulevard',
                                'lat': '34.053600',
                                'lng': '-118.248741'
                              },
                              {
                                'name': 'Downtown Guesthouse',
                                'info': 'Spring Street',
                                'lat': '34.052512',
                                'lng': '-118.250200'
                              },
                              {
                                'name': 'Sunset Retreat',
                                'info': 'Beach Road',
                                'lat': '34.051212',
                                'lng': '-118.249612'
                              },
                              {
                                'name': 'Metro Suites',
                                'info': '5th Avenue',
                                'lat': '34.053341',
                                'lng': '-118.244234'
                              },
                              {
                                'name': 'The Pearl Inn',
                                'info': 'Market Road',
                                'lat': '34.051801',
                                'lng': '-118.245501'
                              },
                              {
                                'name': 'Oceanview Hotel',
                                'info': 'Broadway',
                                'lat': '34.052401',
                                'lng': '-118.243401'
                              },
                              {
                                'name': 'Harbor Breeze',
                                'info': 'River Road',
                                'lat': '34.054001',
                                'lng': '-118.240500'
                              },
                              {
                                'name': 'Garden View Suites',
                                'info': 'Pine Street',
                                'lat': '34.050901',
                                'lng': '-118.246711'
                              },
                              {
                                'name': 'Summit Lodge',
                                'info': 'Mountain Drive',
                                'lat': '34.053781',
                                'lng': '-118.247601'
                              },
                              {
                                'name': 'The Starlight',
                                'info': 'Highland Road',
                                'lat': '34.052371',
                                'lng': '-118.241213'
                              },
                              {
                                'name': 'City Heights Inn',
                                'info': 'Liberty Street',
                                'lat': '34.052091',
                                'lng': '-118.243821'
                              },
                              {
                                'name': 'Coastline Hotel',
                                'info': 'Main Street',
                                'lat': '34.053412',
                                'lng': '-118.242132'
                              },
                              {
                                'name': 'Hillside Suites',
                                'info': '5th Street',
                                'lat': '34.054213',
                                'lng': '-118.246912'
                              },
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
                              {
                                'name': 'Sunshine Bistro',
                                'info': 'Main Street',
                                'lat': '34.052431',
                                'lng': '-118.243681'
                              },
                              {
                                'name': 'Blue Lagoon Seafood',
                                'info': 'Broadway',
                                'lat': '34.050821',
                                'lng': '-118.245716'
                              },
                              {
                                'name': 'Garden Grill',
                                'info': 'Market Road',
                                'lat': '34.051776',
                                'lng': '-118.242187'
                              },
                              {
                                'name': 'Redwood Steakhouse',
                                'info': '5th Avenue',
                                'lat': '34.053041',
                                'lng': '-118.251221'
                              },
                              {
                                'name': 'The Local Diner',
                                'info': 'Riverfront Street',
                                'lat': '34.054321',
                                'lng': '-118.244981'
                              },
                              {
                                'name': 'Bistro & Grill',
                                'info': 'Hillcrest Road',
                                'lat': '34.053881',
                                'lng': '-118.247009'
                              },
                              {
                                'name': 'City Cafe',
                                'info': 'Ocean Avenue',
                                'lat': '34.052411',
                                'lng': '-118.248712'
                              },
                              {
                                'name': 'Sunset Bistro',
                                'info': 'Sunset Boulevard',
                                'lat': '34.051401',
                                'lng': '-118.243899'
                              },
                              {
                                'name': 'The Coffee House',
                                'info': 'Mountain Street',
                                'lat': '34.053900',
                                'lng': '-118.245099'
                              },
                              {
                                'name': 'Urban Eatery',
                                'info': 'Union Square',
                                'lat': '34.054213',
                                'lng': '-118.247412'
                              },
                              {
                                'name': 'Downtown Deli',
                                'info': '5th Avenue',
                                'lat': '34.051121',
                                'lng': '-118.249712'
                              },
                              {
                                'name': 'Greenway Cafe',
                                'info': 'Liberty Road',
                                'lat': '34.052621',
                                'lng': '-118.241812'
                              },
                              {
                                'name': 'Sunrise Diner',
                                'info': 'River Road',
                                'lat': '34.051211',
                                'lng': '-118.246000'
                              },
                              {
                                'name': 'Ocean Grill',
                                'info': 'Broadway',
                                'lat': '34.050999',
                                'lng': '-118.243700'
                              },
                              {
                                'name': 'The Riverside Inn',
                                'info': 'Market Road',
                                'lat': '34.052711',
                                'lng': '-118.250000'
                              },
                              {
                                'name': 'Harvest Bistro',
                                'info': 'Highland Road',
                                'lat': '34.051621',
                                'lng': '-118.245521'
                              },
                              {
                                'name': 'The Carriage House',
                                'info': 'Grand Avenue',
                                'lat': '34.054341',
                                'lng': '-118.244321'
                              },
                              {
                                'name': 'Sunset Point',
                                'info': 'Central Park',
                                'lat': '34.052234',
                                'lng': '-118.243982'
                              },
                              {
                                'name': 'City Pizza',
                                'info': 'Lake Road',
                                'lat': '34.053312',
                                'lng': '-118.249432'
                              },
                              {
                                'name': 'Riverside Cafe',
                                'info': 'Green Street',
                                'lat': '34.053112',
                                'lng': '-118.245832'
                              },
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
                              {
                                'name': 'Green Taxi Services',
                                'info': 'Central Station',
                                'lat': '34.052200',
                                'lng': '-118.244684'
                              },
                              {
                                'name': 'City Bus Line',
                                'info': 'Highland Park',
                                'lat': '34.053678',
                                'lng': '-118.247213'
                              },
                              {
                                'name': 'Downtown Ride Share',
                                'info': 'Commerce Street',
                                'lat': '34.051498',
                                'lng': '-118.249111'
                              },
                              {
                                'name': 'Metro Light Rail',
                                'info': 'Central Plaza',
                                'lat': '34.052978',
                                'lng': '-118.250802'
                              },
                              {
                                'name': 'Rapid Ride',
                                'info': 'Park Avenue',
                                'lat': '34.051671',
                                'lng': '-118.245671'
                              },
                              {
                                'name': 'Express Shuttle',
                                'info': 'Lake Drive',
                                'lat': '34.053741',
                                'lng': '-118.243871'
                              },
                              {
                                'name': 'Blue Line Metro',
                                'info': 'River Station',
                                'lat': '34.052500',
                                'lng': '-118.248012'
                              },
                              {
                                'name': 'Uber Central',
                                'info': 'Sunset Street',
                                'lat': '34.050998',
                                'lng': '-118.245821'
                              },
                              {
                                'name': 'Yellow Cab Service',
                                'info': '5th Street',
                                'lat': '34.053011',
                                'lng': '-118.249009'
                              },
                              {
                                'name': 'Coastal Rides',
                                'info': 'Ocean Road',
                                'lat': '34.051231',
                                'lng': '-118.248112'
                              },
                              {
                                'name': 'Red Taxi Service',
                                'info': 'Main Street',
                                'lat': '34.050543',
                                'lng': '-118.249211'
                              },
                              {
                                'name': 'City Metro',
                                'info': 'Market Plaza',
                                'lat': '34.054211',
                                'lng': '-118.244711'
                              },
                              {
                                'name': 'Union Line Taxi',
                                'info': 'Broadway',
                                'lat': '34.051761',
                                'lng': '-118.247111'
                              },
                              {
                                'name': 'Lakeside Express',
                                'info': 'Riverside',
                                'lat': '34.052811',
                                'lng': '-118.249501'
                              },
                              {
                                'name': 'Central Shuttle',
                                'info': 'Liberty Drive',
                                'lat': '34.053901',
                                'lng': '-118.242321'
                              },
                              {
                                'name': 'Freedom Cab',
                                'info': 'Grand Boulevard',
                                'lat': '34.054651',
                                'lng': '-118.246711'
                              },
                              {
                                'name': 'Urban Car Service',
                                'info': 'Downtown Street',
                                'lat': '34.052300',
                                'lng': '-118.243412'
                              },
                              {
                                'name': 'Highway Transport',
                                'info': 'Mountain Road',
                                'lat': '34.051299',
                                'lng': '-118.250221'
                              },
                              {
                                'name': 'City Rail Link',
                                'info': 'Hilltop',
                                'lat': '34.052999',
                                'lng': '-118.247101'
                              },
                              {
                                'name': 'Express Line',
                                'info': 'Central Ave',
                                'lat': '34.053400',
                                'lng': '-118.248900'
                              },
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
                              {
                                'name': 'City Conference Center',
                                'info': 'Union Square',
                                'lat': '34.053334',
                                'lng': '-118.255442'
                              },
                              {
                                'name': 'Sunset Event Hall',
                                'info': 'Sunset Park',
                                'lat': '34.051211',
                                'lng': '-118.253116'
                              },
                              {
                                'name': 'Town Hall Meeting Room',
                                'info': 'Broadway',
                                'lat': '34.054990',
                                'lng': '-118.245200'
                              },
                              {
                                'name': 'Downtown Banquet Hall',
                                'info': 'Victory Street',
                                'lat': '34.052276',
                                'lng': '-118.246813'
                              },
                              {
                                'name': 'Highland Pavilion',
                                'info': 'Highland Avenue',
                                'lat': '34.053817',
                                'lng': '-118.249212'
                              },
                              {
                                'name': 'Riverside Ballroom',
                                'info': 'Lake Drive',
                                'lat': '34.052899',
                                'lng': '-118.251611'
                              },
                              {
                                'name': 'Greenwood Gardens',
                                'info': 'Central Plaza',
                                'lat': '34.051999',
                                'lng': '-118.244221'
                              },
                              {
                                'name': 'Summit Conference Room',
                                'info': 'Ocean Avenue',
                                'lat': '34.053211',
                                'lng': '-118.247311'
                              },
                              {
                                'name': 'Urban Events',
                                'info': 'Commerce Street',
                                'lat': '34.052811',
                                'lng': '-118.248432'
                              },
                              {
                                'name': 'Sunrise Meeting Hall',
                                'info': '5th Avenue',
                                'lat': '34.051541',
                                'lng': '-118.245621'
                              },
                              {
                                'name': 'Grand Convention Center',
                                'info': 'Liberty Road',
                                'lat': '34.050912',
                                'lng': '-118.249721'
                              },
                              {
                                'name': 'Conference Inn',
                                'info': 'Market Road',
                                'lat': '34.053212',
                                'lng': '-118.243312'
                              },
                              {
                                'name': 'Lakeside Event Hall',
                                'info': 'River Road',
                                'lat': '34.054912',
                                'lng': '-118.247912'
                              },
                              {
                                'name': 'Event Space Downtown',
                                'info': 'Broadway',
                                'lat': '34.052678',
                                'lng': '-118.249831'
                              },
                              {
                                'name': 'Central Park Pavilion',
                                'info': 'Park Street',
                                'lat': '34.054500',
                                'lng': '-118.250112'
                              },
                              {
                                'name': 'Oceanfront Banquet',
                                'info': 'Ocean Avenue',
                                'lat': '34.051999',
                                'lng': '-118.244421'
                              },
                              {
                                'name': 'Grand Ballroom',
                                'info': 'Mountain Drive',
                                'lat': '34.052111',
                                'lng': '-118.245111'
                              },
                              {
                                'name': 'Sunset Terrace',
                                'info': 'Sunset Boulevard',
                                'lat': '34.051111',
                                'lng': '-118.247712'
                              },
                              {
                                'name': 'Town Hall Convention Center',
                                'info': 'Victory Lane',
                                'lat': '34.054221',
                                'lng': '-118.251001'
                              },
                              {
                                'name': 'Downtown Expo Hall',
                                'info': 'Commerce Avenue',
                                'lat': '34.050812',
                                'lng': '-118.248221'
                              },
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
    );
  }
}

class NearbyList extends StatelessWidget {
  final String category;
  final List<Map<String, String>> items;

  const NearbyList({super.key, required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Animate(
          effects: const [
            SlideEffect(
              begin: Offset(0.2, 0), // Slide in from the right
              end: Offset(0, 0), // End position
              curve: Curves.elasticOut,
              duration: Duration(seconds: 4), // Adjust duration as needed
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LarosaColors.primary, LarosaColors.secondary],
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
                elevation: 0, // Keep card transparent for gradient background
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.asset(
                        'assets/images/banner_business.png',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 3.0, left: 8, right: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item['info']} - $category',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                ),
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
          ),
        );
      },
    );
  }
}

