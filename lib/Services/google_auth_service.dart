import 'package:google_sign_in/google_sign_in.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/api_service.dart';

import '../Utils/links.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {

        LogService.logInfo('googleUser $googleUser');

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        LogService.logInfo('accessToken $accessToken');
        LogService.logInfo('idToken $idToken');

        try {
          final response = await ApiService.dio.post(
            '${LarosaLinks.baseurl}/api/v1/auth/social',
            data: {'token': accessToken},
          );

          if (response.statusCode == 200) {
            return googleUser;
          }
        } catch (apiError) {
          LogService.logError('Error sending token to backend: $apiError');
          return null;
        }
      }
      return null;
    } catch (e) {
      LogService.logError('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
