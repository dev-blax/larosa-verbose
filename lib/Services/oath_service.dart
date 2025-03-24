import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

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


  final String clientKey = 'awejkrjc91whklfp';
  final String clientSecret = "qLSTA3tTeAX6IjkUx9HkEpt8gEarZIma";
  final String redirectUri = "https://serialsoftpro.com/larosa-redirect";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> signinWithTikTok() async {
    try {
      // Step 1: Get the authorization code
      final authUrl = Uri.https('www.tiktok.com', '/v2/auth/authorize', {
        'client_key': clientKey,
        'redirect_uri': redirectUri,
        'scope': 'user.info.basic',
        'response_type': 'code',
        'state': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'larosa',
      );

      final code = Uri.parse(result).queryParameters['code'];
      if (code == null) throw Exception('No authorization code received');

      // Step 2: Exchange code for access token
      final tokenResponse = await _dioService.dio.post(
        'https://open-api.tiktok.com/oauth/access_token/',
        data: {
          'client_key': clientKey,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception('Failed to get access token');
      }

      final tokens = tokenResponse.data;
      
      // Store tokens securely
      await _storage.write(key: 'tiktok_access_token', value: tokens['access_token']);
      await _storage.write(key: 'tiktok_open_id', value: tokens['open_id']);

      // Step 3: Get user info
      final userResponse = await _dioService.dio.get(
        'https://open-api.tiktok.com/user/info/',
        queryParameters: {
          'access_token': tokens['access_token'],
          'open_id': tokens['open_id'],
          'fields': ['open_id', 'union_id', 'avatar_url', 'display_name'],
        },
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Failed to get user info');
      }

      final userData = userResponse.data['data'];
      
      // Get current location for your backend
      final position = await _geoService.getCurrentLocation();
      final double latitude = position?.latitude ?? 0.0;
      final double longitude = position?.longitude ?? 0.0;

      // Send to your backend
      await _dioService.dio.post('${LarosaLinks.baseurl}${LarosaLinks.socialLogin}', data: {
        'token': tokens['access_token'],
        'authProvider': 'TIKTOK',
        'latitude': latitude,
        'longitude': longitude,
        'userData': userData,
      });

      return userData;
    } catch (e) {
      LogService.logError('Error signing in with TikTok: $e');
      return null;
    }
  }

  // Sign in with apple
  // Future<Map<String, dynamic>?> signinWithApple() async {
  //   try {
  //     // Check if Apple Sign In is available on this device
  //     final isAvailable = await SignInWithApple.isAvailable();
  //     if (!isAvailable) {
  //       throw Exception('Apple Sign In is not available on this device');
  //     }

  //     // Request credentials
  //     final credential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //     );

  //     // Create user data map
  //     final Map<String, dynamic> userData = {
  //       'id': credential.userIdentifier,
  //       'email': credential.email,
  //       'name': '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim(),
  //     };

  //     // Store the auth code securely
  //     await _storage.write(
  //       key: 'apple_auth_code',
  //       value: credential.authorizationCode,
  //     );

  //     // Get current location for your backend
  //     final position = await _geoService.getCurrentLocation();
  //     final double latitude = position?.latitude ?? 0.0;
  //     final double longitude = position?.longitude ?? 0.0;

  //     // Send to your backend
  //     await _dioService.dio.post('${LarosaLinks.baseurl}${LarosaLinks.socialLogin}', data: {
  //       'token': credential.identityToken, // JWT token
  //       'authProvider': 'APPLE',
  //       'latitude': latitude,
  //       'longitude': longitude,
  //       'userData': userData,
  //       'authCode': credential.authorizationCode,
  //     });

  //     return userData;
  //   } catch (e) {
  //     LogService.logError('Error signing in with Apple: $e');
  //     return null;
  //   }
  // }



}