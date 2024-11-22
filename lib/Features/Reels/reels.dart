// import 'dart:convert';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter_emoji/flutter_emoji.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:gap/gap.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:cached_video_player_plus/cached_video_player_plus.dart';
// import 'package:http/http.dart' as http;
// import 'package:larosa_block/Services/auth_service.dart';
// import 'package:larosa_block/Utils/colors.dart';
// import 'package:larosa_block/Utils/helpers.dart';
// import 'package:larosa_block/Utils/links.dart';
// import 'package:larosa_block/Utils/svg_paths.dart';

// class DeReelsScreen extends StatefulWidget {
//   const DeReelsScreen({super.key});

//   @override
//   State<DeReelsScreen> createState() => _DeReelsScreenState();
// }

// class _DeReelsScreenState extends State<DeReelsScreen> {
//   final PageController _pageController = PageController();
//   final List<CachedVideoPlayerPlusController> _controllers = [];
//   final List<ValueNotifier<double>> _progressIndicators = [];
//   List<Map<String, dynamic>> snippets = [];
//   bool _isPaused = false;

//   Future<void> _favouritePost(int postId) async {
//     String token = AuthService.getToken();

//     if (token.isEmpty) {
//       //Get.snackbar('Explore Larosa', 'Please login');
//       HelperFunctions.showToast('Please Login First', false);
//       //Get.to(const SigninScreen());
//       HelperFunctions.logout(context);
//       return;
//     }

//     final headers = {
//       "Content-Type": "application/json",
//       'Authorization': 'Bearer $token',
//     };

//     var url = Uri.https(
//       LarosaLinks.nakedBaseUrl,
//       '/favorites/update',
//     );

//     try {
//       final response = await http.post(
//         url,
//         body: jsonEncode({
//           "profileId": AuthService.getProfileId(),
//           "postId": postId,
//         }),
//         headers: headers,
//       );

//       if (response.statusCode == 302 || response.statusCode == 403) {
//         await AuthService.refreshToken();
//         _favouritePost(postId);
//       }

//       if (response.statusCode != 200) {
//         // Get.snackbar(
//         //   'Explore Larosa',
//         //   response.body,
//         // );
//         HelperFunctions.showToast('Cannot Perform Action', false);
//         return;
//       }
//     } catch (e) {
//       HelperFunctions.displaySnackbar(
//         'An unknown error occured',
//         context,
//         false,
//       );
//     }
//   }

//   Future<void> _loadSnippets() async {
//     String token = AuthService.getToken();
//     Map<String, String> headers = {
//       "Content-Type": "application/json",
//       "Access-Control-Allow-Origin": "*",
//       'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
//     };

//     var url = Uri.https(
//       LarosaLinks.nakedBaseUrl,
//       '/reels/fetch',
//     );
//     try {
//       final response = await http.post(
//         url,
//         body: jsonEncode({
//           'profileId': AuthService.getProfileId(),
//           'countryId': 1.toString(),
//         }),
//         headers: headers,
//       );

//       if (response.statusCode != 200) {
//         HelperFunctions.showToast('Cannot Load Snippets', false);
//         return;
//       }

//       List<dynamic> data = json.decode(response.body);
//       print(data);
//       for (var item in data) {
//         CachedVideoPlayerPlusController controller =
//             CachedVideoPlayerPlusController.networkUrl(
//                 Uri.parse(item['names']));

//         try {
//           await controller.initialize();
//           _controllers.add(controller);
//           controller.setLooping(true); // Make the video loop
//           _progressIndicators.add(ValueNotifier<double>(0.0));

//           controller.addListener(() {
//             _updateProgress(controller);
//           });

//           snippets.add(item);
//         } catch (e) {
//           // Log or handle initialization error if needed
//           print("Error initializing video: $e");
//           // Dispose of the controller if initialization fails
//           controller.dispose();
//         }
//       }

//       setState(() {});
//     } catch (e) {
//       HelperFunctions.displaySnackbar(
//         'An unknown error occurred!',
//         context,
//         false,
//       );
//     }
//   }

//   Future<void> _likePost(int postId, int index) async {
//     String token = AuthService.getToken();

