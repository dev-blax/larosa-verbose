import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larosa_block/Services/hive_service.dart';
import 'package:larosa_block/app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);



  HiveService hiveService = HiveService();
  await hiveService.init();
  await hiveService.openBox('userBox');
  await hiveService.openBox('onboardingBox');

  await dotenv.load(fileName: ".env");
  runApp(const App());
}
