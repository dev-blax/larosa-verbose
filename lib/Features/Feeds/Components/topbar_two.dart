// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';

// class TopBar2 extends StatelessWidget {
//   const TopBar2({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           IconButton(
//             onPressed: () {},
//             icon: SvgPicture.asset(
//               'assets/svg_icons/NotoV1Fire.svg',
//               height: 30,
//               semanticsLabel: 'Fire icon',
//             ),
//           ),
//           // InkWell(
//           //   onTap: () {
//           //     // Get.to(
//           //     //   const HomeProfileScreen(),
//           //     //   transition: Transition.rightToLeft,
//           //     //   curve: Curves.fastOutSlowIn,
//           //     // );
//           //   },
//           //   child: const CircleAvatar(
             
//           //     child: Icon(Iconsax.user),
//           //   ),
//           // ),
//           IconButton(
//             onPressed: () {
//               // Get.to(
//               //   const DeReelsScreen(),
//               // );
//               context.push('/reels');
//             },
//             icon: SvgPicture.asset(
//               'assets/svg_icons/reels.svg',
//               colorFilter: ColorFilter.mode(
//                 Theme.of(context).colorScheme.secondary,
//                 BlendMode.srcIn,
//               ),
//               height: 25,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }







import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../Utils/colors.dart';

class TopBar2 extends StatelessWidget {
  const TopBar2({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildIconWithBackground(
            context,
            iconPath: 'assets/svg_icons/NotoV1Fire.svg',
            onPressed: () {},
            semanticsLabel: 'Fire icon',
          ),
          _buildIconWithBackground(
            context,
            iconPath: 'assets/svg_icons/reels.svg',
            onPressed: () {
              context.pushNamed('reels');
            },
            semanticsLabel: 'Reels icon',
          ),
        ],
      ),
    );
  }

  Widget _buildIconWithBackground(BuildContext context, {
    required String iconPath,
    required VoidCallback onPressed,
    required String semanticsLabel,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              LarosaColors.primary.withOpacity(.3),
              LarosaColors.purple.withOpacity(.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            iconPath,
            height: 22,
            semanticsLabel: semanticsLabel,
            colorFilter: ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}