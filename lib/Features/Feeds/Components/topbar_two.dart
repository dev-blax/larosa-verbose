import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TopBar2 extends StatelessWidget {
  const TopBar2({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          InkWell(
            onTap: () {
              // Get.to(
              //   const HomeProfileScreen(),
              //   transition: Transition.rightToLeft,
              //   curve: Curves.fastOutSlowIn,
              // );
            },
            child: const CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                'https://images.pexels.com/photos/18325432/pexels-photo-18325432/free-photo-of-hiker-and-a-camera-standing-by-a-lake-in-the-forest-with-her-arms-spread.jpeg?auto=compress&cs=tinysrgb&w=600&lazy=load',
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // Get.to(
              //   const DeReelsScreen(),
              // );
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
