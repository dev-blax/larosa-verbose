// import 'dart:convert';

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:hive/hive.dart';
// import 'package:http/http.dart' as http;
// import 'package:larosa_block/Utils/links.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

// import 'log_service.dart';

// // This needs to be a top-level function
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   LogService.logInfo('Handling a background message: ${message.messageId}');
//   // You can handle background messages here
// }

// class FcmService {
//   static const String _baseUrl = LarosaLinks.baseurl;
//   static const String _userTokenEndpoint = '/api/v1/fcm/update/user-token';

//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   String? _token;

//   static final FcmService _instance = FcmService._internal();
//   factory FcmService() => _instance;
//   FcmService._internal();

//   Future<void> initialize() async {
//     // Initialize Firebase
//     await Firebase.initializeApp();

//     // Initialize local notifications
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');


//         final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       onDidReceiveLocalNotification:
//           (int id, String? title, String? body, String? payload) async {
//         // Handle foreground‑notification on iOS < 10 if you wish
//       },
//     );

    
//     InitializationSettings initSettings =
//         InitializationSettings(android: androidSettings, iOS: iosSettings,);
//     await _flutterLocalNotificationsPlugin.initialize(initSettings);

//     // Request permission for notifications
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       _token = await _firebaseMessaging.getToken();
//       LogService.logInfo('FCM Token: $_token');

//       // Listen for token refresh
//       _firebaseMessaging.onTokenRefresh.listen((newToken) {
//         _token = newToken;
//         updateUserToken(newToken);
//       });

//       // Update the token on the server
//       if (_token != null) {
//         await updateUserToken(_token!);
//       }
//     }

//     // Set up message handlers
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
//   }

//   Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     LogService.logInfo('Got a message whilst in the foreground!');
//     LogService.logInfo('Message data: ${message.data}');

//     if (message.notification != null) {
//       await _showLocalNotification(
//         title: message.notification?.title ?? 'New Message',
//         body: message.notification?.body ?? '',
//         payload: json.encode(message.data),
//       );
//     }
//   }

//   Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
//     LogService.logInfo('Message opened app: ${message.data}');
//     // Handle notification tap when app was in background
//     // You can navigate to specific screens based on the message data
//   }

//   Future<void> _showLocalNotification({
//     required String title,
//     required String body,
//     String? payload,
//   }) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'driver_channel',
//       'Driver Notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: true,
//     );

//     const NotificationDetails notificationDetails = NotificationDetails(
//       android: androidDetails,
//     );

//     await _flutterLocalNotificationsPlugin.show(
//       0,
//       title,
//       body,
//       notificationDetails,
//       payload: payload,
//     );
//   }

//   Future<void> updateUserToken(String token) async {
//     try {
//       var box = await Hive.openBox('userBox');
//       final String authToken = box.get('token');

//       final response = await http.post(
//         Uri.parse('$_baseUrl$_userTokenEndpoint'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $authToken',
//         },
//         body: jsonEncode({'fcmToken': token}),
//       );

//       if (response.statusCode != 200) {
//         throw Exception('Failed to update FCM token: ${response.statusCode}');
//       } else {
//         LogService.logInfo('FCM token updated successfully');
//       }
//     } catch (e) {
//       LogService.logError('Error updating user token: $e');
//     }
//   }
// }






import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../Utils/links.dart';
import 'log_service.dart';

/// SINGLETON ──────────────────────────────────────────────────────────────
class FcmService {
  static const String _baseUrl = LarosaLinks.baseurl;
  static const String _userTokenEndpoint = '/api/v1/fcm/update/user-token';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  String? _token;

  /// Stream that pushes every driver offer payload to listeners.
  final StreamController<Map<String, dynamic>> _driverOfferCtrl =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get driverOfferStream =>
      _driverOfferCtrl.stream;

  /// Stream that pushes driver-info payloads (tokens, meta, etc.)
  final StreamController<Map<String, dynamic>> _driverInfoCtrl =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get driverInfoStream =>
      _driverInfoCtrl.stream;

  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  // ────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    await Firebase.initializeApp();

    // Local-notifications init
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _fln.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Ask user permission
    final settings = await _firebaseMessaging.requestPermission(
      alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _token = await _firebaseMessaging.getToken();
      LogService.logInfo('FCM token: $_token');
      _firebaseMessaging.onTokenRefresh.listen(updateUserToken);
      if (_token != null) await updateUserToken(_token!);
    }

    // Message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_bgHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  // ────────────────────────────────────────────────────────────────────────
  /// FOREGROUND
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    LogService.logInfo('Foreground FCM: ${message.data}');
    _dispatchDriverChannel(message);

    // still show system banner
    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? '',
        payload: json.encode(message.data),
      );
    }
  }

  /// BACKGROUND / TERMINATED isolate
  @pragma('vm:entry-point')
  static Future<void> _bgHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    LogService.logInfo('Background FCM: ${message.data}');
    if (message.data['channel'] != 'driver_channel') return;

    final box = await Hive.openBox('fcmCache');
    final map = Map<String, dynamic>.from(message.data);
    final isInfo  = map['event'] == 'DRIVER_INFO' || map.containsKey('driverToken');
    final isOffer = map['event'] == 'DRIVER_OFFER' || map.containsKey('offerId');

    if (isInfo)  await box.put('latest_driver_info', map);
    if (isOffer) await box.put('latest_driver_offer', map);
  }

  /// Tap-on-notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    LogService.logInfo('FCM opened-app: ${message.data}');
    _dispatchDriverChannel(message);
  }

  /// Common driver-channel dispatcher
  void _dispatchDriverChannel(RemoteMessage message) {
    if (message.data['channel'] != 'driver_channel') return;

    final data = message.data;
    final isInfo  = data['event'] == 'DRIVER_INFO' || data.containsKey('driverToken');
    final isOffer = data['event'] == 'DRIVER_OFFER' || data.containsKey('offerId');

    if (isInfo)  _driverInfoCtrl.add(data);
    if (isOffer) _driverOfferCtrl.add(data);
  }

  // ────────────────────────────────────────────────────────────────────────
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const android = AndroidNotificationDetails(
      'driver_channel', 'Driver Notifications',
      importance: Importance.max, priority: Priority.high, showWhen: true);
    await _fln.show(
      0,
      title,
      body,
      const NotificationDetails(android: android),
      payload: payload,
    );
  }

  Future<void> updateUserToken(String token) async {
    try {
      final authToken = (await Hive.openBox('userBox')).get('token');
      final res = await http.post(
        Uri.parse('$_baseUrl$_userTokenEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': token}),
      );
      if (res.statusCode == 200) {
        LogService.logInfo('FCM token updated on server');
      } else {
        throw 'Server responded ${res.statusCode}';
      }
    } catch (e) {
      LogService.logError('Failed updating FCM token: $e');
    }
  }
}

