import 'package:google_sign_in/google_sign_in.dart';

import 'log_service.dart';

class OauthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'openid',
    ]
  );
  Future<GoogleSignInAccount?> signinWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        LogService.logInfo('signed in');
        return googleUser;
      }
      else {
        LogService.logError('Failed to sign in');
        return null;
      }
    } catch (e) {
      LogService.logError('Error signing in with Google: $e');
      return null;
    }
  }
}