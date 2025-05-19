import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/ride_controller.dart';
import '../RideWidgets/destination_input.dart';
import '../RideWidgets/driver_card.dart';
import '../RideWidgets/loading_animation.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();
  bool _showBookingForm = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _getCurrentLocation() async {
    final controller = Provider.of<RideController>(context, listen: false);
    final address = await controller.getCurrentLocation();
    if (mounted && address != null) {
      _pickupController.text = address;
      controller.setPickupLocation(address);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Provider.of<RideController>(context, listen: false);
      await controller.initialize();
      // Set up error handling
      controller.setErrorCallback((message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      });
      // Get current location immediately and keep updating it
      await _getCurrentLocation();
      // Set up periodic location updates every 30 seconds
      Timer.periodic(const Duration(seconds: 30), (_) => _getCurrentLocation());
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _pickupFocusNode.dispose();
    _destinationFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RideController>(
        builder: (context, rideController, child) {
          return Stack(
            children: [
              _buildMap(rideController),
              if (!_showBookingForm) _buildDestinationButton(context),
              if (_showBookingForm) _buildBookingForm(context, rideController),
              if (rideController.isBookingInProgress)
                Center(child: LoadingAnimation()),
              if (rideController.isDriverFound)
                Positioned(
                  bottom: 90,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 250,
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            
                            child: PageView.builder(
                              controller: _pageController,
                              scrollDirection: Axis.horizontal,
                              itemCount: rideController.assignedDrivers.length,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              itemBuilder: (context, index) {
                                final driver =
                                    rideController.assignedDrivers[index];
                                return Stack(
                                  children: [
                                    DriverCard(driver: driver),
                                    if (index <
                                        rideController.assignedDrivers.length -
                                            1)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 20,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Colors.white.withOpacity(0),
                                                Colors.black.withOpacity(0.1),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          if (rideController.assignedDrivers.length > 1)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (rideController.assignedDrivers.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              rideController.assignedDrivers.length,
                              (index) => Container(
                                width: 8,
                                height: 8,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == index
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Bottom Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(context, rideController),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(RideController rideController) {
    return GoogleMap(
      initialCameraPosition: rideController.initialCameraPosition,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      polylines: rideController.routePolylines,
      markers: rideController.markers,
      style: '''
          [
            {
              "featureType": "all",
              "elementType": "geometry",
              "stylers": [
                { "color": "#f5f5f5" }
              ]
            },
            {
              "featureType": "road",
              "elementType": "geometry",
              "stylers": [
                { "color": "#ffffff" }
              ]
            },
            {
              "featureType": "water",
              "elementType": "geometry",
              "stylers": [
                { "color": "#c9c9c9" }
              ]
            },
            {
              "featureType": "poi",
              "elementType": "geometry",
              "stylers": [
                { "color": "#e5e5e5" }
              ]
            }
          ]
        ''',
      onMapCreated: (GoogleMapController controller) {
        rideController.setMapController(controller);
      },
    );
  }

  Widget _buildDestinationButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showBookingForm = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.search, color: Colors.black87),
              SizedBox(width: 12),
              Text(
                'Where to?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingForm(
      BuildContext context, RideController rideController) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 90,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            _showBookingForm = false;
                          });
                        },
                      ),
                      const Text(
                        'Book a Ride',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Pickup Location
                  TextField(
                    controller: _pickupController,
                    enabled: false,
                    decoration: const InputDecoration(
                      hintText: 'Getting current location...',
                      prefixIcon: Icon(Icons.my_location),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Destination
                  DestinationInput(
                    controller: _destinationController,
                    focusNode: _destinationFocusNode,
                    onDestinationSelected: (destination,
                        {double? lat, double? lng}) {
                      rideController.setDestination(destination,
                          lat: lat, lng: lng);
                    },
                    onProceedToBooking: () {
                      if (_pickupController.text.isNotEmpty &&
                          _destinationController.text.isNotEmpty) {
                        setState(() {
                          _showBookingForm = false;
                        });
                        rideController.bookRide();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, RideController rideController) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: () {
            if (rideController.isDriverFound) {
              // Cancel ride and restore initial state
              setState(() {
                _showBookingForm = false;
                _currentPage = 0;
                _pickupController.clear();
                _destinationController.clear();
              });
              rideController.cancelRide();
              _getCurrentLocation(); // Refresh pickup location
            } else if (_showBookingForm) {
              if (_pickupController.text.isNotEmpty &&
                  _destinationController.text.isNotEmpty) {
                setState(() {
                  _showBookingForm = false;
                });
                rideController.bookRide();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please enter pickup and destination locations'),
                  ),
                );
              }
            } else {
              setState(() {
                _showBookingForm = true;
              });
            }
          },
          child: Text(
            rideController.isDriverFound
                ? 'Cancel Ride'
                : _showBookingForm
                    ? 'Ride Now'
                    : 'Book a Ride',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
