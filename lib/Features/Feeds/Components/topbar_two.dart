import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

class TopBar2 extends StatelessWidget {
  const TopBar2({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              'assets/svg_icons/NotoV1Fire.svg',
              height: 30,
              semanticsLabel: 'Fire icon',
            ),
          ),
          // InkWell(
          //   onTap: () {
          //     // Get.to(
          //     //   const HomeProfileScreen(),
          //     //   transition: Transition.rightToLeft,
          //     //   curve: Curves.fastOutSlowIn,
          //     // );
          //   },
          //   child: const CircleAvatar(
             
          //     child: Icon(Iconsax.user),
          //   ),
          // ),
          IconButton(
            onPressed: () {
              // Get.to(
              //   const DeReelsScreen(),
              // );
              context.push('/reels');
            },
            icon: SvgPicture.asset(
              'assets/svg_icons/reels.svg',
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.secondary,
                BlendMode.srcIn,
              ),
              height: 25,
            ),
          ),
        ],
      ),
    );
  }
}
