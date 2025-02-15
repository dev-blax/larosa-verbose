import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/links.dart';

import '../Utils/helpers.dart';

class AuthService {
  static String getToken() {
    var box = Hive.box('userBox');

    if (box.get('token') == null) {
      return '';
    }
    return box.get('token');
  }

  static bool isBusinessAccount() {
    var box = Hive.box('userBox');
    final int accountType = box.get('accountId');
    if (accountType == 2) {
      return true;
    }
    return false;
  }

  static String getRefreshToken() {
    var box = Hive.box('userBox');
    return box.get('refreshToken');
  }

  static bool isReservation() {
    var box = Hive.box('userBox');
    return box.get('reservation');
  }

  static int? getProfileId() {
    var box = Hive.box('userBox');
    return box.get('profileId');
  }

  static Future<bool> booleanRefreshToken() async {
    try {
      await refreshToken();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> refreshToken() async {
    LogService.logInfo('hello toke refresh');
    var headers = {"Content-Type": "application/json"};

    var url = Uri.https(LarosaLinks.nakedBaseUrl, '/api/v1/auth/refresh');
    var response = await http.post(
      url,
      headers: headers,
      body: json.encode(
        {
          'token': AuthService.getRefreshToken(),
        },
      ),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var box = Hive.box('userBox');
      box.put('token', data['token']);
      box.put('refreshToken', data['refreshToken']);
      return;
    } else {
      LogService.logError(response.body);
      throw Exception('Failed to refresh token');
    }
  }
}
