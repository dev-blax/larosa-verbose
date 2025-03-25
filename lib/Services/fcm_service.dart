import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Utils/links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'log_service.dart';

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  LogService.logInfo('Handling a background message: ${message.messageId}');
  // You can handle background messages here
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
    // Initialize Firebase
    await Firebase.initializeApp();

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Request permission for notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _token = await _firebaseMessaging.getToken();
      LogService.logInfo('FCM Token: $_token');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _token = newToken;
        updateUserToken(newToken);
      });

      // Update the token on the server
      if (_token != null) {
        await updateUserToken(_token!);
      }
    }

    // Set up message handlers
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
      var box = await Hive.openBox('userBox');
      final String authToken = box.get('token');

      final response = await http.post(
        Uri.parse('$_baseUrl$_userTokenEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update FCM token: ${response.statusCode}');
      } else {
        LogService.logInfo('FCM token updated successfully');
      }
    } catch (e) {
      LogService.logError('Error updating user token: $e');
    }
  }
}
