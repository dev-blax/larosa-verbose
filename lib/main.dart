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

// Create a global instance of FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

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

