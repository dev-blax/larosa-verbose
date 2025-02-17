import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:larosa_block/Services/google_auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';

class OauthButtons extends StatelessWidget {
  const OauthButtons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onTap: () async {
            final googleAuthService = GoogleAuthService();
            final user = await googleAuthService.signIn();
            LogService.logInfo('user ${user!.displayName}');
          },
          child: Animate(
            effects: const [
              FadeEffect(
                begin: BlurEffect.minBlur,
                end: BlurEffect.defaultBlur,
                duration: Duration(seconds: 5)
              ),

              ScaleEffect(
                begin: ScaleEffect.defaultValue,
                end: ScaleEffect.neutralValue,
                duration: Duration(seconds: 1),
                delay: Duration(seconds: 0)
              )
            ],
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Image.asset('assets/icons/icons8-google-48.png'),
              ),
            ),
          ),
        ),

        Animate(
          effects: const [
            FadeEffect(
              begin: BlurEffect.minBlur,
              end: BlurEffect.defaultBlur,
              duration: Duration(seconds: 5)
            ),

            ScaleEffect(
              begin: ScaleEffect.defaultValue,
              end: ScaleEffect.neutralValue,
              duration: Duration(seconds: 1),
              delay: Duration(milliseconds: 500)
            )
          ],
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset('assets/icons/icons8-tiktok-48.png'),
            ),
          ),
        ),
        Animate(
          effects: const [
            FadeEffect(
              begin: BlurEffect.minBlur,
              end: BlurEffect.defaultBlur,
              duration: Duration(seconds: 5)
            ),

            ScaleEffect(
              begin: ScaleEffect.defaultValue,
              end: ScaleEffect.neutralValue,
              duration: Duration(seconds: 1),
              delay: Duration(milliseconds: 500)
            )
          ],
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset('assets/icons/icons8-facebook-48.png'),
            ),
          ),
        ),
        Animate(
          effects: const [
            FadeEffect(
              begin: BlurEffect.minBlur,
              end: BlurEffect.defaultBlur,
              duration: Duration(seconds: 5)
            ),

            ScaleEffect(
              begin: ScaleEffect.defaultValue,
              end: ScaleEffect.neutralValue,
              duration: Duration(seconds: 1),
              delay: Duration(milliseconds: 500)
            )
          ],
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Image.asset('assets/icons/icons8-instagram-48.png'),
            ),
          ),
        ),
        
      ],
    );
  }
}
