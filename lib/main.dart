// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:larosa_block/Services/fcm_service.dart';
// import 'package:larosa_block/Services/hive_service.dart';
// import 'package:larosa_block/app.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:firebase_core/firebase_core.dart';

// bool connectedToSocket = false;

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Firebase
//   await Firebase.initializeApp();

//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   // Initialize Hive for local storage
//   HiveService hiveService = HiveService();
//   await hiveService.init();
//   await hiveService.openBox('userBox');
//   await hiveService.openBox('onboardingBox');
//   await hiveService.openBox('profileBox');
//   await FcmService().initialize();

//   await dotenv.load(fileName: ".env");

//   runApp(const App());
// }





import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:larosa_block/Services/hive_service.dart';
import 'package:larosa_block/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:larosa_block/firebase_options.dart';

bool connectedToSocket = false;

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set device orientations.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Check if Firebase has already been initialized to avoid duplicate initialization.
  // if (Firebase.apps.isEmpty) {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  // } else {
  //   // Optionally, you can log that Firebase is already initialized.
  //   debugPrint('Firebase is already initialized');
  // }

  // Initialize Hive for local storage.
  HiveService hiveService = HiveService();
  await hiveService.init();
  await hiveService.openBox('userBox');
  await hiveService.openBox('onboardingBox');
  await hiveService.openBox('profileBox');

  // Load environment variables.
  await dotenv.load(fileName: ".env");

  // Run your app.
  runApp(const App());
}

