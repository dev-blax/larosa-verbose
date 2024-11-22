// // import 'dart:convert';
// // import 'dart:ui';
// // import 'package:flutter/material.dart';
// // import 'package:cached_network_image/cached_network_image.dart';
// // import 'package:flutter_emoji/flutter_emoji.dart';
// // import 'package:flutter_spinkit/flutter_spinkit.dart';
// // import 'package:flutter_svg/svg.dart';
// // import 'package:gap/gap.dart';
// // import 'package:iconsax/iconsax.dart';
// // import 'package:cached_video_player_plus/cached_video_player_plus.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:larosa_block/Services/auth_service.dart';
// // import 'package:larosa_block/Utils/colors.dart';
// // import 'package:larosa_block/Utils/helpers.dart';
// // import 'package:larosa_block/Utils/links.dart';
// // import 'package:larosa_block/Utils/svg_paths.dart';

// // class DeReelsScreen extends StatefulWidget {
// //   const DeReelsScreen({super.key});

// //   @override
// //   State<DeReelsScreen> createState() => _DeReelsScreenState();
// // }

// // class _DeReelsScreenState extends State<DeReelsScreen> {
// //   final PageController _pageController = PageController();
// //   final List<CachedVideoPlayerPlusController> _controllers = [];
// //   final List<ValueNotifier<double>> _progressIndicators = [];
// //   List<Map<String, dynamic>> snippets = [];
// //   bool _isPaused = false;

// //   Future<void> _favouritePost(int postId) async {
// //     String token = AuthService.getToken();

// //     if (token.isEmpty) {
// //       //Get.snackbar('Explore Larosa', 'Please login');
// //       HelperFunctions.showToast('Please Login First', false);
// //       //Get.to(const SigninScreen());
// //       HelperFunctions.logout(context);
// //       return;
// //     }

// //     final headers = {
// //       "Content-Type": "application/json",
// //       'Authorization': 'Bearer $token',
// //     };

// //     var url = Uri.https(
// //       LarosaLinks.nakedBaseUrl,
// //       '/favorites/update',
// //     );

// //     try {
// //       final response = await http.post(
// //         url,
// //         body: jsonEncode({
// //           "profileId": AuthService.getProfileId(),
// //           "postId": postId,
// //         }),
// //         headers: headers,
// //       );

// //       if (response.statusCode == 302 || response.statusCode == 403) {
// //         await AuthService.refreshToken();
// //         _favouritePost(postId);
// //       }

// //       if (response.statusCode != 200) {
// //         // Get.snackbar(
// //         //   'Explore Larosa',
// //         //   response.body,
// //         // );
// //         HelperFunctions.showToast('Cannot Perform Action', false);
// //         return;
// //       }
// //     } catch (e) {
// //       HelperFunctions.displaySnackbar(
// //         'An unknown error occured',
// //         context,
// //         false,
// //       );
// //     }
// //   }

// //   Future<void> _loadSnippets() async {
// //     String token = AuthService.getToken();
// //     Map<String, String> headers = {
// //       "Content-Type": "application/json",
// //       "Access-Control-Allow-Origin": "*",
// //       'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
// //     };

// //     var url = Uri.https(
// //       LarosaLinks.nakedBaseUrl,
// //       '/reels/fetch',
// //     );
// //     try {
// //       final response = await http.post(
// //         url,
// //         body: jsonEncode({
// //           'profileId': AuthService.getProfileId(),
// //           'countryId': 1.toString(),
// //         }),
// //         headers: headers,
// //       );

// //       if (response.statusCode != 200) {
// //         HelperFunctions.showToast('Cannot Load Snippets', false);
// //         return;
// //       }

// //       List<dynamic> data = json.decode(response.body);
// //       print(data);
// //       for (var item in data) {
// //         CachedVideoPlayerPlusController controller =
// //             CachedVideoPlayerPlusController.networkUrl(
// //                 Uri.parse(item['names']));

// //         try {
// //           await controller.initialize();
// //           _controllers.add(controller);
// //           controller.setLooping(true); // Make the video loop
// //           _progressIndicators.add(ValueNotifier<double>(0.0));

// //           controller.addListener(() {
// //             _updateProgress(controller);
// //           });

// //           snippets.add(item);
// //         } catch (e) {
// //           // Log or handle initialization error if needed
// //           print("Error initializing video: $e");
// //           // Dispose of the controller if initialization fails
// //           controller.dispose();
// //         }
// //       }

// //       setState(() {});
// //     } catch (e) {
// //       HelperFunctions.displaySnackbar(
// //         'An unknown error occurred!',
// //         context,
// //         false,
// //       );
// //     }
// //   }

// //   Future<void> _likePost(int postId, int index) async {
// //     String token = AuthService.getToken();

// //     if (token.isEmpty) {
// //       //Get.snackbar('Explore Larosa', 'Please login');
// //       HelperFunctions.showToast('Login first', false);
// //       HelperFunctions.logout(context);
// //       //Get.to(const SigninScreen());
// //       return;
// //     }

// //     final headers = {
// //       "Content-Type": "application/json",
// //       'Authorization': 'Bearer $token',
// //     };

