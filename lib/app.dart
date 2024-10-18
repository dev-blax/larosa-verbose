// import 'package:flutter/material.dart';
// import 'package:larosa_block/Features/Feeds/Controllers/content_controller.dart';
// import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';
// import 'package:larosa_block/Features/Onboarding/onboarding_controller.dart';
// import 'package:larosa_block/Utils/theme.dart';
// import 'package:larosa_block/router.dart';
// import 'package:provider/provider.dart';
// import 'package:toastification/toastification.dart';

// class App extends StatefulWidget {
//   const App({super.key});

//   @override
//   State<App> createState() => _AppState();
// }

// class _AppState extends State<App> {
//   final routerService = RouterService();

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => HomeFeedsController()),
//         ChangeNotifierProvider(create: (_) => ContentController()),
//         ChangeNotifierProvider(create: (_) => OnboardingProvider()),
//       ],
//       child: ToastificationWrapper(
//         child: MaterialApp.router(
//           routerConfig: routerService.router,
//           themeMode: ThemeMode.system,
//           theme: LarosaAppTheme.lightTheme,
//           darkTheme: LarosaAppTheme.darkTheme,
//           debugShowCheckedModeBanner: false,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  void initState() {
    super.initState();
    _setSystemUIOverlayStyle();
  }

  void _setSystemUIOverlayStyle() {
    // Set light and dark mode overlays based on the theme
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Change based on your theme
      statusBarBrightness: Brightness.dark, // Change based on your theme
      systemNavigationBarColor: Colors.black, // Set according to your dark theme
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

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
          builder: (context, child) {
            // Update system overlays dynamically based on the theme
            Brightness brightness = Theme.of(context).brightness;
            SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: 
                brightness == Brightness.dark ? Brightness.light : Brightness.dark,
              statusBarBrightness: 
                brightness == Brightness.dark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: 
                brightness == Brightness.dark ? Colors.black : Colors.white,
              systemNavigationBarIconBrightness: 
                brightness == Brightness.dark ? Brightness.light : Brightness.dark,
            ));
            return child!;
          },
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
