// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:larosa_block/Services/hive_service.dart';
// import 'package:larosa_block/app.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   HiveService hiveService = HiveService();
//   await hiveService.init();
//   await hiveService.openBox('userBox');
//   await hiveService.openBox('onboardingBox');
//   await hiveService.openBox('profileBox');
//   await dotenv.load(fileName: ".env");
//   runApp(const App());
// }


// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:larosa_block/Services/hive_service.dart';
// import 'package:larosa_block/app.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// // Create a global instance of FlutterLocalNotificationsPlugin
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Lock orientation to portrait mode
//   SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   // Initialize Hive for local storage
//   HiveService hiveService = HiveService();
//   await hiveService.init();
//   await hiveService.openBox('userBox');
//   await hiveService.openBox('onboardingBox');
//   await hiveService.openBox('profileBox');

//   // Load environment variables
//   await dotenv.load(fileName: ".env");

//   // Initialize local notifications
//   const AndroidInitializationSettings androidSettings =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   const InitializationSettings initializationSettings =
//       InitializationSettings(android: androidSettings);

//   await flutterLocalNotificationsPlugin.initialize(initializationSettings);

//   // Run the main app
//   runApp(const App());
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larosa_block/Services/hive_service.dart';
import 'package:larosa_block/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'Services/auth_service.dart';
import 'Services/log_service.dart';
import 'Utils/helpers.dart';
import 'Utils/links.dart';

// Create a global instance of FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global instance for StompClient
late StompClient stompClient;

bool connectedToSocket = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive for local storage
  HiveService hiveService = HiveService();
  await hiveService.init();
  await hiveService.openBox('userBox');
  await hiveService.openBox('onboardingBox');
  await hiveService.openBox('profileBox');

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize local notifications
  await _initializeNotifications();

  // Initialize WebSocket connection
  await _socketConnection2();

  // Run the main app
  runApp(const App());
}

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // Handle notification tap
      if (response.payload != null) {
        debugPrint('Notification payload: ${response.payload}');
        // Add logic here for navigation or other actions based on the payload
      }
    },
  );
}

// Initialize WebSocket connection
Future<void> _socketConnection2() async {
  stompClient = StompClient(
    config: StompConfig.sockJS(
      url: LarosaLinks.socketUrl,
      onConnect: onConnect,
      onWebSocketError: (dynamic error) =>
          LogService.logError('WebSocket error: $error'),
      onStompError: (StompFrame frame) =>
          LogService.logWarning('Stomp error: ${frame.body}'),
      onDisconnect: (StompFrame frame) =>
          LogService.logFatal('Disconnected from WebSocket'),
    ),
  );
  stompClient.activate();
}

// Callback for handling successful connection
void onConnect(StompFrame frame) {
  connectedToSocket = true;
  LogService.logInfo('Connected to WebSocket server: $frame');

  final String subscriptionDestination = '/topic/customer/${AuthService.getProfileId()}';

  // Log the subscription destination
  LogService.logInfo('Subscribing to destination: $subscriptionDestination');

  stompClient.subscribe(
    destination: subscriptionDestination,
    callback: (StompFrame message) {
      // Log the received message
      LogService.logInfo(
        'Received message from $subscriptionDestination: ${message.body}',
      );

      // Show the message in a toast
      HelperFunctions.showToast(
        message.body.toString(),
        true,
      );
    },
  );
}
