import 'package:geolocator/geolocator.dart';
import 'package:larosa_block/Services/log_service.dart';

class GeoService {
  static final GeoService _instance = GeoService._internal();
  
  factory GeoService() {
    return _instance;
  }

  GeoService._internal();

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        LogService.logError('Location services are disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          LogService.logError('Location permissions are denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        LogService.logError('Location permissions are permanently denied');
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      LogService.logError('Error getting location: $e');
      return null;
    }
  }
}
