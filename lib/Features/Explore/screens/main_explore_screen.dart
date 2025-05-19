import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../Components/bottom_navigation.dart';

class MainExploreScreen extends StatefulWidget {
  const MainExploreScreen({super.key});

  @override
  State<MainExploreScreen> createState() => _MainExploreScreenState();
}

class _MainExploreScreenState extends State<MainExploreScreen> {
  final List<String> _titles = [
    'Looking for a fast town trip?',
    'Explore your beautiful World!',
    'Explore Nearby Services',
    'Shop With Us',
    'Explore Movies',
  ];

  final List<IconData> _icons = [
    CupertinoIcons.car,
    CupertinoIcons.globe,
    CupertinoIcons.location,
    CupertinoIcons.shopping_cart,
    CupertinoIcons.video_camera,
  ];

  final List<String> _backgroundImages = [
    'assets/images/trip.jpg',
    'assets/images/world_globe.jpg',
    'assets/images/nearby_services.jpg',
    'assets/images/shopping.jpg',
    'assets/images/popcorn.jpg'
  ];

  final List<String> _routes = [
    '/ride',
    '/beautiful-world',
    '/reservations',
    '/marketplace',
    '/movies'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Explore',
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ListView.builder(
              itemCount: _titles.length + 1,
              itemBuilder: (context, index) {
                if (index == _titles.length) {
                  return Container(height: 100);
                }
                return _buildListTile(
                  _titles[index],
                  _icons[index],
                  _backgroundImages[index],
                  _routes[index],
                );
              },
            ),
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

  Widget _buildListTile(
      String title, IconData icon, String imagePath, String route) {
    return GestureDetector(
      onTap: () {
        context.push(route);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            height: 100,
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                height: 100,
                width: double.infinity,
              ),
            ),
          ),
          Positioned(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withAlpha(128),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
              ),
              Gap(10),
              Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }
}
