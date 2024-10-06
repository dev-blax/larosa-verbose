import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import 'package:larosa_block/Utils/svg_paths.dart';

enum ActivePage {
  feeds,
  search,
  newPost,
  delivery,
  account,
}

// class BottomNavigationController extends GetxController {
//   var selectedIndex = 0.obs;

//   void changeIndex(int index) {
//     selectedIndex.value = index;
//   }
// }

class BottomNavigation extends StatelessWidget {
  final ActivePage activePage;
  const BottomNavigation({super.key, required this.activePage});

  // final BottomNavigationController controller =
  //     Get.put(BottomNavigationController());

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
                  // controller.changeIndex(0);
                  // Get.offUntil(
                  //   MaterialPageRoute(
                  //       builder: (_) => const HomeFeedsScreen()),
                  //   (route) => route.isFirst,
                  // );

                  context.goNamed('home');
                },
                icon: SvgPicture.asset(
                  activePage == ActivePage.feeds
                      ? SvgIconsPaths.homeBold
                      : SvgIconsPaths.homeOutline,
                  colorFilter: ColorFilter.mode(
                    // controller.selectedIndex.value == 0
                    //     ? Theme.of(context).colorScheme.secondary
                    //     : Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.secondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // controller.changeIndex(1);
                  // if (Get.currentRoute == '/search') {
                  //  // HelperFunctions.larosaLogger('in stack');
                  //   Get.offNamedUntil(
                  //     '/search',
                  //     (route) => false,
                  //   );
                  // } else {
                  //   HelperFunctions.larosaLogger('Not in stack');
                  //   Get.toNamed(
                  //     '/search',
                  //   );
                  // }
                  context.go('/search');
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
                  // controller.changeIndex(2);
                  // Get.to(
                  //   const CameraContent(),
                  //   transition: Transition.downToUp,
                  //   curve: Curves.decelerate,
                  // );
                  // Get.to(
                  //   const NewBusinessPost(),
                  //     transition: Transition.downToUp,
                  //   curve: Curves.decelerate,
                  // );

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
                  // controller.changeIndex(3);
                  // Get.to(
                  //   const MainDeliveryScreen(),
                  // );
                  context.goNamed('maindelivery');
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
                  // controller.changeIndex(4);

                  // if (Get.currentRoute == '/myprofile') {
                  //   HelperFunctions.larosaLogger('My profile in stack');
                  //   Get.offNamedUntil(
                  //     '/myprofile',
                  //     (route) => false,
                  //   );
                  // } else {
                  //   HelperFunctions.larosaLogger(
                  //       ' my profile Not in stack');
                  //   Get.toNamed(
                  //     '/myprofile',
                  //   );
                  // }
                  context.goNamed('homeprofile');
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
