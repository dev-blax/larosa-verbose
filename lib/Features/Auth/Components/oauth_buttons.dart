import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Services/google_auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Services/navigation_service.dart';
import 'package:larosa_block/Utils/svg_paths.dart';

class OauthButtons extends StatefulWidget {
  const OauthButtons({
    super.key,
  });

  @override
  State<OauthButtons> createState() => _OauthButtonsState();
}

class _OauthButtonsState extends State<OauthButtons> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onTap: () async {
            UserCredential? credential =
                await _googleAuthService.signInWithGoogle();
            if (credential != null) {
              LogService.logInfo(
                  'Google Sign-In Successful as  ${credential.user!.displayName}');
              context.goNamed('home');
            } else {
              LogService.logError('Google Sign-In Failed');
            }
          },
          child: Animate(
            effects: const [
              FadeEffect(
                  begin: BlurEffect.minBlur,
                  end: BlurEffect.defaultBlur,
                  duration: Duration(seconds: 5)),
              ScaleEffect(
                  begin: ScaleEffect.defaultValue,
                  end: ScaleEffect.neutralValue,
                  duration: Duration(seconds: 1),
                  delay: Duration(seconds: 0))
            ],
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: SvgPicture.asset(
                  SvgIconsPaths.googleIcon,
                  height: 40,
                ),
              ),
            ),
          ),
        ),
        Animate(
          effects: const [
            FadeEffect(
                begin: BlurEffect.minBlur,
                end: BlurEffect.defaultBlur,
                duration: Duration(seconds: 5)),
            ScaleEffect(
              begin: ScaleEffect.defaultValue,
              end: ScaleEffect.neutralValue,
              duration: Duration(seconds: 1),
              delay: Duration(milliseconds: 500),
            )
          ],
          child: InkWell(
            onTap: () {
              NavigationService.showErrorSnackBar(
                  'Not Available! We are working on this!');
            },
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: SvgPicture.asset(SvgIconsPaths.tikTokIcon,
                    height: 40,
                    colorFilter:
                        const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
              ),
            ),
          ),
        ),
        Animate(
          effects: const [
            FadeEffect(
                begin: BlurEffect.minBlur,
                end: BlurEffect.defaultBlur,
                duration: Duration(seconds: 5)),
            ScaleEffect(
                begin: ScaleEffect.defaultValue,
                end: ScaleEffect.neutralValue,
                duration: Duration(seconds: 1),
                delay: Duration(milliseconds: 500))
          ],
          child: InkWell(
            onTap: () {
              NavigationService.showErrorSnackBar(
                  'Not Available! We are working on this!');
            },
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: SvgPicture.asset(SvgIconsPaths.appleIcon,
                    height: 40,
                    colorFilter:
                        const ColorFilter.mode(Colors.grey, BlendMode.srcIn)),
              ),
            ),
          ),
        ),
        Animate(
          effects: const [
            FadeEffect(
                begin: BlurEffect.minBlur,
                end: BlurEffect.defaultBlur,
                duration: Duration(seconds: 5)),
            ScaleEffect(
                begin: ScaleEffect.defaultValue,
                end: ScaleEffect.neutralValue,
                duration: Duration(seconds: 1),
                delay: Duration(milliseconds: 500))
          ],
          child: InkWell(
            onTap: () async {
              UserCredential? credential =
                  await _googleAuthService.signInWithTwitter();

              if (credential != null) {
                LogService.logInfo(
                    'Twitter Sign-In Successful as  ${credential.user!.displayName}');
                context.goNamed('home');
              } else {
                LogService.logError('Twitter Sign-In Failed');
              }
            },
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: SvgPicture.asset(
                  SvgIconsPaths.twitterIcon,
                  height: 40,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
