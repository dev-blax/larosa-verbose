import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larosa_block/Services/fcm_service.dart';
import 'package:larosa_block/Services/hive_service.dart';
import 'package:larosa_block/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

bool connectedToSocket = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

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
  await FcmService().initialize();

  await dotenv.load(fileName: ".env");

  runApp(const App());
}

