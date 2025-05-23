import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Services/oath_service.dart';
import 'package:larosa_block/Utils/svg_paths.dart';

class OauthButtons extends StatefulWidget {
  const OauthButtons({
    super.key,
  });

  @override
  State<OauthButtons> createState() => _OauthButtonsState();
}

class _OauthButtonsState extends State<OauthButtons> {
  final OauthService _oauthService = OauthService();
  bool isGoogleLoading = false;

  // @override
  // Widget build(BuildContext context) {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceAround,
  //     children: [
  //       GestureDetector(
  //         onTap: () async {
  //           setState(() {
  //             isGoogleLoading = true;
  //           });
  //           try {
  //             final googleUser = await _oauthService.signinWithGoogle(context: context);
  //             if (googleUser != null && mounted) {
  //               context.goNamed('home');
  //             } else {
  //             }
  //           } finally {
  //             setState(() {
  //               isGoogleLoading = false;
  //             });
  //           }
  //         },
  //         child: Animate(
  //           effects: const [
  //             FadeEffect(
  //               begin: BlurEffect.minBlur,
  //               end: BlurEffect.defaultBlur,
  //               duration: Duration(seconds: 5),
  //             ),
  //             ScaleEffect(
  //               begin: ScaleEffect.defaultValue,
  //               end: ScaleEffect.neutralValue,
  //               duration: Duration(seconds: 1),
  //               delay: Duration(seconds: 0),
  //             )
  //           ],
  //           child: Card(
  //             color: Colors.white,
  //             child: Padding(
  //               padding: const EdgeInsets.all(5.0),
  //               child: SvgPicture.asset(
  //                 SvgIconsPaths.googleIcon,
  //                 height: 40,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //       Animate(
  //         effects: const [
  //           FadeEffect(
  //               begin: BlurEffect.minBlur,
  //               end: BlurEffect.defaultBlur,
  //               duration: Duration(seconds: 5)),
  //           ScaleEffect(
  //             begin: ScaleEffect.defaultValue,
  //             end: ScaleEffect.neutralValue,
  //             duration: Duration(seconds: 1),
  //             delay: Duration(milliseconds: 500),
  //           )
  //         ],
  //         child: InkWell(
  //           onTap: () async {
  //             final userData = await _oauthService.signinWithTikTok();
  //             if (userData != null && mounted) {
  //               context.goNamed('home');
  //             } else {
  //               NavigationService.showErrorSnackBar('TikTok Sign-In Failed');
  //             }
  //           },
  //           child: Card(
  //             color: Colors.white,
  //             child: Padding(
  //               padding: const EdgeInsets.all(5.0),
  //               child: SvgPicture.asset(
  //                 SvgIconsPaths.tikTokIcon,
  //                 height: 40,
  //                 //colorFilter: const ColorFilter.mode(Colors.red, BlendMode.srcIn),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //       Animate(
  //         effects: const [
  //           FadeEffect(
  //               begin: BlurEffect.minBlur,
  //               end: BlurEffect.defaultBlur,
  //               duration: Duration(seconds: 5)),
  //           ScaleEffect(
  //               begin: ScaleEffect.defaultValue,
  //               end: ScaleEffect.neutralValue,
  //               duration: Duration(seconds: 1),
  //               delay: Duration(milliseconds: 500))
  //         ],
  //         child: InkWell(
  //           onTap: () async {
  //             final userData = await _oauthService.signinWithApple();
  //             if (userData != null && mounted) {
  //               context.goNamed('home');
  //             } else {
  //               NavigationService.showErrorSnackBar('Apple Sign-In Failed');
  //             }
  //           },
  //           child: Card(
  //             color: Colors.white,
  //             child: Padding(
  //               padding: const EdgeInsets.all(5.0),
  //               child: SvgPicture.asset(
  //                 SvgIconsPaths.appleIcon,
  //                 height: 40,
  //                 colorFilter: const ColorFilter.mode(
  //                   Colors.black,
  //                   BlendMode.srcIn,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //       Animate(
  //         effects: const [
  //           FadeEffect(
  //             begin: BlurEffect.minBlur,
  //             end: BlurEffect.defaultBlur,
  //             duration: Duration(seconds: 5),
  //           ),
  //           ScaleEffect(
  //             begin: ScaleEffect.defaultValue,
  //             end: ScaleEffect.neutralValue,
  //             duration: Duration(seconds: 1),
  //             delay: Duration(milliseconds: 500),
  //           )
  //         ],
  //         child: InkWell(
  //           onTap: () async {
  //             NavigationService.showErrorSnackBar(
  //                 'Not Available! We are working on this!');
  //             // UserCredential? credential =
  //             //     await _googleAuthService.signInWithTwitter();

  //             // if (credential != null) {
  //             //   LogService.logInfo(
  //             //       'Twitter Sign-In Successful as  ${credential.user!.displayName}');
  //             //   context.goNamed('home');
  //             // } else {
  //             //   LogService.logError('Twitter Sign-In Failed');
  //             // }
  //           },
  //           child: Card(
  //             color: Colors.white,
  //             child: Padding(
  //               padding: const EdgeInsets.all(5.0),
  //               child: SvgPicture.asset(
  //                 SvgIconsPaths.facebookIcon,
  //                 height: 40,
  //                 // colorFilter: const ColorFilter.mode(
  //                 //   Colors.grey,
  //                 //   BlendMode.srcIn,
  //                 // ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    // sign in with google
    return InkWell(
      onTap: () async {
        setState(() {
          isGoogleLoading = true;
        });
        try {
          final googleUser = await _oauthService.signinWithGoogle(context: context);
          if (googleUser != null && mounted) {
            context.goNamed('home');
          } else {
          }
        } finally {
          setState(() {
            isGoogleLoading = false;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          
        ),
        child: !isGoogleLoading ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(SvgIconsPaths.googleIcon, height: 24),
            Gap(10),
             Text('Sign in with Google', style: TextStyle(color: Colors.black),),
          ],
        ) :
        CupertinoActivityIndicator(
          color: CupertinoColors.black,
        )
      ),
    );
  }
}
