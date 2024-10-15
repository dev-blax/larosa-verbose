import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Features/Onboarding/onboarding_controller.dart';
import 'package:provider/provider.dart';

class OnboardingNextButton extends StatelessWidget {
  const OnboardingNextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 10,
      child: Animate(
        effects: const [
          SlideEffect(
            begin: Offset(0, 4),
            end: Offset(0, 0),
            curve: Curves.easeOutQuad,
            duration: Duration(seconds: 1),
            delay: Duration(seconds: 1),
          ),
        ],
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            gradient: const LinearGradient(
              colors: [Color(0xff34a4f9), Color(0xff0a1282)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: FilledButton(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            onPressed: () {
              Provider.of<OnboardingProvider>(context, listen: false).nextPage(context);
            },
            child: const Row(
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Gap(5),
                Icon(
                  Iconsax.arrow_right_3,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
