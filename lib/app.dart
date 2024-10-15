import 'package:flutter/material.dart';
import 'package:larosa_block/Features/Feeds/Controllers/content_controller.dart';
import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';
import 'package:larosa_block/Features/Onboarding/onboarding_controller.dart';
import 'package:larosa_block/Utils/theme.dart';
import 'package:larosa_block/router.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final routerService = RouterService();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeFeedsController()),
        ChangeNotifierProvider(create: (_) => ContentController()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
      ],
      child: ToastificationWrapper(
        child: MaterialApp.router(
          routerConfig: routerService.router,
          themeMode: ThemeMode.system,
          theme: LarosaAppTheme.lightTheme,
          darkTheme: LarosaAppTheme.darkTheme,
        ),
      ),
    );
  }
}
