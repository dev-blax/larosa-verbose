import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'log_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LogService.logInfo('Handling a background message: ${message.messageId}');
}

class FcmService {
  static const String _baseUrl = LarosaLinks.baseurl;
  static const String _userTokenEndpoint = '/api/v1/fcm/update/user-token';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? _token;

  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  Future<void> initialize() async {
    await Firebase.initializeApp();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _token = await _firebaseMessaging.getToken();
      LogService.logInfo('FCM Token: $_token');

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _token = newToken;
        updateUserToken(newToken);
      });

      if (_token != null) {
        await updateUserToken(_token!);
      }
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    LogService.logInfo('Got a message whilst in the foreground!');
    LogService.logInfo('Message data: ${message.data}');

    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? '',
        payload: json.encode(message.data),
      );
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    LogService.logInfo('Message opened app: ${message.data}');
    // Handle notification tap when app was in background
    // You can navigate to specific screens based on the message data
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'driver_channel',
      'Driver Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> updateUserToken(String token) async {
    try {

      final String authToken = AuthService.getToken();


      final response = await http.post(
        Uri.parse('$_baseUrl$_userTokenEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );

      LogService.logInfo('FCM token response: ${response.body}');

      if (response.statusCode != 200) {
        LogService.logError(
            'Failed to update FCM token: ${response.statusCode}');
        throw Exception('Failed to update FCM token: ${response.statusCode}');
      } else {
        LogService.logInfo(
            'FCM token updated successfully ${response.statusCode}');
      }
    } catch (e) {
      LogService.logError('Error updating user token: $e');
    }
  }
}
