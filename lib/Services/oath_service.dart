import 'package:google_sign_in/google_sign_in.dart';

import '../Utils/links.dart';
import 'log_service.dart';
import 'dio_service.dart';
import 'geo_service.dart';

class OauthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'openid',
    ]
  );
  final DioService _dioService = DioService();
  final GeoService _geoService = GeoService();
  Future<GoogleSignInAccount?> signinWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        LogService.logInfo('signed in as ${googleUser.email}');
        LogService.logInfo('Display Name: ${googleUser.displayName}');
        LogService.logInfo('id ${googleUser.id}');
        final GoogleSignInAuthentication auth = await googleUser.authentication;
        LogService.logInfo('id token ${auth.idToken}');
        LogService.logInfo('access token ${auth.accessToken}');

        // Get current location
        final position = await _geoService.getCurrentLocation();
        final double latitude = position?.latitude ?? 0.0;
        final double longitude = position?.longitude ?? 0.0;

        await _dioService.dio.post('${LarosaLinks.baseurl}${LarosaLinks.socialLogin}', data: {
          'token': auth.idToken,
          'authProvider': 'GOOGLE',
          'latitude': latitude,
          'longitude': longitude,
        });

        return googleUser;
      }
      else {
        LogService.logError('Failed to sign in');
        _googleSignIn.disconnect();
        return null;
      }
    } catch (e) {
      LogService.logError('Error signing in with Google: $e');
      return null;
    }
  }
}