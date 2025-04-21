import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:hive/hive.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../Utils/links.dart';
import 'log_service.dart';
import 'dio_service.dart';
import 'geo_service.dart';

class OauthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
    'email',
    'profile',
    'openid',
  ]);
  final DioService _dioService = DioService();
  final GeoService _geoService = GeoService();

  Future<GoogleSignInAccount?> signinWithGoogle({BuildContext? context}) async {
    try {
      LogService.logInfo('Starting Google Sign In process');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        LogService.logInfo('Google Sign In successful for user: ${googleUser.email}');
        final GoogleSignInAuthentication auth = await googleUser.authentication;
        String token = auth.idToken!;

        while (token.isNotEmpty) {
          int initLength = (token.length >= 500 ? 500 : token.length);
          LogService.logInfo('id token ${token.substring(0, initLength)}');
          int endLength = token.length;
          token = token.substring(initLength, endLength);
        }

        LogService.logInfo('Starting location fetch');
        try {
          final position = await _geoService.getCurrentLocation(context: context);
          LogService.logInfo('Location fetch result: ${position?.latitude}, ${position?.longitude}');
          final double latitude = position?.latitude ?? 0.0;
          final double longitude = position?.longitude ?? 0.0;

          LogService.logInfo('Making API request to ${LarosaLinks.baseurl}${LarosaLinks.socialLogin}');
          var response = await _dioService.dio.post(
            '${LarosaLinks.baseurl}${LarosaLinks.socialLogin}',
            data: {
              'token': auth.idToken,
              'authProvider': 'GOOGLE',
              'latitude': latitude,
              'longitude': longitude,
            },
          );

          LogService.logInfo('API response received: ${response.data}');

          final data = response.data;

          var box = await Hive.openBox('userBox');
          await box.clear();
          box.put('profileId', data['profileId']);
          box.put('accountId', data['accountType']['id']);
          box.put('accountName', data['accountType']['name']);
          box.put('reservation', data['reservation']);

          box.put('token', data['jwtAuthenticationResponse']['token']);
          LogService.logInfo(
              'got toke ${data['jwtAuthenticationResponse']['token']}');
          box.put(
            'refreshToken',
            data['jwtAuthenticationResponse']['refreshToken'],
          );

          return googleUser;
        } catch (locationError) {
          LogService.logError('Location error: $locationError');
          // Try to proceed without location
          var response = await _dioService.dio.post(
            '${LarosaLinks.baseurl}${LarosaLinks.socialLogin}',
            data: {
              'token': auth.idToken,
              'authProvider': 'GOOGLE',
              'latitude': 0.0,
              'longitude': 0.0,
            },
          );
          LogService.logInfo('API response without location: ${response.data}');
          // Continue with the rest of the data processing
          final data = response.data;

          var box = await Hive.openBox('userBox');
          await box.clear();
          box.put('profileId', data['profileId']);
          box.put('accountId', data['accountType']['id']);
          box.put('accountName', data['accountType']['name']);
          box.put('reservation', data['reservation']);

          box.put('token', data['jwtAuthenticationResponse']['token']);
          LogService.logInfo(
              'got toke ${data['jwtAuthenticationResponse']['token']}');
          box.put(
            'refreshToken',
            data['jwtAuthenticationResponse']['refreshToken'],
          );

          return googleUser;
        }
      } else {
        LogService.logError('User cancelled Google Sign In');
        _googleSignIn.disconnect();
        return null;
      }
    } catch (e, stackTrace) {
      LogService.logError('Error signing in with Google: $e\nStack trace: $stackTrace');
      _googleSignIn.signOut();
      LogService.logInfo('Signed out from Google');
      return null;
    }
  }

  // google logout
  Future<void> googleLogout() async {
    _googleSignIn.disconnect();
  }

  final String clientKey = 'sbaw9h94ykl64jqmv3';
  final String clientSecret = "Re6Ea8Lk3Ey6ShiB7geMZCrcTRv9QMEv";
  final String redirectUri = "https://serialsoftpro.com/larosa-redirect";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> signinWithTikTok() async {
    try {
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

      await _storage.write(
          key: 'tiktok_access_token', value: tokens['access_token']);
      await _storage.write(key: 'tiktok_open_id', value: tokens['open_id']);

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
      await _dioService.dio
          .post('${LarosaLinks.baseurl}${LarosaLinks.socialLogin}', data: {
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

  Future<Map<String, dynamic>?> signinWithApple() async {
    try {
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('Apple Sign In is not available on this device');
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.explore.larosa',
          redirectUri: Uri.https('serialsoftpro.com', '/larosa-redirect'),
        ),
      );

      final Map<String, dynamic> userData = {
        'id': credential.userIdentifier,
        'email': credential.email,
        'name': '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
            .trim(),
      };

      await _storage.write(
        key: 'apple_auth_code',
        value: credential.authorizationCode,
      );

      final position = await _geoService.getCurrentLocation();
      final double latitude = position?.latitude ?? 0.0;
      final double longitude = position?.longitude ?? 0.0;

      await _dioService.dio.post(
        '${LarosaLinks.baseurl}${LarosaLinks.socialLogin}',
        data: {
          'token': credential.identityToken,
          'authProvider': 'APPLE',
          'latitude': latitude,
          'longitude': longitude,
          'userData': userData,
          'authCode': credential.authorizationCode,
        },
      );

      return userData;
    } catch (e) {
      LogService.logError('Error signing in with Apple: $e');
      return null;
    }
  }

}
