import 'package:flutter/material.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Services/log_service.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterSplashScreen.fadeIn(
      useImmersiveMode: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      onInit: () {
        debugPrint("On Init");
      },
      onEnd: () {
        debugPrint("On End");
      },
      childWidget: SizedBox(
        height: 200,
        width: 200,
        child: Column(
          children: [
            Image.asset(
              "assets/images/larosa-gradient.png",
              height: 120,
            ),
            const Gap(10),
            Text(
              'Explore Larosa',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Powered by Serial Soft Pro',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      onAnimationEnd: () => LogService.logDebug('Animation finished'),
      asyncNavigationCallback: () async {
        await Future.delayed(const Duration(seconds: 3));
        if (context.mounted) context.go('/');
      },
    );
  }
}
