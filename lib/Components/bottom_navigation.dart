import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Services/auth_service.dart';

import 'package:larosa_block/Utils/svg_paths.dart';

enum ActivePage {
  feeds,
  search,
  newPost,
  delivery,
  account,
}

class BottomNavigation extends StatelessWidget {
  final ActivePage activePage;
  const BottomNavigation({
    super.key,
    required this.activePage,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black.withOpacity(.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  
                  context.goNamed('home');
                },
                icon: SvgPicture.asset(
                  activePage == ActivePage.feeds
                      ? SvgIconsPaths.homeBold
                      : SvgIconsPaths.homeOutline,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  context.push('/search');
                },
                icon: SvgPicture.asset(
                  'assets/svg_icons/searchOutline.svg',
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn,
                  ),
                  height: 28,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (AuthService.getToken().isEmpty) {
                    context.pushNamed('login');
                    return;
                  }
                  context.pushNamed('cameraContent');
                },
                icon: const Icon(
                  Iconsax.add_circle5,
                  size: 30,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (AuthService.getToken().isEmpty) {
                    context.pushNamed('login');
                    return;
                  }
                  context.pushNamed('maindelivery');
                },
                icon: SvgPicture.asset(
                  'assets/svg_icons/transportOutline.svg',
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn,
                  ),
                  height: 25,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (AuthService.getToken().isEmpty) {
                    context.pushNamed('login');
                    return;
                  }
                  context.pushNamed('homeprofile');
                },
                icon: SvgPicture.asset(
                  activePage == ActivePage.account
                      ? SvgIconsPaths.userBold
                      : SvgIconsPaths.userOutline,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn,
                  ),
                  height: 23,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