//     if (token.isEmpty) {
//       //Get.snackbar('Explore Larosa', 'Please login');
//       HelperFunctions.showToast('Login first', false);
//       HelperFunctions.logout(context);
//       //Get.to(const SigninScreen());
//       return;
//     }

//     final headers = {
//       "Content-Type": "application/json",
//       'Authorization': 'Bearer $token',
//     };

//     var url = Uri.https(LarosaLinks.nakedBaseUrl, '/like/save');

//     try {
//       final response = await http.post(
//         url,
//         body: jsonEncode({
//           "likerId": AuthService.getProfileId(),
//           "postId": postId,
//         }),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//       } else if (response.statusCode == 302 || response.statusCode == 403) {
//         await AuthService.refreshToken();
//         await _likePost(postId, index);
//         return;
//       } else {
//         setState(() {
//           snippets[index]['liked'] = !snippets[index]['liked'];
//         });
//         //Get.snackbar('Explore Larosa', 'Error occured');
//       }
//     } catch (e) {
//       HelperFunctions.displaySnackbar(
//         'Failed to perform action...!',
//         context,
//         false,
//       );
//     }
//   }

//   void _seekToPosition(int index, double value) {
//     final controller = _controllers[index];
//     final newPosition = Duration(
//         milliseconds:
//             (value * controller.value.duration.inMilliseconds).toInt());
//     controller.seekTo(newPosition);
//   }

//   @override
//   void initState() {
//     super.initState();
//     _loadSnippets();
//   }

//   void _togglePlayPause() {
//     setState(() {
//       _isPaused = !_isPaused;
//       if (_isPaused) {
//         _controllers[_pageController.page!.toInt()].pause();
//       } else {
//         _controllers[_pageController.page!.toInt()].play();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     for (var controller in _controllers) {
//       controller.removeListener(() {});
//       controller.dispose();
//     }
//     for (var progressIndicator in _progressIndicators) {
//       progressIndicator.dispose();
//     }
//     _pageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   backgroundColor: Colors.transparent,
//       //   surfaceTintColor: Colors.transparent,
//       //   elevation: 0,
//       //   actions: const [],
//       //   automaticallyImplyLeading: false,
//       // ),
//       extendBodyBehindAppBar: true,
//       body: PageView.builder(
//           pageSnapping: true,
//           onPageChanged: (value) {
//             for (var i = 0; i < _controllers.length; i++) {
//               if (i != value) {
//                 _controllers[i].pause();
//               } else {
//                 _controllers[i].play();
//               }
//             }

//             if (value == _controllers.length - 1) {
//               _onLoadMoreVideos();
//             }
//           },
//           controller: _pageController,
//           itemCount: _controllers.length,
//           scrollDirection: Axis.vertical,
//           itemBuilder: (context, index) {
//             int likesCount = snippets[index]['likes'];
//             final controller = _controllers[index];
//             controller
//               ..play()
//               ..setLooping(false);
//             return Stack(
//               //fit: StackFit.loose,
//               //alignment: Alignment.centerRight,
//               children: [
//                 !controller.value.isInitialized
//                     ? const SpinKitCircle(
//                         color: LarosaColors.primary,
//                       )
//                     : GestureDetector(
//                         onTap: () async {
//                           setState(() {
//                             snippets[index]['liked'] =
//                                 !snippets[index]['liked'];

//                             if (snippets[index]['liked']) {
//                               likesCount = likesCount++;
//                             } else {
//                               likesCount = likesCount--;
//                             }
//                           });

