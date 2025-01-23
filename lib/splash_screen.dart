// import 'package:flutter/material.dart';
// import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
// import 'package:gap/gap.dart';
// import 'package:go_router/go_router.dart';
// import 'package:larosa_block/Services/log_service.dart';

// class SplashScreen extends StatelessWidget {
//   const SplashScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return FlutterSplashScreen.fadeIn(
//       useImmersiveMode: true,
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       onInit: () {
//         debugPrint("On Init");
//       },
//       onEnd: () {
//         debugPrint("On End");
//       },
//       childWidget: SizedBox(
//         height: MediaQuery.of(context).size.height - 10,
//         width: 200,
//         child: Column(
//           children: [
//             Image.asset(
//               "assets/images/larosa-gradient.png",
//               height: 120,
//             ),
//             const Gap(10),
//             Text(
//               'Explore Larosa',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//             Text(
//               'Powered by Serial Soft Pro',
//               style: Theme.of(context).textTheme.labelSmall,
//             ),
//           ],
//         ),
//       ),
//       onAnimationEnd: () => LogService.logDebug('Animation finished'),
//       asyncNavigationCallback: () async {
//         await Future.delayed(const Duration(seconds: 3));
//         if (context.mounted) context.go('/');
//       },
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Utils/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  Animate(
                    effects: [
                      FadeEffect(
                        begin: 0.0,
                        end: 1.0,
                        curve: Curves.easeIn,
                        duration: Duration(seconds: 1),

                      )
                    ],
                    child: Image.asset(
                      'assets/images/larosa-gradient.png',
                      height: 120,
                      width: 120,
                    ),
                  ),
                  
                  Gap(10),
                  Text(
                    'Explore Larosa',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: LarosaColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sponsor Name
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text(
              'Powered by Serial-Soft-Pro',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
