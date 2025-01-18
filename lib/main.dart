import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larosa_block/Services/hive_service.dart';
import 'package:larosa_block/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:stomp_dart_client/stomp_dart_client.dart';

// import 'Services/auth_service.dart';
// import 'Services/log_service.dart';
// import 'Utils/helpers.dart';
// import 'Utils/links.dart';

// Create a global instance of FlutterLocalNotificationsPlugin
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    // FlutterLocalNotificationsPlugin();

// Global instance for StompClient
// late StompClient stompClient;

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
  // await _initializeNotifications();

  // Run the main app
  runApp(const App());
}

// Future<void> _initializeNotifications() async {
//   const AndroidInitializationSettings androidSettings =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   const InitializationSettings initializationSettings =
//       InitializationSettings(android: androidSettings);

//   await flutterLocalNotificationsPlugin.initialize(
//     initializationSettings,
//     onDidReceiveNotificationResponse: (NotificationResponse response) async {
//       // Handle notification tap
//       if (response.payload != null) {
//         debugPrint('Notification payload: ${response.payload}');
//         // Add logic here for navigation or other actions based on the payload
//       }
//     },
//   );
// }


// import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Hello World App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Hello World App'),
//       ),
//       body: Center(
//         child: Text(
//           'Hello World',
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }
// }


// Initialize WebSocket connection
// Future<void> _socketConnection2() async {
//   stompClient = StompClient(
//     config: StompConfig.sockJS(
//       url: LarosaLinks.socketUrl,
//       onConnect: onConnect,
//       onWebSocketError: (dynamic error) =>
//           LogService.logError('WebSocket error: $error'),
//       onStompError: (StompFrame frame) =>
//           LogService.logWarning('Stomp error: ${frame.body}'),
//       onDisconnect: (StompFrame frame) =>
//           LogService.logFatal('Disconnected from WebSocket'),
//     ),
//   );
//   stompClient.activate();
// }

// Callback for handling successful connection
// void onConnect(StompFrame frame) {
//   connectedToSocket = true;
//   LogService.logInfo('Connected to WebSocket server: $frame');

//   final String subscriptionDestination = '/topic/customer/${AuthService.getProfileId()}';

//   // Log the subscription destination
//   LogService.logInfo('Subscribing to destination: $subscriptionDestination');

//   stompClient.subscribe(
//     destination: subscriptionDestination,
//     callback: (StompFrame message) {
//       // Log the received message
//       LogService.logInfo(
//         'Received message from $subscriptionDestination: ${message.body}',
//       );

//       // Show the message in a toast
//       HelperFunctions.showToast(
//         message.body.toString(),
//         true,
//       );
//     },
//   );
// }


// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:larosa_block/Services/hive_service.dart';
// import 'package:larosa_block/app.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:stomp_dart_client/stomp_dart_client.dart';
// import 'package:workmanager/workmanager.dart';

// import 'Services/auth_service.dart';
// import 'Services/log_service.dart';
// import 'Utils/helpers.dart';
// import 'Utils/links.dart';

// // Global instances
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();
// late StompClient stompClient;

// bool connectedToSocket = false;

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   LogService.logInfo("Starting the app initialization...");

//   // Lock orientation to portrait mode
//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);
//   LogService.logInfo("Orientation locked to portrait mode.");

//   // Initialize Hive for local storage
//   HiveService hiveService = HiveService();
//   await hiveService.init();
//   await hiveService.openBox('userBox');
//   await hiveService.openBox('onboardingBox');
//   await hiveService.openBox('profileBox');
//   LogService.logInfo("Hive storage initialized and boxes opened.");

//   // Load environment variables
//   await dotenv.load(fileName: ".env");
//   LogService.logInfo("Environment variables loaded.");

//   // Initialize notifications
//   await HelperFunctions.initializeNotifications();
//   LogService.logInfo("Notifications initialized.");

//   // Initialize WorkManager
//   Workmanager().initialize(_callbackDispatcher, isInDebugMode: true);
//   LogService.logInfo("WorkManager initialized.");

//   // Register periodic background task
//   Workmanager().registerPeriodicTask(
//     "backgroundWebSocketTask",
//     "backgroundWebSocketTask",
//     frequency: const Duration(minutes: 15),
//   );
//   LogService.logInfo("Periodic background task registered.");

//   // Initialize WebSocket
//   await _socketConnection2();
//   LogService.logInfo("WebSocket connection initialization triggered.");

//   // Run the app
//   LogService.logInfo("Starting the app...");
//   runApp(const App());
// }

// void _callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     LogService.logInfo("Executing background task: $task");
//     if (task == "backgroundWebSocketTask") {
//       try {
//         // Attempt to reconnect WebSocket in the background
//         await _reconnectWebSocket();
//         LogService.logInfo("Background WebSocket connection maintained.");
//         return Future.value(true);
//       } catch (e) {
//         LogService.logError("Error in background WebSocket task: $e");
//         return Future.value(false);
//       }
//     }
//     return Future.value(false);
//   });
// }

// Future<void> _socketConnection2() async {
//   LogService.logInfo("Initializing WebSocket connection...");
//   try {
//     stompClient = StompClient(
//       config: StompConfig.sockJS(
//         url: LarosaLinks.socketUrl,
//         onConnect: _onConnect,
//         onWebSocketError: (error) {
//           LogService.logError("WebSocket error occurred: $error");
//         },
//         onStompError: (frame) {
//           LogService.logWarning("Stomp protocol error: ${frame.body}");
//         },
//         onDisconnect: (_) {
//           LogService.logFatal("WebSocket disconnected.");
//           connectedToSocket = false; // Update connection status
//         },
//       ),
//     );
//     stompClient.activate();
//     LogService.logInfo("WebSocket client activated.");
//   } catch (e) {
//     LogService.logError("Error during WebSocket initialization: $e");
//   }
// }

// void _onConnect(StompFrame frame) {
//   LogService.logInfo("WebSocket connected successfully.");
//   connectedToSocket = true;

//   final String subscriptionDestination = '/topic/customer/${AuthService.getProfileId()}';
//   LogService.logInfo("Subscribing to topic: $subscriptionDestination");

//   try {
//     stompClient.subscribe(
//       destination: subscriptionDestination,
//       callback: (message) {
//         LogService.logInfo("Message received from $subscriptionDestination: ${message.body}");
//         HelperFunctions.showNotificationForChannelMessage(
//           title: 'New Message',
//           body: message.body ?? 'No content',
//           channelId: subscriptionDestination,
//         );
//       },
//     );
//     LogService.logInfo("Subscription to $subscriptionDestination completed.");
//   } catch (e) {
//     LogService.logError("Error during subscription: $e");
//   }
// }

// Future<void> _reconnectWebSocket() async {
//   if (!connectedToSocket) {
//     LogService.logInfo("Attempting to reconnect WebSocket...");
//     await _socketConnection2();
//   } else {
//     LogService.logInfo("WebSocket is already connected.");
//   }
// }