//                           await _likePost(
//                             snippets[index]['id'],
//                             index,
//                           );
//                         },
//                         child: Center(
//                           child: AspectRatio(
//                             aspectRatio: controller.value.aspectRatio,
//                             child: GestureDetector(
//                               onTap: () {
//                                 controller.pause();
//                               },
//                               child: Stack(
//                                 alignment: Alignment.center,
//                                 children: [
//                                   //VideoPlayer(controller),
//                                   CachedVideoPlayerPlus(controller),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                 Positioned(
//                   bottom: 0,
//                   child: Container(
//                     height: 100,
//                     width: MediaQuery.of(context).size.width,
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           Colors.black54,
//                           Colors.transparent,
//                         ],
//                         begin: Alignment.bottomCenter,
//                         end: Alignment.topCenter,
//                       ),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 10,
//                   left: 5,
//                   right: 5,
//                   child: Container(
//                     padding: const EdgeInsets.all(1.0),
//                     decoration: BoxDecoration(
//                       //ipe gradient kama background za kwenye posts
//                       color: Colors.black.withOpacity(
//                           0.6), // Black background with 60% opacity
//                       borderRadius: BorderRadius.circular(
//                           10), // Rounded corners for the background
//                     ),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 snippets[index]['profile_picture'] == null
//                                     ? ClipOval(
//                                         child: Image.asset(
//                                           'assets/images/EXPLORE.png',
//                                           height: 30,
//                                           width: 30,
//                                           fit: BoxFit.cover,
//                                         ),
//                                       )
//                                     : CircleAvatar(
//                                         backgroundImage:
//                                             CachedNetworkImageProvider(
//                                           snippets[index]['profile_picture'],
//                                         ),
//                                       ),
//                                 const Gap(10),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     // https://storage.googleapis.com/explore-test-1/reels/post_16_2024_8_25_19_40_29_2.mp4
//                                     // SizedBox(
//                                     //   width: 300,
//                                     //   child: Text(
//                                     //     '${snippets[index]['names']}',
//                                     //     overflow: TextOverflow.visible, // Allows the text to wrap
//                                     //     softWrap: true, // Ensures the text wraps if it exceeds the width
//                                     //     maxLines: null, // Allows for unlimited lines
//                                     //     style: TextStyle(
//                                     //       // Add any styles you prefer
//                                     //     ),
//                                     //   ),
//                                     // ),
//                                     Text(snippets[index]['name']),
//                                     Text(
//                                       '${snippets[index]['duration']}',
//                                       style: Theme.of(context)
//                                           .textTheme
//                                           .bodySmall!
//                                           .copyWith(fontSize: 12),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                             const Gap(5),
//                             SizedBox(
//                               width: MediaQuery.of(context).size.width * .80,
//                               child: Text(
//                                 EmojiParser().emojify(
//                                   snippets[index]['caption'],
//                                 ),
//                                 style: Theme.of(context)
//                                     .textTheme
//                                     .bodySmall!
//                                     .copyWith(color: LarosaColors.light),
//                                 overflow: TextOverflow.ellipsis,
//                                 maxLines: 40,
//                               ),
//                             ),
//                             Positioned(
//                               bottom: 20,
//                               left: 10,
//                               child: ValueListenableBuilder<double>(
//                                 valueListenable: _progressIndicators[index],
//                                 builder: (context, value, child) {
//                                   return Container(
//                                     width: MediaQuery.of(context).size.width -
//                                         20, // Adjusted width for a smaller slider
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 0),
//                                     child: SliderTheme(
//                                       data: SliderTheme.of(context).copyWith(
//                                         trackHeight:
//                                             2.0, // Reduce the height of the track
//                                         thumbShape: const RoundSliderThumbShape(
//                                             enabledThumbRadius:
//                                                 6.0), // Reduce the thumb size
//                                         overlayShape: const RoundSliderOverlayShape(
//                                             overlayRadius:
//                                                 12.0), // Control the thumb hover size
//                                       ),
//                                       child: Slider(
//                                         value: value,
//                                         min: 0.0,
//                                         max: 1.0,
//                                         onChanged: (newValue) {
//                                           _seekToPosition(index, newValue);
//                                         },
//                                         activeColor: LarosaColors.grey,
//                                         inactiveColor: Colors.grey,
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             )
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 // Positioned(
//                 //   bottom: 0,
//                 //   left: 0,
//                 //   right: 0,
//                 //   child: ValueListenableBuilder<double>(
//                 //     valueListenable: _progressIndicators[index],
//                 //     builder: (context, value, child) {
//                 //       return LinearProgressIndicator(
//                 //         value: value,
//                 //         backgroundColor: Theme.of(context).colorScheme.primary,
//                 //         valueColor: AlwaysStoppedAnimation<Color>(
//                 //           Theme.of(context).colorScheme.secondaryContainer,
//                 //         ),
//                 //       );
//                 //     },
//                 //   ),
//                 // ),
//                 Positioned.directional(
//                   textDirection: TextDirection.ltr,
//                   child: IconButton(
//                     onPressed: _togglePlayPause,
//                     icon: _isPaused
//                         ? const Icon(
//                             Iconsax.play,
//                           )
//                         : const SizedBox.shrink(),
//                   ),
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   top: 0,
//                   right: 5,
//                   child: Container(
//                     alignment: Alignment.center,
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(20),
//                       child: BackdropFilter(
//                         filter: ImageFilter.blur(
//                           sigmaX: 1,
//                           sigmaY: 1,
//                         ),
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           color: Colors.black.withOpacity(.2),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             mainAxisSize: MainAxisSize.min,
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               Column(
//                                 children: [
//                                   IconButton(
//                                     onPressed: () async {
//                                       print('likes count: $likesCount');

//                                       setState(() {
//                                         snippets[index]['liked'] =
//                                             !snippets[index]['liked'];

//                                         if (snippets[index]['liked']) {
//                                           likesCount = likesCount + 1;
//                                           print('adding: $likesCount');
//                                         } else {
//                                           likesCount = likesCount - 1;
//                                           print('minusing: $likesCount');
//                                         }
//                                       });

//                                       print('likes count: $likesCount');

//                                       await _likePost(
//                                         snippets[index]['id'],
//                                         index,
//                                       );
//                                     },
//                                     icon: snippets[index]['liked']
//                                         ? SvgPicture.asset(
//                                             'assets/icons/SolarHeartAngleBold.svg',
//                                             width: 25,
//                                             height: 25,
//                                             colorFilter: const ColorFilter.mode(
//                                               Colors.red,
//                                               BlendMode.srcIn,
//                                             ),
//                                             semanticsLabel: 'Like icon',
//                                           )
//                                         : SvgPicture.asset(
//                                             "assets/icons/SolarHeartAngleLinear.svg",
//                                             width: 25,
//                                             height: 25,
//                                             colorFilter: ColorFilter.mode(
//                                               Theme.of(context)
//                                                   .colorScheme
//                                                   .secondary,
//                                               BlendMode.srcIn,
//                                             ),
//                                             semanticsLabel: 'Like icon',
//                                           ),
//                                   ),
//                                   Text(
//                                     likesCount.toString(),
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall!
//                                         .copyWith(
//                                           fontSize: 15,
//                                         ),
//                                   )
//                                 ],
//                               ),

//                               // favourite
//                               Column(
//                                 children: [
//                                   IconButton(
//                                       onPressed: () async {
//                                         await _favouritePost(
//                                             snippets[index]['id']);
//                                       },
//                                       icon: SvgPicture.asset(
//                                         !snippets[index]['favorite']
//                                             ? SvgIconsPaths.starOutline
//                                             : SvgIconsPaths.starBold,
//                                         width: 25,
//                                         height: 25,
//                                         colorFilter: ColorFilter.mode(
//                                           snippets[index]['favorite']
//                                               ? LarosaColors.gold
//                                               : Theme.of(context)
//                                                   .colorScheme
//                                                   .secondary,
//                                           BlendMode.srcIn,
//                                         ),
//                                         semanticsLabel: 'Star icon',
//                                       )),
//                                   Text(
//                                     snippets[index]['favorites'].toString(),
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall!
//                                         .copyWith(
//                                           fontSize: 15,
//                                         ),
//                                   )
//                                 ],
//                               ),
//                               // comment
//                               Column(
//                                 children: [
//                                   IconButton(
//                                     onPressed: () {
//                                       // Get.bottomSheet(
//                                       //   backgroundColor: Theme.of(context)
//                                       //       .scaffoldBackgroundColor,
//                                       //   isScrollControlled: true,
//                                       //   enableDrag: true,
//                                       //   CommentSection(
//                                       //     postId: snippets[index]['id'],
//                                       //   ),
//                                       // );
//                                     },
//                                     icon: Icon(
//                                       Iconsax.message,
//                                       color: Theme.of(context)
//                                           .colorScheme
//                                           .secondary,
//                                     ),
//                                   ),
//                                   Text(
//                                     snippets[index]['comments'].toString(),
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall!
//                                         .copyWith(
//                                           fontSize: 15,
//                                         ),
//                                   )
//                                 ],
//                               ),
//                               // Sharea
//                               Column(
//                                 children: [
//                                   IconButton(
//                                     onPressed: () {
//                                       HelperFunctions.shareLink(
//                                           '/post/${snippets[index]['id']}');
//                                     },
//                                     icon: SvgPicture.asset(
//                                       'assets/svg_icons/share.svg',
//                                       width: 25,
//                                       height: 25,
//                                       colorFilter: ColorFilter.mode(
//                                         Theme.of(context).colorScheme.secondary,
//                                         BlendMode.srcIn,
//                                       ),
//                                       semanticsLabel: 'Like icon',
//                                     ),
//                                   ),
//                                   Text(
//                                     snippets[index]['shares'].toString(),
//                                     style: Theme.of(context)
//                                         .textTheme
//                                         .bodySmall!
//                                         .copyWith(
//                                           fontSize: 15,
//                                         ),
//                                   )
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           }),
//     );
//   }

