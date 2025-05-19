import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapsService {
  static String get apiKey {
    // First try to get from .env file
    final envKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (envKey != null && envKey.isNotEmpty) {
      return envKey;
    }
    
    // Fallback to a development key (you should replace this with your actual key)
    return 'AIzaSyA30rAh34FrfL-71H0wdZpdtNB-MkZ8u3A';
  }
}
