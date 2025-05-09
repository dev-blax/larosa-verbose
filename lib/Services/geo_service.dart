import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:flutter/material.dart';

class GeoService {
  static final GeoService _instance = GeoService._internal();
  static const int _maxRetries = 2;
  static const Duration _timeout = Duration(seconds: 10);
  
  factory GeoService() {
    return _instance;
  }

  GeoService._internal();

  Future<bool?> _showLocationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Enable Location'),
          content: const Text(
            'Larosa needs your location to enhance your experience by showing relevant content and deals near you. This helps us connect you with the best local experiences.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Not Now'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Allow'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  Future<Position?> getCurrentLocation({BuildContext? context}) async {
    int retryCount = 0;
    while (retryCount <= _maxRetries) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          LogService.logError('Location services are disabled. Attempt ${retryCount + 1}/$_maxRetries');
          if (retryCount == _maxRetries) return null;
          retryCount++;
          continue;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          if (context != null) {
            bool shouldProceed = await _showLocationDialog(context) ?? false;
            if (!shouldProceed) {
              LogService.logInfo('User declined location permission from dialog');
              return null;
            }
          }
          
          LogService.logInfo('Requesting location permission. Attempt ${retryCount + 1}/$_maxRetries');
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            LogService.logError('Location permissions denied. Attempt ${retryCount + 1}/$_maxRetries');
            if (retryCount == _maxRetries) return null;
            retryCount++;
            continue;
          }
        }
        
        if (permission == LocationPermission.deniedForever) {
          LogService.logError('Location permissions permanently denied');
          return null;
        }

        LogService.logInfo('Fetching location with timeout: $_timeout');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: _timeout,
        );
        LogService.logInfo('Location fetch successful: ${position.latitude}, ${position.longitude}');
        return position;
      } catch (e) {
        LogService.logError('Error getting location (Attempt ${retryCount + 1}/$_maxRetries): $e');
        if (retryCount == _maxRetries) return null;
        retryCount++;
        await Future.delayed(Duration(seconds: 1));
      }
    }
    return null;
  }


  // Get location name from latitude and longitude
  static Future<String?> getLocationNameFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
        // -6.7474,
        // 39.2817
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        LogService.logInfo('Location name: ${place.toString()}');

        final locality = place.locality ?? '';
        final subLocality = place.subLocality ?? '';
        final country = place.country ?? '';

        if(subLocality.isNotEmpty){
          final locationName = '$subLocality, $locality';
          return locationName;
        }
        if(locality.isNotEmpty && country.isNotEmpty){
          final locationName = '$locality, $country';
          return locationName;
        }

        return null;
      }
    } catch (e) {
      LogService.logError('Error getting location name: $e');
    }
    return null;
  }


  // get locations names from an array of latitude and longitudes
  static Future<List<String?>> getLocationsNamesFromCoordinates(List<double> latitudes, List<double> longitudes) async {
    try {
      List<String?> locationNames = [];
      for (int i = 0; i < latitudes.length; i++) {
        locationNames.add(await getLocationNameFromCoordinates(latitudes[i], longitudes[i]));
      }
      return locationNames;
    } catch (e) {
      LogService.logError('Error getting locations names: $e');
      return [];
    }
  }
}
