// import 'dart:ui';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:larosa_block/Services/auth_service.dart';

// import 'package:larosa_block/Utils/svg_paths.dart';

// import '../Utils/colors.dart';

// enum ActivePage {
//   feeds,
//   search,
//   newPost,
//   delivery,
//   account,
// }

// class BottomNavigation extends StatelessWidget {
//   final ActivePage activePage;
//   const BottomNavigation({
//     super.key,
//     required this.activePage,
//   }); 

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(
//           // sigmaX: 10,
//           // sigmaY: 10,
//           sigmaX: 0,
//           sigmaY: 0,
//         ),
//         child: Container(
//           padding: const EdgeInsets.all(8),
//           color: Theme.of(context).colorScheme.surface.withOpacity(.2),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               IconButton(
//                 onPressed: () {
//                   context.goNamed('home');
//                 },
//                 icon: SvgPicture.asset(
//                   activePage == ActivePage.feeds
//                       ? SvgIconsPaths.homeBold
//                       : SvgIconsPaths.homeOutline,
//                   colorFilter: ColorFilter.mode(
//                     Theme.of(context).colorScheme.secondary,
//                     BlendMode.srcIn,
//                   ),
//                 ),
//               ),
//               IconButton(
//                 onPressed: () {
//                   context.push('/search');
//                 },
//                 icon: SvgPicture.asset(
//                   'assets/svg_icons/searchOutline.svg',
//                   colorFilter: ColorFilter.mode(
//                     Theme.of(context).colorScheme.secondary,
//                     BlendMode.srcIn,
//                   ),
//                   height: 25,
//                 ),
//               ),
//               // IconButton(
//               //   onPressed: () {
//               //     if (AuthService.getToken().isEmpty) {
//               //       context.pushNamed('login');
//               //       return;
//               //     }
//               //     context.pushNamed('main-post');
//               //   },
//               //   icon: const Icon(
//               //     Iconsax.add_circle5,
//               //     size: 30,
//               //     color: LarosaColors.primary,
//               //   ),
//               // ),

//               Container(
//   decoration: const BoxDecoration(
//     gradient: LinearGradient(
//       colors: [LarosaColors.secondary, LarosaColors.purple],
//       begin: Alignment.topLeft,
//       end: Alignment.bottomRight,
//     ),
//     shape: BoxShape.circle,
//   ),
//   child: IconButton(
//     onPressed: () {
//       if (AuthService.getToken().isEmpty) {
//         context.pushNamed('login');
//         return;
//       }
//       context.pushNamed('main-post');
//     },
//     icon: const Icon(
//       CupertinoIcons.add,
//       size: 25,
//       color: Colors.white, // Make the icon white to contrast with the gradient
//     ),
//     iconSize: 30,
//   ),
// ),
//               IconButton(
//                 onPressed: () {
//                   if (AuthService.getToken().isEmpty) {
//                     context.pushNamed('login');
//                     return;
//                   }
//                   context.pushNamed('maindelivery');
//                 },
//                 icon: SvgPicture.asset(
//                   activePage == ActivePage.delivery
//                       ? SvgIconsPaths.transportBold
//                       : 'assets/svg_icons/transportOutline.svg',
//                   colorFilter: ColorFilter.mode(
//                     Theme.of(context).colorScheme.secondary,
//                     BlendMode.srcIn,
//                   ),
//                   height: 25,
//                 ),
//               ),
//               IconButton(
//                 onPressed: () {
//                   if (AuthService.getToken().isEmpty) {
//                     context.pushNamed('login');
//                     return;
//                   }
//                   context.pushNamed('homeprofile');
//                 },
//                 icon: SvgPicture.asset(
//                   activePage == ActivePage.account
//                       ? SvgIconsPaths.userBold
//                       : SvgIconsPaths.userOutline,
//                   colorFilter: ColorFilter.mode(
//                     Theme.of(context).colorScheme.secondary,
//                     BlendMode.srcIn,
//                   ),
//                   height: 23,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


// import 'dart:ui';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';
// import 'package:larosa_block/Services/auth_service.dart';
// import '../Utils/colors.dart';
// import '../Utils/svg_paths.dart';

// enum ActivePage {
//   feeds,
//   search,
//   newPost,
//   delivery,
//   account,
// }

// class BottomNavigation extends StatelessWidget {
//   final ActivePage activePage;

//   const BottomNavigation({
//     super.key,
//     required this.activePage,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 90,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             Theme.of(context).colorScheme.surface.withOpacity(0.9),
//             Theme.of(context).colorScheme.background.withOpacity(0.9),
//           ],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 10,
//             offset: const Offset(0, -4),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildNavItem(
//             context,
//             icon: Icons.home_outlined,
//             activeIcon: Icons.home,
//             label: 'Home',
//             isActive: activePage == ActivePage.feeds,
//             onTap: () => context.goNamed('home'),
//           ),
//           _buildNavItem(
//             context,
//             icon: Icons.search_outlined,
//             activeIcon: Icons.search,
//             label: 'Search',
//             isActive: activePage == ActivePage.search,
//             onTap: () => context.push('/search'),
//           ),
//           _buildFloatingActionButton(context),
//           _buildNavItem(
//             context,
//             icon: Icons.local_shipping_outlined,
//             activeIcon: Icons.local_shipping,
//             label: 'Delivery',
//             isActive: activePage == ActivePage.delivery,
//             onTap: () => context.pushNamed('maindelivery'),
//           ),
//           _buildNavItem(
//             context,
//             icon: Icons.person_outline,
//             activeIcon: Icons.person,
//             label: 'Profile',
//             isActive: activePage == ActivePage.account,
//             onTap: () => context.pushNamed('homeprofile'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNavItem(
//     BuildContext context, {
//     required IconData icon,
//     required IconData activeIcon,
//     required String label,
//     required bool isActive,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 300),
//             transitionBuilder: (child, animation) => ScaleTransition(
//               scale: animation,
//               child: child,
//             ),
//             child: Icon(
//               isActive ? activeIcon : icon,
//               key: ValueKey(isActive),
//               size: isActive ? 28 : 24,
//               color: isActive
//                   ? Theme.of(context).colorScheme.primary
//                   : Theme.of(context).colorScheme.secondary.withOpacity(0.6),
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//               color: isActive
//                   ? Theme.of(context).colorScheme.primary
//                   : Theme.of(context).colorScheme.secondary.withOpacity(0.6),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFloatingActionButton(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         if (AuthService.getToken().isEmpty) {
//           context.pushNamed('login');
//           return;
//         }
//         context.pushNamed('main-post');
//       },
//       child: Container(
//         width: 65,
//         height: 65,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [LarosaColors.secondary, LarosaColors.purple],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: LarosaColors.purple.withOpacity(0.5),
//               blurRadius: 15,
//               spreadRadius: 1,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: const Icon(
//           CupertinoIcons.add,
//           size: 30,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Services/auth_service.dart';
import '../Utils/colors.dart';

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
    return Container(
      height: 70, // Reduced height
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.5),
            Theme.of(context).colorScheme.surface.withOpacity(0.7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), // Smaller corner radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2), // Adjusted shadow for smaller size
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Reduced padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: activePage == ActivePage.feeds,
            onTap: () => context.goNamed('home'),
          ),
          _buildNavItem(
            context,
            icon: Icons.search_outlined,
            label: 'Search',
            isActive: activePage == ActivePage.search,
            onTap: () => context.push('/search'),
          ),
          _buildFloatingActionButton(context),
          _buildNavItem(
            context,
            icon: Icons.local_shipping_outlined,
            label: 'Delivery',
            isActive: activePage == ActivePage.delivery,
            onTap: () => context.pushNamed('maindelivery'),
          ),
          _buildNavItem(
            context,
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: activePage == ActivePage.account,
            onTap: () => context.pushNamed('homeprofile'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: isActive ? 28 : 22, // Increase size for active state
            width: isActive ? 28 : 22, // Maintain proportions
            child: Icon(
              icon,
              size: isActive ? 28 : 22, // Dynamically change size
              color: Theme.of(context).colorScheme.secondary, // Keep colour consistent
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10, // Small text size for all
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal, // Bold text for active
              color: Theme.of(context).colorScheme.secondary, // Consistent colour
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (AuthService.getToken().isEmpty) {
          context.pushNamed('login');
          return;
        }
        context.pushNamed('main-post');
      },
      child: Container(
        width: 50, // Smaller width
        height: 50, // Smaller height
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [LarosaColors.secondary, LarosaColors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: LarosaColors.purple.withOpacity(0.4),
              blurRadius: 12, // Smaller blur radius
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.add,
          size: 24, // Reduced icon size for the FAB
          color: Colors.white,
        ),
      ),
    );
  }
}


