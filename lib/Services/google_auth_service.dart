import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Services/geo_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/links.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DioService _dioService = DioService();
  final GeoService _geoService = GeoService();

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        LogService.logInfo('googleUser $googleUser');

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase first to get the token
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final String? token = await userCredential.user?.getIdToken();
        
        LogService.logInfo('Firebase token $token');
        LogService.logInfo('id token ${googleAuth.idToken}');
        LogService.logInfo('access token ${googleAuth.accessToken}');

        // Get current location
        final position = await _geoService.getCurrentLocation();
        final double latitude = position?.latitude ?? 0.0;
        final double longitude = position?.longitude ?? 0.0;

        await _dioService.dio.post('${LarosaLinks.baseurl}${LarosaLinks.socialLogin}', data: {
          'token': token,
          'authProvider': 'GOOGLE',
          'latitude': latitude,
          'longitude': longitude,
        });

        return userCredential;
      }
      return null;
    } catch (e) {
      LogService.logError('Error signing in with Google: $e');
      return null;
    }
  }

}