//   void _onLoadMoreVideos() {
//     // Load More Videos
//   }

//   void _updateProgress(CachedVideoPlayerPlusController controller) {
//     int controllerIndex = _controllers.indexOf(controller);
//     if (controllerIndex == -1) {
//       return;
//     }
//     final progress = controller.value.position.inMilliseconds /
//         controller.value.duration.inMilliseconds;
//     _progressIndicators[controllerIndex].value = progress;
//   }
// }

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:like_button/like_button.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';

import '../Feeds/Components/carousel.dart';
import '../Feeds/Components/comments_component.dart';

class DeReelsScreen extends StatefulWidget {
  const DeReelsScreen({super.key});

  @override
  State<DeReelsScreen> createState() => _DeReelsScreenState();
}

class _DeReelsScreenState extends State<DeReelsScreen> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> snippets = [];
  bool _isLoading = true;

  late bool _isLiked;
  late int _likesCount;
  double _opacity = 0.0; // For heart animation opacity
  bool _showExplosion = false; // For explosion animation


  @override
  void initState() {
    super.initState();
    _loadSnippets();
  }
  

  Future<void> _loadSnippets() async {
    String token = AuthService.getToken();
    final headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
    };

    var url = Uri.https(LarosaLinks.nakedBaseUrl, '/reels/fetch');
    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'profileId': AuthService.getProfileId(),
          'countryId': "1",
        }),
        headers: headers,
      );

