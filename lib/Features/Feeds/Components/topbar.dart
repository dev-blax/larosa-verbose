import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../../Services/auth_service.dart';
import '../../../Utils/colors.dart';

class TopBar1 extends StatelessWidget {
  const TopBar1({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 0,
        right: 0,
        top: Platform.isIOS ? 43 : 18,
        bottom: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconWithBackground(
            context,
            iconPath: 'assets/svg_icons/chats-double.svg',
            onPressed: () {
              if (AuthService.getToken().isEmpty) {
                context.pushNamed('login');
                return;
              }
              context.pushNamed('chatsland');
            },
            semanticsLabel: 'Chat icon',
          ),
          _buildCharacterPopAnimatedText(),
          _buildIconWithBackground(
            context,
            icon: CupertinoIcons.cart,
            onPressed: () {
              if (AuthService.getToken().isEmpty) {
                context.pushNamed('login');
                return;
              }
              context.pushNamed('maincart');
            },
            isSvg: false,
          ),
        ],
      ),
    );
  }

  Widget _buildIconWithBackground(
    BuildContext context, {
    String? iconPath,
    IconData? icon,
    required VoidCallback onPressed,
    String? semanticsLabel,
    bool isSvg = true,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: Platform.isIOS ? 45 : null,
        width: Platform.isIOS ? 45 : null,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LarosaColors.primary.withOpacity(.3),
              LarosaColors.purple.withOpacity(.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSvg
            ? SvgPicture.asset(
                iconPath!,
                height: 24,
                semanticsLabel: semanticsLabel,
                colorFilter: const ColorFilter.mode(
                 Colors.white,
                  BlendMode.srcIn,
                ),
              )
            : Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
      ),
    );
  }

  Widget _buildCharacterPopAnimatedText() {
    return Container(
      // height: 30, // Fixed constant height
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            LarosaColors.primary.withOpacity(.3),
            LarosaColors.purple.withOpacity(.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
          color:   Colors.white,
        ),
        child: AnimatedTextKit(
          animatedTexts: [
            WavyAnimatedText(
              'Explore Larosa',
              speed: const Duration(milliseconds:700),
            ),
          ],
          repeatForever: true,
        ),
      ),
    );
  }
}

