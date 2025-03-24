import 'package:google_sign_in/google_sign_in.dart';

import 'log_service.dart';

class OauthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    //clientId: '493360937456-177eg997h9qg8e4oq29qj72f0bn5n5of.apps.googleusercontent.com',
    clientId: '493360937456-v5qiq5n2lftu805a69ll1ij8ifnvifp4.apps.googleusercontent.com',
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
        LogService.logInfo('signed in as ${googleUser.email}');
        LogService.logInfo('Display Name: ${googleUser.displayName}');
        LogService.logInfo('id ${googleUser.id}');
        final GoogleSignInAuthentication auth = await googleUser.authentication;
        LogService.logInfo('id token ${auth.idToken}');
        LogService.logInfo('access token ${auth.accessToken}');
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