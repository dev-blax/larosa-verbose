import 'dart:async';
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
