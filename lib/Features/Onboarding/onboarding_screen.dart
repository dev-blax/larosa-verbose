import 'package:flutter/material.dart';
import 'package:larosa_block/Features/Onboarding/Components/first_onboarding.dart';
import 'package:larosa_block/Features/Onboarding/Components/second_onboarding.dart';
import 'package:larosa_block/Features/Onboarding/Components/third_onboarding.dart';
import 'package:larosa_block/Features/Onboarding/onboarding_controller.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    // Access OnboardingProvider instance
    final onboardingProvider =
        Provider.of<OnboardingProvider>(context, listen: false);

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: onboardingProvider.pageController,
            onPageChanged: onboardingProvider.updatePageIndicator,
            children: const [
              FirstOnboarding(),
              SecondOnboarding(),
              ThirdOnboarding(),
            ],
          ),
          // You can also uncomment and add these components if needed
          // const OnboardingSkip(),
          // const OnboardingDotNavigation()
        ],
      ),
    );
  }
}