// //     var url = Uri.https(LarosaLinks.nakedBaseUrl, '/like/save');

// //     try {
// //       final response = await http.post(
// //         url,
// //         body: jsonEncode({
// //           "likerId": AuthService.getProfileId(),
// //           "postId": postId,
// //         }),
// //         headers: headers,
// //       );

// //       if (response.statusCode == 200) {
// //       } else if (response.statusCode == 302 || response.statusCode == 403) {
// //         await AuthService.refreshToken();
// //         await _likePost(postId, index);
// //         return;
// //       } else {
// //         setState(() {
// //           snippets[index]['liked'] = !snippets[index]['liked'];
// //         });
// //         //Get.snackbar('Explore Larosa', 'Error occured');
// //       }
// //     } catch (e) {
// //       HelperFunctions.displaySnackbar(
// //         'Failed to perform action...!',
// //         context,
// //         false,
// //       );
// //     }
// //   }

// //   void _seekToPosition(int index, double value) {
// //     final controller = _controllers[index];
// //     final newPosition = Duration(
// //         milliseconds:
// //             (value * controller.value.duration.inMilliseconds).toInt());
// //     controller.seekTo(newPosition);
// //   }

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadSnippets();
// //   }

// //   void _togglePlayPause() {
// //     setState(() {
// //       _isPaused = !_isPaused;
// //       if (_isPaused) {
// //         _controllers[_pageController.page!.toInt()].pause();
// //       } else {
// //         _controllers[_pageController.page!.toInt()].play();
// //       }
// //     });
// //   }

// //   @override
// //   void dispose() {
// //     for (var controller in _controllers) {
// //       controller.removeListener(() {});
// //       controller.dispose();
// //     }
// //     for (var progressIndicator in _progressIndicators) {
// //       progressIndicator.dispose();
// //     }
// //     _pageController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       // appBar: AppBar(
// //       //   backgroundColor: Colors.transparent,
// //       //   surfaceTintColor: Colors.transparent,
// //       //   elevation: 0,
// //       //   actions: const [],
// //       //   automaticallyImplyLeading: false,
// //       // ),
// //       extendBodyBehindAppBar: true,
// //       body: PageView.builder(
// //           pageSnapping: true,
// //           onPageChanged: (value) {
// //             for (var i = 0; i < _controllers.length; i++) {
// //               if (i != value) {
// //                 _controllers[i].pause();
// //               } else {
// //                 _controllers[i].play();
// //               }
// //             }

// //             if (value == _controllers.length - 1) {
// //               _onLoadMoreVideos();
// //             }
// //           },
// //           controller: _pageController,
// //           itemCount: _controllers.length,
// //           scrollDirection: Axis.vertical,
// //           itemBuilder: (context, index) {
// //             int likesCount = snippets[index]['likes'];
// //             final controller = _controllers[index];
// //             controller
// //               ..play()
// //               ..setLooping(false);
// //             return Stack(
// //               //fit: StackFit.loose,
// //               //alignment: Alignment.centerRight,
// //               children: [
// //                 !controller.value.isInitialized
// //                     ? const SpinKitCircle(
// //                         color: LarosaColors.primary,
// //                       )
// //                     : GestureDetector(
// //                         onTap: () async {
// //                           setState(() {
// //                             snippets[index]['liked'] =
// //                                 !snippets[index]['liked'];

// //                             if (snippets[index]['liked']) {
// //                               likesCount = likesCount++;
// //                             } else {
// //                               likesCount = likesCount--;
// //                             }
// //                           });

