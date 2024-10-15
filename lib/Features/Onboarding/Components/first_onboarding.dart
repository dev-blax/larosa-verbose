import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:larosa_block/Features/Onboarding/Components/next_button.dart';

class FirstOnboarding extends StatefulWidget {
  const FirstOnboarding({super.key});

  @override
  State<FirstOnboarding> createState() => _FirstOnboardingState();
}

class _FirstOnboardingState extends State<FirstOnboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
              image:
                  AssetImage('assets/images/lady-in-red-eating-ice-cream.jpg'),
              fit: BoxFit.cover,
            )),
          ),

          // glass wall
          Positioned(
              bottom: 0,
              left: 0,
              top: 0,
              width: MediaQuery.of(context).size.width * 0.5,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              )),

          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(left: 40, right: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Animate(
                    effects: const [
                      SlideEffect(
                        begin: Offset(0, 1),
                        end: Offset(0, 0),
                        curve: Curves.easeOutQuad,
                        duration: Duration(seconds: 1),
                        //delay: Duration(seconds: 1),
                      )
                    ],
                    child: const Text(
                      'Discover Your World',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Animate(
                    effects: const [
                      SlideEffect(
                        begin: Offset(0, 1),
                        end: Offset(0, 0),
                        curve: Curves.easeInOutQuad,
                        duration: Duration(seconds: 1),
                        delay: Duration(milliseconds: 200),
                      )
                    ],
                    child: const Text(
                      'Unleash endless possibilities with our social hub and seamless food delivery at your fingertips',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18),
                    ),
                  )
                ],
              ),
            ),
          ),

          const OnboardingNextButton()
        ],
      ),
    );
  }
}
