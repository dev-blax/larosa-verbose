import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:location/location.dart' as loc;
import '../../../Services/dio_service.dart';
import '../../../Services/maps_service.dart';
import '../models/ride_model.dart';
import 'package:logger/logger.dart';

class RideController extends ChangeNotifier {
  // Location
  final loc.Location _location = loc.Location();
  loc.LocationData? _currentLocation;
  bool _serviceEnabled = false;
  loc.PermissionStatus? _permissionGranted;

  // Map
  GoogleMapController? _mapController;
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(-6.1630, 35.7516), // Default to Dodoma, Tanzania
    zoom: 15,
  );
  Set<Polyline> _routePolylines = {};
  Set<Marker> _markers = {};

  // Ride details
  String? _pickupLocation;
  String? _destination;
  LatLng? _destinationLatLng;
  RideType _selectedRideType = RideType.economy;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;

  // Booking state
  bool _isBookingInProgress = false;
  bool _isDriverFound = false;
  // list of assigned drivers
  List<DriverModel> _assignedDrivers = [];
  DriverModel? _assignedDriver;

  // Suggestions
  final List<LocationSuggestion> _locationSuggestions =
      LocationSuggestion.getMockSuggestions();

  // Getters
  loc.LocationData? get currentLocation => _currentLocation;
  GoogleMapController? get mapController => _mapController;
  Set<Polyline> get routePolylines => _routePolylines;
  Set<Marker> get markers => _markers;
  CameraPosition get initialCameraPosition => _initialCameraPosition;
  String? get pickupLocation => _pickupLocation;
  String? get destination => _destination;
  RideType get selectedRideType => _selectedRideType;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;
  bool get isBookingInProgress => _isBookingInProgress;
  bool get isDriverFound => _isDriverFound;
  List<DriverModel> get assignedDrivers => _assignedDrivers;
  DriverModel? get assignedDriver => _assignedDriver;
  List<LocationSuggestion> get locationSuggestions => _locationSuggestions;

  // Initialize
  Future<void> initialize() async {
    await _checkLocationPermission();
    if (_permissionGranted == loc.PermissionStatus.granted) {
      await getCurrentLocation();
    }
  }

  // Check location permission
  Future<void> _checkLocationPermission() async {
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == loc.PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != loc.PermissionStatus.granted) {
        return;
      }
    }
  }

  // Get current location and return formatted address
  Future<String?> getCurrentLocation() async {
    try {
      _currentLocation = await _location.getLocation();
      if (_currentLocation != null) {
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            ),
          );
        }

        final placemarks = await placemarkFromCoordinates(
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
        );

        Logger().i('current location: $_currentLocation');

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final address = [
            placemark.street,
            placemark.subLocality,
            placemark.locality,
            placemark.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          return address;
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    } finally {
      notifyListeners();
    }
    return null;
  }

  // Set map controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        ),
      );
    }
  }

  // Set pickup location
  Future<void> setPickupLocation(String location) async {
    _pickupLocation = location;
    await _updateRouteOnMap();
    notifyListeners();
  }

  // Update route on map
  Future<void> _updateRouteOnMap() async {
    if (_currentLocation == null || _destinationLatLng == null) return;

    try {
      final response = await DioService().dio.get(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin':
              '${_currentLocation!.latitude},${_currentLocation!.longitude}',
          'destination':
              '${_destinationLatLng!.latitude},${_destinationLatLng!.longitude}',
          'key': MapsService.apiKey,
        },
      );

      if (response.data['status'] == 'OK') {
        final points =
            response.data['routes'][0]['overview_polyline']['points'];
        final decodedPoints = _decodePolyline(points);

        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 4,
            points: decodedPoints,
          ),
        };

        _markers = {
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(
                _currentLocation!.latitude!, _currentLocation!.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationLatLng!,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        };

        // Adjust map bounds to show the entire route
        if (_mapController != null) {
          final bounds = LatLngBounds(
            southwest: LatLng(
              decodedPoints.map((p) => p.latitude).reduce(min),
              decodedPoints.map((p) => p.longitude).reduce(min),
            ),
            northeast: LatLng(
              decodedPoints.map((p) => p.latitude).reduce(max),
              decodedPoints.map((p) => p.longitude).reduce(max),
            ),
          );

          await _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      }
    } catch (e) {
      LogService.logError('Error updating route: $e');
    }
    notifyListeners();
  }

  // Decode Google Maps polyline string
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Set destination with coordinates
  Future<void> setDestination(String location,
      {double? lat, double? lng}) async {
    _destination = location;
    if (lat != null && lng != null) {
      _destinationLatLng = LatLng(lat, lng);
      await _updateRouteOnMap();
    }
    notifyListeners();
  }

  // Set ride type
  void setRideType(RideType type) {
    _selectedRideType = type;
    notifyListeners();
  }

  // Set payment method
  void setPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  // Book ride
  void Function(String)? _onError;

  void setErrorCallback(void Function(String) callback) {
    _onError = callback;
  }

  Future<void> bookRide() async {
    if (_pickupLocation == null || _destination == null) {
      return;
    }

    _isBookingInProgress = true;
    notifyListeners();

    final cost = await calculateTransportCost();
    LogService.logInfo('Cost: $cost');
    final vehicleEstimations = cost['vehicleEstimations'] as List;
    LogService.logInfo('Vehicle Estimations: $vehicleEstimations');
    for (var vehicleEstimation in vehicleEstimations) {
      _assignedDriver = DriverModel(
        id: 'driver-123',
        name: 'James Mbogo',
        photoUrl:
            'https://images.pexels.com/photos/32046645/pexels-photo-32046645/free-photo-of-stylish-man-in-cap-and-glasses-in-istanbul.jpeg?auto=compress&cs=tinysrgb&w=600',
        vehicleType: vehicleEstimation['vehicleType'],
        vehicleNumber: 'T 123 ABC',
        rating: 4.8,
        estimatedArrivalTimeInMinutes: vehicleEstimation['pickupDuration'],
        cost: vehicleEstimation['cost'],
        routeDuration: vehicleEstimation['routeDuration'],
        costAfterOffer: vehicleEstimation['costAfterOffer'],
      );
      if (_assignedDriver?.estimatedArrivalTimeInMinutes != 0) {
        _assignedDrivers.add(_assignedDriver!);
      }
    }

    if (_assignedDrivers.isEmpty) {
      _onError?.call('No drivers found at the moment. Please try again later.');
      _isBookingInProgress = false;
      notifyListeners();
      return;
    }

    _isDriverFound = true;
    _isBookingInProgress = false;
    notifyListeners();
  }

  // Reset ride
  void resetRide() {
    _pickupLocation = null;
    _destination = null;
    _isBookingInProgress = false;
    _isDriverFound = false;
    _assignedDriver = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> calculateTransportCost() async {
    if (_currentLocation == null || _destinationLatLng == null) {
      return {'error': 'Missing location coordinates'};
    }

    final requestBody = {
      'startLat': _currentLocation!.latitude!.toStringAsFixed(4),
      'startLng': _currentLocation!.longitude!.toStringAsFixed(4),
      'endLat': _destinationLatLng!.latitude.toStringAsFixed(4),
      'endLng': _destinationLatLng!.longitude.toStringAsFixed(4),
      'cityName': 'dodoma',
      'country': 'Tanzania',
    };

    LogService.logFatal('Request body: $requestBody');

    try {
      final response = await DioService().dio.post(
            '${LarosaLinks.baseurl}/api/v1/transport-cost/calculate',
            data: requestBody,
          );
      return response.data;
    } catch (e) {
      LogService.logError('Error calculating transport cost: $e');
      return {'error': 'Failed to calculate transport cost'};
    }
  }

  Future<void> acceptVehicle() async {
    if (_assignedDriver == null) {
      return;
    }

    _isBookingInProgress = true;
    notifyListeners();

    final requestBody = {
      "startLat": _currentLocation!.latitude!,
      "startLng": _currentLocation!.longitude!,
      "endLat": _destinationLatLng!.latitude,
      "endLng": _destinationLatLng!.longitude,
      "city": "dodoma",
      "country": "Tanzania",
      "paymentMethod": "CASH",
      "vehicleType": "MOTORCYCLE"
    };

    LogService.logTrace('Request body: $requestBody');

    var response = await DioService().dio.post(
      '${LarosaLinks.baseurl}/api/v1/ride/request',
      data: requestBody,
    );

    if(response.statusCode == 200){
      LogService.logTrace(response.data);
    }

    _isBookingInProgress = false;
    notifyListeners();
  }


  Future<void> cancelRide() async {
    // Clear route lines and markers
    _routePolylines = {};
    _markers = {};
    
    // Reset driver-related state
    _isDriverFound = false;
    _assignedDrivers = [];
    _assignedDriver = null;
    _destinationLatLng = null;
    _destination = null;
    
    notifyListeners();
  }
}