// //                           await _likePost(
// //                             snippets[index]['id'],
// //                             index,
// //                           );
// //                         },
// //                         child: Center(
// //                           child: AspectRatio(
// //                             aspectRatio: controller.value.aspectRatio,
// //                             child: GestureDetector(
// //                               onTap: () {
// //                                 controller.pause();
// //                               },
// //                               child: Stack(
// //                                 alignment: Alignment.center,
// //                                 children: [
// //                                   //VideoPlayer(controller),
// //                                   CachedVideoPlayerPlus(controller),
// //                                 ],
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                 Positioned(
// //                   bottom: 0,
// //                   child: Container(
// //                     height: 100,
// //                     width: MediaQuery.of(context).size.width,
// //                     decoration: const BoxDecoration(
// //                       gradient: LinearGradient(
// //                         colors: [
// //                           Colors.black54,
// //                           Colors.transparent,
// //                         ],
// //                         begin: Alignment.bottomCenter,
// //                         end: Alignment.topCenter,
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 Positioned(
// //                   bottom: 10,
// //                   left: 5,
// //                   right: 5,
// //                   child: Container(
// //                     padding: const EdgeInsets.all(1.0),
// //                     decoration: BoxDecoration(
// //                       //ipe gradient kama background za kwenye posts
// //                       color: Colors.black.withOpacity(
// //                           0.6), // Black background with 60% opacity
// //                       borderRadius: BorderRadius.circular(
// //                           10), // Rounded corners for the background
// //                     ),
// //                     child: Row(
// //                       crossAxisAlignment: CrossAxisAlignment.end,
// //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                       children: [
// //                         Column(
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             Row(
// //                               children: [
// //                                 snippets[index]['profile_picture'] == null
// //                                     ? ClipOval(
// //                                         child: Image.asset(
// //                                           'assets/images/EXPLORE.png',
// //                                           height: 30,
// //                                           width: 30,
// //                                           fit: BoxFit.cover,
// //                                         ),
// //                                       )
// //                                     : CircleAvatar(
// //                                         backgroundImage:
// //                                             CachedNetworkImageProvider(
// //                                           snippets[index]['profile_picture'],
// //                                         ),
// //                                       ),
// //                                 const Gap(10),
// //                                 Column(
// //                                   crossAxisAlignment: CrossAxisAlignment.start,
// //                                   children: [
// //                                     // https://storage.googleapis.com/explore-test-1/reels/post_16_2024_8_25_19_40_29_2.mp4
// //                                     // SizedBox(
// //                                     //   width: 300,
// //                                     //   child: Text(
// //                                     //     '${snippets[index]['names']}',
// //                                     //     overflow: TextOverflow.visible, // Allows the text to wrap
// //                                     //     softWrap: true, // Ensures the text wraps if it exceeds the width
// //                                     //     maxLines: null, // Allows for unlimited lines
// //                                     //     style: TextStyle(
// //                                     //       // Add any styles you prefer
// //                                     //     ),
// //                                     //   ),
// //                                     // ),
// //                                     Text(snippets[index]['name']),
// //                                     Text(
// //                                       '${snippets[index]['duration']}',
// //                                       style: Theme.of(context)
// //                                           .textTheme
// //                                           .bodySmall!
// //                                           .copyWith(fontSize: 12),
// //                                     ),
// //                                   ],
// //                                 ),
// //                               ],
// //                             ),
// //                             const Gap(5),
// //                             SizedBox(
// //                               width: MediaQuery.of(context).size.width * .80,
// //                               child: Text(
// //                                 EmojiParser().emojify(
// //                                   snippets[index]['caption'],
// //                                 ),
// //                                 style: Theme.of(context)
// //                                     .textTheme
// //                                     .bodySmall!
// //                                     .copyWith(color: LarosaColors.light),
// //                                 overflow: TextOverflow.ellipsis,
// //                                 maxLines: 40,
// //                               ),
// //                             ),
// //                             Positioned(
// //                               bottom: 20,
// //                               left: 10,
// //                               child: ValueListenableBuilder<double>(
// //                                 valueListenable: _progressIndicators[index],
// //                                 builder: (context, value, child) {
// //                                   return Container(
// //                                     width: MediaQuery.of(context).size.width -
// //                                         20, // Adjusted width for a smaller slider
// //                                     padding: const EdgeInsets.symmetric(
// //                                         horizontal: 0),
// //                                     child: SliderTheme(
// //                                       data: SliderTheme.of(context).copyWith(
// //                                         trackHeight:
// //                                             2.0, // Reduce the height of the track
// //                                         thumbShape: const RoundSliderThumbShape(
// //                                             enabledThumbRadius:
// //                                                 6.0), // Reduce the thumb size
// //                                         overlayShape: const RoundSliderOverlayShape(
// //                                             overlayRadius:
// //                                                 12.0), // Control the thumb hover size
// //                                       ),
// //                                       child: Slider(
// //                                         value: value,
// //                                         min: 0.0,
// //                                         max: 1.0,
// //                                         onChanged: (newValue) {
// //                                           _seekToPosition(index, newValue);
// //                                         },
// //                                         activeColor: LarosaColors.grey,
// //                                         inactiveColor: Colors.grey,
// //                                       ),
// //                                     ),
// //                                   );
// //                                 },
// //                               ),
// //                             )
// //                           ],
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ),
// //                 // Positioned(
// //                 //   bottom: 0,
// //                 //   left: 0,
// //                 //   right: 0,
// //                 //   child: ValueListenableBuilder<double>(
// //                 //     valueListenable: _progressIndicators[index],
// //                 //     builder: (context, value, child) {
// //                 //       return LinearProgressIndicator(
// //                 //         value: value,
// //                 //         backgroundColor: Theme.of(context).colorScheme.primary,
// //                 //         valueColor: AlwaysStoppedAnimation<Color>(
// //                 //           Theme.of(context).colorScheme.secondaryContainer,
// //                 //         ),
// //                 //       );
// //                 //     },
// //                 //   ),
// //                 // ),
// //                 Positioned.directional(
// //                   textDirection: TextDirection.ltr,
// //                   child: IconButton(
// //                     onPressed: _togglePlayPause,
// //                     icon: _isPaused
// //                         ? const Icon(
// //                             Iconsax.play,
// //                           )
// //                         : const SizedBox.shrink(),
// //                   ),
// //                 ),
// //                 Positioned(
// //                   bottom: 0,
// //                   top: 0,
// //                   right: 5,
// //                   child: Container(
// //                     alignment: Alignment.center,
// //                     child: ClipRRect(
// //                       borderRadius: BorderRadius.circular(20),
// //                       child: BackdropFilter(
// //                         filter: ImageFilter.blur(
// //                           sigmaX: 1,
// //                           sigmaY: 1,
// //                         ),
// //                         child: Container(
// //                           padding: const EdgeInsets.all(8),
// //                           color: Colors.black.withOpacity(.2),
// //                           child: Column(
// //                             mainAxisAlignment: MainAxisAlignment.center,
// //                             mainAxisSize: MainAxisSize.min,
// //                             crossAxisAlignment: CrossAxisAlignment.center,
// //                             children: [
// //                               Column(
// //                                 children: [
// //                                   IconButton(
// //                                     onPressed: () async {
// //                                       print('likes count: $likesCount');

// //                                       setState(() {
// //                                         snippets[index]['liked'] =
// //                                             !snippets[index]['liked'];

// //                                         if (snippets[index]['liked']) {
// //                                           likesCount = likesCount + 1;
// //                                           print('adding: $likesCount');
// //                                         } else {
// //                                           likesCount = likesCount - 1;
// //                                           print('minusing: $likesCount');
// //                                         }
// //                                       });

// //                                       print('likes count: $likesCount');

// //                                       await _likePost(
// //                                         snippets[index]['id'],
// //                                         index,
// //                                       );
// //                                     },
// //                                     icon: snippets[index]['liked']
// //                                         ? SvgPicture.asset(
// //                                             'assets/icons/SolarHeartAngleBold.svg',
// //                                             width: 25,
// //                                             height: 25,
// //                                             colorFilter: const ColorFilter.mode(
// //                                               Colors.red,
// //                                               BlendMode.srcIn,
// //                                             ),
// //                                             semanticsLabel: 'Like icon',
// //                                           )
// //                                         : SvgPicture.asset(
// //                                             "assets/icons/SolarHeartAngleLinear.svg",
// //                                             width: 25,
// //                                             height: 25,
// //                                             colorFilter: ColorFilter.mode(
// //                                               Theme.of(context)
// //                                                   .colorScheme
// //                                                   .secondary,
// //                                               BlendMode.srcIn,
// //                                             ),
// //                                             semanticsLabel: 'Like icon',
// //                                           ),
// //                                   ),
// //                                   Text(
// //                                     likesCount.toString(),
// //                                     style: Theme.of(context)
// //                                         .textTheme
// //                                         .bodySmall!
// //                                         .copyWith(
// //                                           fontSize: 15,
// //                                         ),
// //                                   )
// //                                 ],
// //                               ),

// //                               // favourite
// //                               Column(
// //                                 children: [
// //                                   IconButton(
// //                                       onPressed: () async {
// //                                         await _favouritePost(
// //                                             snippets[index]['id']);
// //                                       },
// //                                       icon: SvgPicture.asset(
// //                                         !snippets[index]['favorite']
// //                                             ? SvgIconsPaths.starOutline
// //                                             : SvgIconsPaths.starBold,
// //                                         width: 25,
// //                                         height: 25,
// //                                         colorFilter: ColorFilter.mode(
// //                                           snippets[index]['favorite']
// //                                               ? LarosaColors.gold
// //                                               : Theme.of(context)
// //                                                   .colorScheme
// //                                                   .secondary,
// //                                           BlendMode.srcIn,
// //                                         ),
// //                                         semanticsLabel: 'Star icon',
// //                                       )),
// //                                   Text(
// //                                     snippets[index]['favorites'].toString(),
// //                                     style: Theme.of(context)
// //                                         .textTheme
// //                                         .bodySmall!
// //                                         .copyWith(
// //                                           fontSize: 15,
// //                                         ),
// //                                   )
// //                                 ],
// //                               ),
// //                               // comment
// //                               Column(
// //                                 children: [
// //                                   IconButton(
// //                                     onPressed: () {
// //                                       // Get.bottomSheet(
// //                                       //   backgroundColor: Theme.of(context)
// //                                       //       .scaffoldBackgroundColor,
// //                                       //   isScrollControlled: true,
// //                                       //   enableDrag: true,
// //                                       //   CommentSection(
// //                                       //     postId: snippets[index]['id'],
// //                                       //   ),
// //                                       // );
// //                                     },
// //                                     icon: Icon(
// //                                       Iconsax.message,
// //                                       color: Theme.of(context)
// //                                           .colorScheme
// //                                           .secondary,
// //                                     ),
// //                                   ),
// //                                   Text(
// //                                     snippets[index]['comments'].toString(),
// //                                     style: Theme.of(context)
// //                                         .textTheme
// //                                         .bodySmall!
// //                                         .copyWith(
// //                                           fontSize: 15,
// //                                         ),
// //                                   )
// //                                 ],
// //                               ),
// //                               // Sharea
// //                               Column(
// //                                 children: [
// //                                   IconButton(
// //                                     onPressed: () {
// //                                       HelperFunctions.shareLink(
// //                                           '/post/${snippets[index]['id']}');
// //                                     },
// //                                     icon: SvgPicture.asset(
// //                                       'assets/svg_icons/share.svg',
// //                                       width: 25,
// //                                       height: 25,
// //                                       colorFilter: ColorFilter.mode(
// //                                         Theme.of(context).colorScheme.secondary,
// //                                         BlendMode.srcIn,
// //                                       ),
// //                                       semanticsLabel: 'Like icon',
// //                                     ),
// //                                   ),
// //                                   Text(
// //                                     snippets[index]['shares'].toString(),
// //                                     style: Theme.of(context)
// //                                         .textTheme
// //                                         .bodySmall!
// //                                         .copyWith(
// //                                           fontSize: 15,
// //                                         ),
// //                                   )
// //                                 ],
// //                               ),
// //                             ],
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             );
// //           }),
// //     );
// //   }

// //   void _onLoadMoreVideos() {
// //     // Load More Videos
// //   }

// //   void _updateProgress(CachedVideoPlayerPlusController controller) {
// //     int controllerIndex = _controllers.indexOf(controller);
// //     if (controllerIndex == -1) {
// //       return;
// //     }
// //     final progress = controller.value.position.inMilliseconds /
// //         controller.value.duration.inMilliseconds;
// //     _progressIndicators[controllerIndex].value = progress;
// //   }
// // }

// import 'dart:convert';
// import 'dart:ui';
// import 'package:cached_video_player_plus/cached_video_player_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter_emoji/flutter_emoji.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:gap/gap.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:http/http.dart' as http;
// import 'package:larosa_block/Services/auth_service.dart';
// import 'package:larosa_block/Utils/colors.dart';
// import 'package:larosa_block/Utils/helpers.dart';
// import 'package:larosa_block/Utils/links.dart';
// import 'package:larosa_block/Utils/svg_paths.dart';
// import 'package:like_button/like_button.dart';
// import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

// import '../Feeds/Components/carousel.dart';
// import '../Feeds/Components/comments_component.dart';

// class DeReelsScreen extends StatefulWidget {
//   const DeReelsScreen({super.key});

//   @override
//   State<DeReelsScreen> createState() => _DeReelsScreenState();
// }

// class _DeReelsScreenState extends State<DeReelsScreen> {
//   final PageController _pageController = PageController();
//   final List<CachedVideoPlayerPlusController> _controllers =
//       []; // Declare _controllers
//   List<Map<String, dynamic>> snippets = [];
//   bool _isLoading = true;

//   late bool _isLiked;
//   late int _likesCount;
//   double _opacity = 0.0; // For heart animation opacity
//   bool _showExplosion = false; // For explosion animation

//   @override
//   void initState() {
//     super.initState();
//     _loadSnippets();
//   }

// //   Future<void> _loadSnippets() async {
// //     String token = AuthService.getToken();
// //     final headers = {
// //       "Content-Type": "application/json",
// //       "Access-Control-Allow-Origin": "*",
// //       'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
// //     };

// //     var url = Uri.https(LarosaLinks.nakedBaseUrl, '/reels/fetch');
// //     try {
// //       final response = await http.post(
// //         url,
// //         body: jsonEncode({
// //           'profileId': AuthService.getProfileId(),
// //           'countryId': "1",
// //         }),
// //         headers: headers,
// //       );

// // // print('Response status: ${response.statusCode}');
// // // print('Response body: ${response.body}');

// //       if (response.statusCode == 200) {
// //         List<dynamic> data = json.decode(response.body);
// //         setState(() {
// //           snippets = data.cast<
// //               Map<String, dynamic>>(); // Properly casting to the required type
// //           _isLoading = false;
// //         });
// //       } else {
// //         HelperFunctions.showToast('Cannot Load Snippets', false);
// //       }
// //     } catch (e) {
// //       HelperFunctions.displaySnackbar(
// //         'An unknown error occurred!',
// //         context,
// //         false,
// //       );
// //       setState(() {
// //         _isLoading = false;
// //       });
// //     }
// //   }

//   Future<void> _loadSnippets() async {
//     String token = AuthService.getToken();
//     final headers = {
//       "Content-Type": "application/json",
//       "Access-Control-Allow-Origin": "*",
//       'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
//     };

//     var url = Uri.https(LarosaLinks.nakedBaseUrl, '/reels/fetch');
//     try {
//       final response = await http.post(
//         url,
//         body: jsonEncode({
//           'profileId': AuthService.getProfileId(),
//           'countryId': "1",
//         }),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         List<dynamic> data = json.decode(response.body);

//         // Initialize controllers for each video
//         for (var snippet in data) {
//           final controller =
//               // ignore: deprecated_member_use
//               CachedVideoPlayerPlusController.network(snippet['names']);
//           await controller.initialize(); // Initialize the video controller
//           controller.setLooping(true); // Loop the video
//           _controllers.add(controller); // Add the controller to the list
//         }

//         setState(() {
//           snippets = data.cast<Map<String, dynamic>>(); // Store the snippets
//           _isLoading = false; // Stop the loading indicator

//           print(snippets);
//         });
//       } else {
//         HelperFunctions.showToast('Cannot Load Snippets', false);
//       }
//     } catch (e) {
//       // HelperFunctions.displaySnackbar(
//       //   'An unknown error occurred!',
//       //   context,
//       //   false,
//       // );
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _favoritePost(int postId, int index) async {
//     String token = AuthService.getToken();

//     if (token.isEmpty) {
//       // Get.snackbar('Explore Larosa', 'Please login');
//       // Get.to(const SigninScreen());
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

//       if (response.statusCode == 302) {
//         print('response: ${response.statusCode}');
//         await AuthService.refreshToken();
//         await _favoritePost(postId, index);
//       }

//       if (response.statusCode != 200) {
//         // Get.snackbar(
//         //   'Explore Larosa',
//         //   response.body,
//         // );
//         return;
//       }
//     } catch (e) {
//       // Get.snackbar('Explore Larosa', 'An unknown error occurred');
//     }
//   }

//   // Future<void> _likePost(int postId, int index) async {
//   //   String token = AuthService.getToken();

//   //   if (token.isEmpty) {
//   //     // Get.snackbar('Explore Larosa', 'Please login');
//   //     // Get.to(const SigninScreen());
//   //     return;
//   //   }

//   //   final headers = {
//   //     "Content-Type": "application/json",
//   //     'Authorization': 'Bearer $token',
//   //   };

//   //   var url = Uri.https(LarosaLinks.nakedBaseUrl, '/like/save');

//   //   try {
//   //     final response = await http.post(
//   //       url,
//   //       body: jsonEncode({
//   //         "likerId": AuthService.getProfileId(),
//   //         "postId": postId,
//   //       }),
//   //       headers: headers,
//   //     );

//   //     if (response.statusCode == 200) {
//   //     } else if (response.statusCode == 302 || response.statusCode == 403) {
//   //       await AuthService.refreshToken();
//   //       await _likePost(postId, index);
//   //       return;
//   //     } else {
//   //       // Get.snackbar('Explore Larosa', 'Error occured');
//   //     }
//   //   } catch (e) {
//   //     //HelperFunctions.displaySnackbar('An unknown error occurred');
//   //   }
//   // }

//   void toggleLike(int index) {
//     setState(() {
//       // Toggle like state and update like count
//       snippets[index]['liked'] = !snippets[index]['liked'];
//       snippets[index]['likes'] += snippets[index]['liked'] ? 1 : -1;

//       // Trigger animations
//       _opacity = 1.0;
//       _showExplosion = true;
//     });

//     // Reset animations after a delay
//     Future.delayed(const Duration(milliseconds: 1300), () {
//       setState(() {
//         _opacity = 0.0;
//         _showExplosion = false;
//       });
//     });
//   }

//   Future<void> _updateFavoriteInBackend(
//       int postId, int index, bool previousState) async {
//     try {
//       await _favoritePost(postId, index);
//     } catch (e) {
//       // Revert the UI state if the backend fails
//       setState(() {
//         snippets[index]['favorite'] = previousState; // Revert to previous state
//         snippets[index]['favorites'] += previousState ? 1 : -1; // Revert count
//       });

//       // Optionally show an error message to the user
//       HelperFunctions.showToast(
//           "Failed to update favorite. Please try again.", false);
//     }
//   }

//   @override
//   void dispose() {
//     for (var controller in _controllers) {
//       controller.dispose(); // Dispose of controllers
//     }
//     _pageController.dispose(); // Dispose of PageController
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       body: Stack(
//         children: [
//           _isLoading
//               ? const Center(
//                   child: SpinKitCircle(
//                     color: LarosaColors.primary,
//                   ),
//                 )
//               : Container(
//                   color: Theme.of(context).scaffoldBackgroundColor,
//                   // child: PageView.builder(
//                   //   controller: _pageController,
//                   //   itemCount: snippets.length,
//                   //   scrollDirection: Axis.vertical,
//                   //   itemBuilder: (context, index) {
//                   //     final snippet = snippets[index];
//                   //     return Stack(
//                   //       children: [
//                   //         CenterSnapCarousel(
//                   //           mediaUrls: [snippet['names']],
//                   //           isPlayingState: true,
//                   //           postHeight: MediaQuery.of(context).size.height,
//                   //         ),
//                   //         _postInteracts(snippets[index], snippet['id'], snippet['name'], snippet['duration'], snippet['caption'], snippet['liked'],snippet['likes'], snippet['favorite'] , snippet['favorites'],  )
//                   //         ]
//                   //     );
//                   //   },
//                   // ),

//                   child: PageView.builder(
//                     controller: _pageController,
//                     itemCount: _controllers.length,
//                     scrollDirection: Axis.vertical,
//                     onPageChanged: (index) {
//                       // Pause all controllers except the current one
//                       for (int i = 0; i < _controllers.length; i++) {
//                         if (i == index) {
//                           _controllers[i].play(); // Play the current video
//                         } else {
//                           _controllers[i].pause(); // Pause other videos
//                         }
//                       }
//                     },
//                     itemBuilder: (context, index) {
//                       final controller = _controllers[index];

//                       return Stack(
//                         children: [
//                           !controller.value.isInitialized
//                               ? const Center(
//                                   child: SpinKitCircle(
//                                     color: LarosaColors.primary,
//                                   ),
//                                 )
//                               : GestureDetector(
//                                   onTap: () {
//                                     // Toggle play/pause on tap
//                                     if (controller.value.isPlaying) {
//                                       controller.pause();
//                                     } else {
//                                       controller.play();
//                                     }
//                                     setState(() {}); // Update UI state
//                                   },
//                                   child: Center(
//                                     child: AspectRatio(
//                                       aspectRatio: controller.value.aspectRatio,
//                                       child: CachedVideoPlayerPlus(controller),
//                                     ),
//                                   ),
//                                 ),

//                           // Slider Timeline
//                           Positioned(
//                             bottom: 20, // Adjust based on layout
//                             left: 20,
//                             right: 20,
//                             child: ValueListenableBuilder(
//                               valueListenable: controller, // Listen for updates
//                               builder: (context, value, child) {
//                                 if (!controller.value.isInitialized) {
//                                   return const SizedBox.shrink();
//                                 }
//                                 return Slider(
//                                   value: controller
//                                       .value.position.inMilliseconds
//                                       .toDouble(),
//                                   max: controller.value.duration.inMilliseconds
//                                       .toDouble(),
//                                   activeColor: Colors.red,
//                                   inactiveColor: Colors.grey,
//                                   onChanged: (value) {
//                                     controller.seekTo(Duration(
//                                         milliseconds: value.toInt())); // Seek
//                                   },
//                                 );
//                               },
//                             ),
//                           ),

//                           // Interaction Buttons (like, favorite, etc.)
//                           // _postInteracts(
//                           //   snippets[
//                           //       index], // Pass the entire snippet for reference
//                           //   snippets[index]['id'], // Extract the postId
//                           //   snippets[index]['name'], // Extract the name
//                           //   snippets[index]['duration'], // Extract the duration
//                           //   snippets[index]['caption'], // Extract the caption
//                           //   snippets[index]['liked'], // Extract the liked state
//                           //   snippets[index]
//                           //       ['likes'], // Extract the number of likes
//                           //   snippets[index]
//                           //       ['favorite'], // Extract the favorite state
//                           //   snippets[index][
//                           //       'favorites'], // Extract the number of favorites
//                           //   controller, // Pass the corresponding video controller
//                           // ),
//                         ],
//                       );
//                     },
//                   ),
//                 ),
//         ],
//       ),
//     );
//   }

// //   Widget _postInteracts(
// //   Map<String, dynamic> snippet,
// //   int postId,
// //   String name,
// //   String duration,
// //   String caption,
// //   bool liked,
// //   int likes,
// //   bool favorite,
// //   int favorites,
// // ) {
// //   return Positioned(
// //     bottom: MediaQuery.of(context).size.height / 2 - 100, // Centered with offset
// //     right: 15.0,
// //     child: Container(
// //       padding: const EdgeInsets.all(10.0),
// //       decoration: BoxDecoration(
// //         color: Colors.black.withOpacity(0.6), // Black with light opacity
// //         borderRadius: BorderRadius.circular(10.0),
// //       ),
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.end,
// //         children: [
// //           // Like Button with Count Below
// //           Column(
// //             children: [
// //               LikeButton(
// //                 size: 30.0,
// //                 isLiked: liked,
// //                 // likeCount: likes,
// //                 animationDuration: const Duration(milliseconds: 500),
// //                 bubblesColor: const BubblesColor(
// //                   dotPrimaryColor: Color.fromRGBO(180, 23, 12, 1),
// //                   dotSecondaryColor: Colors.orange,
// //                 ),
// //                 circleColor: const CircleColor(
// //                   start: Color.fromRGBO(255, 204, 0, 1),
// //                   end: Color.fromRGBO(180, 23, 12, 1),
// //                 ),
// //                 likeBuilder: (bool isLiked) {
// //                   return SvgPicture.asset(
// //                     isLiked
// //                         ? 'assets/icons/SolarHeartAngleBold.svg'
// //                         : 'assets/icons/SolarHeartAngleLinear.svg',
// //                     width: 30,
// //                     height: 30,
// //                     colorFilter: ColorFilter.mode(
// //                       isLiked
// //                           ? const Color.fromRGBO(180, 23, 12, 1)
// //                           : Colors.white,
// //                       BlendMode.srcIn,
// //                     ),
// //                   );
// //                 },
// //                 onTap: (bool isLiked) async {
// //                   toggleLike(snippets.indexOf(snippet));
// //                   return !isLiked;
// //                 },
// //               ),
// //               const SizedBox(height: 5),
// //               Text(
// //                 likes.toString(),
// //                 style: const TextStyle(color: Colors.white, fontSize: 12),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 20),

// //           // Favorite Button with Count Below
// //           Column(
// //             children: [
// //               LikeButton(
// //   size: 30.0,
// //   isLiked: favorite, // Use the current `favorite` state
// //   animationDuration: const Duration(milliseconds: 500),
// //   bubblesColor: const BubblesColor(
// //     dotPrimaryColor: Color.fromRGBO(255, 215, 0, 1),
// //     dotSecondaryColor: Colors.orange,
// //   ),
// //   circleColor: const CircleColor(
// //     start: Color.fromRGBO(255, 223, 0, 1),
// //     end: Color.fromRGBO(255, 215, 0, 1),
// //   ),
// //   likeBuilder: (bool isFavorite) {
// //     return SvgPicture.asset(
// //       isFavorite
// //           ? SvgIconsPaths.starBold
// //           : SvgIconsPaths.starOutline,
// //       width: 30,
// //       height: 30,
// //       colorFilter: ColorFilter.mode(
// //         isFavorite ? LarosaColors.gold : Colors.white,
// //         BlendMode.srcIn,
// //       ),
// //     );
// //   },
// //   onTap: (bool isFavorite) async {
// //     // Trigger animation and update UI state
// //     setState(() {
// //       snippet['favorite'] = !isFavorite; // Toggle favorite state
// //       snippet['favorites'] += isFavorite ? -1 : 1; // Adjust count
// //     });

// //     // Backend update handled asynchronously
// //     _updateFavoriteInBackend(postId, snippets.indexOf(snippet), isFavorite);

// //     return !isFavorite; // Return the new favorite state
// //   },
// // ),

// //               const SizedBox(height: 5),
// //               Text(
// //                 favorites.toString(),
// //                 style: const TextStyle(color: Colors.white, fontSize: 12),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 20),

// //           // Comment Button with Count Below
// //           Column(
// //             children: [
// //               IconButton(
// //                 onPressed: () {
// //                   showMaterialModalBottomSheet(
// //                     context: context,
// //                     builder: (BuildContext context) => Container(
// //                       constraints: const BoxConstraints(minHeight: 200),
// //                       child: CommentSection(
// //                         postId: postId,
// //                         names: name,
// //                       ),
// //                     ),
// //                   );
// //                 },
// //                 icon: const Icon(
// //                   Iconsax.message,
// //                   color: Colors.white,
// //                   size: 25,
// //                 ),
// //               ),
// //               Text(
// //                 snippet['comments'].toString(),
// //                 style: const TextStyle(color: Colors.white, fontSize: 12),
// //               ),
// //             ],
// //           ),
// //           const SizedBox(height: 20),

// //           // Share Button with Count Below (optional if needed)
// //           Column(
// //             children: [
// //               IconButton(
// //                 onPressed: () {
// //                   HelperFunctions.shareLink(postId.toString());
// //                 },
// //                 icon: SvgPicture.asset(
// //                   'assets/svg_icons/share.svg',
// //                   colorFilter: const ColorFilter.mode(
// //                     Colors.white,
// //                     BlendMode.srcIn,
// //                   ),
// //                   height: 25,
// //                 ),
// //               ),
// //               const SizedBox(height: 5),
// //               // Optional: If a share count exists, you can show it here.
// //               const Text(
// //                 'Share', // Example text or count
// //                 style: TextStyle(color: Colors.white, fontSize: 12),
// //               ),
// //             ],
// //           ),
// //         ],
// //       ),
// //     ),
// //   );
// // }

//   Widget _postInteracts(
//     Map<String, dynamic> snippet,
//     int postId,
//     String name,
//     String duration,
//     String caption,
//     bool liked,
//     int likes,
//     bool favorite,
//     int favorites,
//     CachedVideoPlayerPlusController controller,
//   ) {
//     return Positioned(
//       bottom: 0, // Place it at the bottom of the screen
//       left: 0,
//       right: 0,
//       child: Column(
//         children: [
//           // Video Controls
//           Container(
//             color: Colors.black.withOpacity(0.5), // Semi-transparent background
//             padding: const EdgeInsets.all(8.0),
//             child: SliderTheme(
//               data: SliderTheme.of(context).copyWith(
//                 trackHeight: 4.0,
//                 thumbShape:
//                     const RoundSliderThumbShape(enabledThumbRadius: 8.0),
//                 overlayShape:
//                     const RoundSliderOverlayShape(overlayRadius: 14.0),
//                 thumbColor: Colors.white,
//                 activeTrackColor: Colors.red,
//                 inactiveTrackColor: Colors.white38,
//               ),
//               child: ValueListenableBuilder(
//                 valueListenable:
//                     controller, // Listen to video controller changes
//                 builder: (context, videoValue, child) {
//                   if (!controller.value.isInitialized) {
//                     return const SizedBox.shrink();
//                   }

//                   return Slider(
//                     value: controller.value.position.inSeconds.toDouble(),
//                     min: 0.0,
//                     max: controller.value.duration.inSeconds.toDouble(),
//                     onChanged: (value) {
//                       controller.seekTo(Duration(seconds: value.toInt()));
//                     },
//                   );
//                 },
//               ),
//             ),
//           ),

//           // Post Interaction Buttons
//           _interactionButtons(
//               snippet, postId, likes, liked, favorite, favorites),
//         ],
//       ),
//     );
//   }

//   Widget _interactionButtons(Map<String, dynamic> snippet, int postId,
//       int likes, bool liked, bool favorite, int favorites) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 16.0),
//       decoration: BoxDecoration(
//         color: Colors.black.withOpacity(0.6),
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Like Button with Count
//           LikeButton(
//             isLiked: liked,
//             likeCount: likes,
//             onTap: (isLiked) async {
//               toggleLike(snippets.indexOf(snippet));
//               return !isLiked;
//             },
//           ),
//           const SizedBox(height: 16.0),
//           // Favorite Button with Count
//           LikeButton(
//             isLiked: favorite,
//             likeCount: favorites,
//             onTap: (isFavorite) async {
//               _updateFavoriteInBackend(
//                   postId, snippets.indexOf(snippet), favorite);
//               return !isFavorite;
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