// print('Response status: ${response.statusCode}');
// print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          snippets = data.cast<
              Map<String, dynamic>>(); // Properly casting to the required type
          _isLoading = false;
        });
      } else {
        HelperFunctions.showToast('Cannot Load Snippets', false);
      }
    } catch (e) {
      HelperFunctions.displaySnackbar(
        'An unknown error occurred!',
        context,
        false,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _favoritePost(int postId, int index) async {
    String token = AuthService.getToken();

    if (token.isEmpty) {
      // Get.snackbar('Explore Larosa', 'Please login');
      // Get.to(const SigninScreen());
      return;
    }

    final headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      '/favorites/update',
    );

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          "profileId": AuthService.getProfileId(),
          "postId": postId,
        }),
        headers: headers,
      );

      if (response.statusCode == 302) {
        print('response: ${response.statusCode}');
        await AuthService.refreshToken();
        await _favoritePost(postId, index);
      }

      if (response.statusCode != 200) {
        // Get.snackbar(
        //   'Explore Larosa',
        //   response.body,
        // );
        return;
      }
    } catch (e) {
      // Get.snackbar('Explore Larosa', 'An unknown error occurred');
    }
  }

  Future<void> _likePost(int postId, int index) async {
    String token = AuthService.getToken();

    if (token.isEmpty) {
      // Get.snackbar('Explore Larosa', 'Please login');
      // Get.to(const SigninScreen());
      return;
    }

    final headers = {
      "Content-Type": "application/json",
      'Authorization': 'Bearer $token',
    };

    var url = Uri.https(LarosaLinks.nakedBaseUrl, '/like/save');

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          "likerId": AuthService.getProfileId(),
          "postId": postId,
        }),
        headers: headers,
      );

      if (response.statusCode == 200) {
      } else if (response.statusCode == 302 || response.statusCode == 403) {
        await AuthService.refreshToken();
        await _likePost(postId, index);
        return;
      } else {
        // Get.snackbar('Explore Larosa', 'Error occured');
      }
    } catch (e) {
      //HelperFunctions.displaySnackbar('An unknown error occurred');
    }
  }

  // void toggleLike(int index) {
  //   setState(() {
  //     // Toggle like state and update like count
  //     snippets[index]['liked'] = !snippets[index]['liked'];
  //     snippets[index]['likes'] += snippets[index]['liked'] ? 1 : -1;

  //     // Trigger animations
  //     _opacity = 1.0;
  //     _showExplosion = true;
  //   });

  //   // Reset animations after a delay
  //   Future.delayed(const Duration(milliseconds: 1300), () {
  //     setState(() {
  //       _opacity = 0.0;
  //       _showExplosion = false;
  //     });
  //   });
  // }

  void toggleLike(int index) {
    setState(() {
      // Toggle the like state
      snippets[index]['liked'] = !snippets[index]['liked'];
      snippets[index]['likes'] += snippets[index]['liked'] ? 1 : -1;

      // Show the heart animation and explosion effect
      if (snippets[index]['liked']) {
        _opacity = 1.0; // Show the heart
        _showExplosion = true; // Show explosion
      }
    });

    // Reset animations after a delay
    if (snippets[index]['liked']) {
      Future.delayed(const Duration(milliseconds: 13000), () {
        setState(() {
          _opacity = 0.0; // Hide the heart
          _showExplosion = false; // Hide explosion
        });
      });
    }

    // Call the like API
    _likePost(snippets[index]['id'], index);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // body: Stack(
      //   children: [
      //     _isLoading
      //         ? _buildLoadingShimmer(context) // Show shimmer while loading
      //         : Container(
      //             color: Theme.of(context).scaffoldBackgroundColor,
      //             child: PageView.builder(
      //               controller: _pageController,
      //               itemCount: snippets.length,
      //               scrollDirection: Axis.vertical,
      //               itemBuilder: (context, index) {
      //                 final snippet = snippets[index];
      //                 return GestureDetector(
      //                   child: Stack(children: [
      //                     CenterSnapCarousel(
      //                       mediaUrls: [snippet['names']],
      //                       isPlayingState: true,
      //                       postHeight: MediaQuery.of(context).size.height,
      //                     ),
      //                     _postInteracts(
      //                       snippets[index],
      //                       snippet['id'],
      //                       snippet['name'],
      //                       snippet['duration'],
      //                       snippet['caption'],
      //                       snippet['liked'],
      //                       snippet['likes'],
      //                       snippet['favorite'],
      //                       snippet['favorites'],
      //                     )
      //                   ]),
      //                 );
      //               },
      //             ),
      //           ),
      //   ],
      // ),

      body: Stack(
  children: [
    _isLoading
        ? _buildLoadingShimmer(context) // Show shimmer while loading
        : GestureDetector(
          onDoubleTap: () {
    // Get the current page index
    final currentIndex = _pageController.page?.round() ?? 0;

    // Trigger the like animation and update state
    toggleLike(currentIndex);
  },
            onTap: () {
              // Get the current page index
              final currentIndex = _pageController.page?.round() ?? 0;

              // Toggle play/pause for the current video
              setState(() {
                snippets[currentIndex]['isPlaying'] = 
                    !(snippets[currentIndex]['isPlaying'] ?? true);
              });
            },
            child: Container(
              color: Colors.black, // Prevent unintended gestures by providing a base color
              child: PageView.builder(
                controller: _pageController,
                itemCount: snippets.length,
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  // Pause all videos except the current one
                  setState(() {
                    for (var i = 0; i < snippets.length; i++) {
                      snippets[i]['isPlaying'] = i == index;
                    }
                  });
                },
                itemBuilder: (context, index) {
                  final snippet = snippets[index];
                  snippet['isPlaying'] ??= true; // Initialize playing state if null

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CenterSnapCarousel(
                        mediaUrls: [snippet['names']],
                        isPlayingState: snippet['isPlaying'],
                        postHeight: MediaQuery.of(context).size.height,
                      ),
                      if (!snippet['isPlaying']) // Show play icon when paused
                        Icon(
                          Icons.play_circle_outline,
                          size: 70,
                          color: Colors.white.withOpacity(.7)
                        ),

                        // Explosion effect
                        if (_showExplosion)
                          LottieBuilder.asset(
                            'assets/lotties/like_explode.json',
                            width: 250,
                            height: 250,
                            repeat: false,
                          ),
                          
                      _postInteracts(
                        snippet,
                        snippet['id'],
                        snippet['name'],
                        snippet['duration'],
                        snippet['caption'],
                        snippet['liked'],
                        snippet['likes'],
                        snippet['favorite'],
                        snippet['favorites'],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
  ],
)
    );
  }

  Widget _postInteracts(
    Map<String, dynamic> snippet,
    int postId,
    String name,
    String duration,
    String caption,
    bool liked,
    int likes,
    bool favorite,
    int favorites,
  ) {
    return Positioned(
      bottom:
          MediaQuery.of(context).size.height / 2 - 100, // Centered with offset
      right: 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3), // Black with light opacity
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Like Button with Count Below
            Column(
              children: [
                LikeButton(
                  size: 26.0,
                  isLiked: liked,
                  likeCount: likes,
                  animationDuration: const Duration(milliseconds: 500),
                  bubblesColor: const BubblesColor(
                    dotPrimaryColor: Color.fromRGBO(180, 23, 12, 1),
                    dotSecondaryColor: Colors.orange,
                  ),
                  circleColor: const CircleColor(
                    start: Color.fromRGBO(255, 204, 0, 1),
                    end: Color.fromRGBO(180, 23, 12, 1),
                  ),
                  likeBuilder: (bool isLiked) {
                    return SvgPicture.asset(
                      isLiked
                          ? 'assets/icons/SolarHeartAngleBold.svg'
                          : 'assets/icons/SolarHeartAngleLinear.svg',
                      width: 30,
                      height: 30,
                      colorFilter: ColorFilter.mode(
                        isLiked
                            ? const Color.fromRGBO(180, 23, 12, 1)
                            : Colors.white,
                        BlendMode.srcIn,
                      ),
                    );
                  },
                  countBuilder: (int? count, bool isLiked, String text) {
                    return Text(
                      text, // The like count as a string
                      style: const TextStyle(
                        color: Colors.white, // Set the text color to white
                        fontSize: 14.0, // Adjust the font size if needed
                        fontWeight: FontWeight.bold, // Optional for styling
                      ),
                    );
                  },
                  countPostion: CountPostion
                      .bottom, // Position the like count below the button
                  likeCountPadding: const EdgeInsets.only(
                      top: 8.0), // Add space between button and like count
                  onTap: (bool isLiked) async {
                    toggleLike(snippets.indexOf(snippet));
                    return !isLiked;
                  },
                ),
                const SizedBox(height: 5),
                // Text(
                //   likes.toString(),
                //   style: const TextStyle(color: Colors.white, fontSize: 12),
                // ),
              ],
            ),
            const SizedBox(height: 5),

            // Favorite Button with Count Below
            Column(
              children: [
                // LikeButton(
                //   size: 30.0,
                //   isLiked: favorite,
                //   likeCount: favorites,
                //   animationDuration: const Duration(milliseconds: 500),
                //   bubblesColor: const BubblesColor(
                //     dotPrimaryColor: Color.fromRGBO(255, 215, 0, 1),
                //     dotSecondaryColor: Colors.orange,
                //   ),
                //   circleColor: const CircleColor(
                //     start: Color.fromRGBO(255, 223, 0, 1),
                //     end: Color.fromRGBO(255, 215, 0, 1),
                //   ),
                //   likeBuilder: (bool isLiked) {
                //     return SvgPicture.asset(
                //       isLiked
                //           ? SvgIconsPaths.starBold
                //           : SvgIconsPaths.starOutline,
                //       width: 30,
                //       height: 30,
                //       colorFilter: ColorFilter.mode(
                //         isLiked
                //             ? LarosaColors.gold
                //             : Colors.white,
                //         BlendMode.srcIn,
                //       ),
                //     );
                //   },
                //   onTap: (bool isFavorite) async {
                //     await _favoritePost(postId, snippets.indexOf(snippet));
                //     return !isFavorite;
                //   },
                // ),

                LikeButton(
                  size: 26.0,
                  isLiked: favorite,
                  likeCount: favorites,
                  animationDuration: const Duration(milliseconds: 500),
                  bubblesColor: const BubblesColor(
                    dotPrimaryColor: Color.fromRGBO(255, 215, 0, 1),
                    dotSecondaryColor: Colors.orange,
                  ),
                  circleColor: const CircleColor(
                    start: Color.fromRGBO(255, 223, 0, 1),
                    end: Color.fromRGBO(255, 215, 0, 1),
                  ),
                  likeBuilder: (bool isLiked) {
                    return SvgPicture.asset(
                      isLiked
                          ? SvgIconsPaths.starBold
                          : SvgIconsPaths.starOutline,
                      width: 30,
                      height: 30,
                      colorFilter: ColorFilter.mode(
                        isLiked ? LarosaColors.gold : Colors.white,
                        BlendMode.srcIn,
                      ),
                    );
                  },
                  countBuilder: (int? count, bool isLiked, String text) {
                    return Text(
                      text, // The like count as a string
                      style: const TextStyle(
                        color: Colors.white, // Set the text color to white
                        fontSize: 14.0, // Adjust the font size if needed
                        fontWeight: FontWeight.bold, // Optional for styling
                      ),
                    );
                  },
                  countPostion: CountPostion
                      .bottom, // Position the like count below the button
                  likeCountPadding: const EdgeInsets.only(
                      top: 10.0), // Add space between button and like count
                  onTap: (bool isFavorite) async {
                    await _favoritePost(postId, snippets.indexOf(snippet));
                    return !isFavorite;
                  },
                ),

                // const SizedBox(height: 5),
                // Text(
                //   favorites.toString(),
                //   style: const TextStyle(color: Colors.white, fontSize: 12),
                // ),
              ],
            ),

            const SizedBox(height: 5),

            // Comment Button with Count Below
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    showMaterialModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) => Container(
                        constraints: const BoxConstraints(minHeight: 200),
                        child: CommentSection(
                          postId: postId,
                          names: name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Iconsax.message,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                Text(
                  snippet['comments'].toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Share Button with Count Below (optional if needed)
            Column(
              children: [
                IconButton(
                  onPressed: () {
                    HelperFunctions.shareLink(postId.toString());
                  },
                  icon: SvgPicture.asset(
                    'assets/svg_icons/share.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    height: 24,
                  ),
                ),
                const SizedBox(height: 5),
                // Optional: If a share count exists, you can show it here.
                const Text(
                  'Share', // Example text or count
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      itemCount: 5, // Number of shimmer placeholders
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
          child: Shimmer.fromColors(
            period: const Duration(milliseconds: 6000), // Animation duration
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[300]!,
            highlightColor: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
            child: Container(
              height: MediaQuery.of(context).size.height *
                  0.8, // Match video card size
              decoration: BoxDecoration(
                // color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Video Thumbnail Placeholder
                  // Positioned.fill(
                  //   child: Container(
                  //     color: Colors.grey[300],
                  //   ),
                  // ),
                  // Profile Picture and Text Placeholder
                  Positioned(
                    bottom: 0,
                    left: 16,
                    child: Row(
                      children: [
                        // Profile Picture Placeholder
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Caption Placeholder
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: MediaQuery.of(context).size.width * 0.5,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 16,
                              width: MediaQuery.of(context).size.width * 0.4,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Interaction Buttons Placeholder
                  Positioned(
                    bottom: 20,
                    right: 16,
                    child: Column(
                      children: [
                        // Like Button Placeholder
                        Column(
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 40,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Favorite Button Placeholder
                        Column(
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 40,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Comment Button Placeholder
                        Column(
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 40,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Share Button Placeholder
                        Column(
                          children: [
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 12,
                              width: 40,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
