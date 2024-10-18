import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/svg_paths.dart';

class DeReelsScreen extends StatefulWidget {
  const DeReelsScreen({super.key});

  @override
  State<DeReelsScreen> createState() => _DeReelsScreenState();
}

class _DeReelsScreenState extends State<DeReelsScreen> {
  final PageController _pageController = PageController();
  final List<CachedVideoPlayerPlusController> _controllers = [];
  final List<ValueNotifier<double>> _progressIndicators = [];
  List<Map<String, dynamic>> snippets = [];
  bool _isPaused = false;

  Future<void> _favouritePost(int postId) async {
    String token = AuthService.getToken();

    if (token.isEmpty) {
      //Get.snackbar('Explore Larosa', 'Please login');
      HelperFunctions.showToast('Please Login First', false);
      //Get.to(const SigninScreen());
      HelperFunctions.logout(context);
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

      if (response.statusCode == 302 || response.statusCode == 403) {
        await AuthService.refreshToken();
        _favouritePost(postId);
      }

      if (response.statusCode != 200) {
        // Get.snackbar(
        //   'Explore Larosa',
        //   response.body,
        // );
        HelperFunctions.showToast('Cannot Perform Action', false);
        return;
      }
    } catch (e) {
      HelperFunctions.displaySnackbar(
        'An unknown error occured',
        context,
        false,
      );
    }
  }

  Future<void> _loadSnippets() async {
  String token = AuthService.getToken();
  Map<String, String> headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
  };

  var url = Uri.https(
    LarosaLinks.nakedBaseUrl,
    '/reels/fetch',
  );
  try {
    final response = await http.post(
      url,
      body: jsonEncode({
        'profileId': AuthService.getProfileId(),
        'countryId': 1.toString(),
      }),
      headers: headers,
    );

    if (response.statusCode != 200) {
      HelperFunctions.showToast('Cannot Load Snippets', false);
      return;
    }

    List<dynamic> data = json.decode(response.body);

    for (var item in data) {
      CachedVideoPlayerPlusController controller =
          CachedVideoPlayerPlusController.networkUrl(Uri.parse(item['names']));

      try {
        await controller.initialize();
        _controllers.add(controller);
        controller.setLooping(true); // Make the video loop
        _progressIndicators.add(ValueNotifier<double>(0.0));

        controller.addListener(() {
          _updateProgress(controller);
        });

        snippets.add(item);
      } catch (e) {
        // Log or handle initialization error if needed
        print("Error initializing video: $e");
        // Dispose of the controller if initialization fails
        controller.dispose();
      }
    }

    setState(() {});
  } catch (e) {
    HelperFunctions.displaySnackbar(
      'An unknown error occurred!',
      context,
      false,
    );
  }
}


  Future<void> _likePost(int postId, int index) async {
    String token = AuthService.getToken();

    if (token.isEmpty) {
      //Get.snackbar('Explore Larosa', 'Please login');
      HelperFunctions.showToast('Login first', false);
      HelperFunctions.logout(context);
      //Get.to(const SigninScreen());
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
        setState(() {
          snippets[index]['liked'] = !snippets[index]['liked'];
        });
        //Get.snackbar('Explore Larosa', 'Error occured');
      }
    } catch (e) {
      HelperFunctions.displaySnackbar(
        'Failed to perform action...!',
        context,
        false,
      );
    }
  }

  void _seekToPosition(int index, double value) {
    final controller = _controllers[index];
    final newPosition = Duration(milliseconds: (value * controller.value.duration.inMilliseconds).toInt());
    controller.seekTo(newPosition);
  }

  @override
  void initState() {
    super.initState();
    _loadSnippets();
  }

  void _togglePlayPause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _controllers[_pageController.page!.toInt()].pause();
      } else {
        _controllers[_pageController.page!.toInt()].play();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.removeListener(() {});
      controller.dispose();
    }
    for (var progressIndicator in _progressIndicators) {
      progressIndicator.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   surfaceTintColor: Colors.transparent,
      //   elevation: 0,
      //   actions: const [],
      //   automaticallyImplyLeading: false,
      // ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
          pageSnapping: true,
          onPageChanged: (value) {
            for (var i = 0; i < _controllers.length; i++) {
              if (i != value) {
                _controllers[i].pause();
              } else {
                _controllers[i].play();
              }
            }

            if (value == _controllers.length - 1) {
              _onLoadMoreVideos();
            }
          },
          controller: _pageController,
          itemCount: _controllers.length,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            int likesCount = snippets[index]['likes'];
            final controller = _controllers[index];
            controller
              ..play()
              ..setLooping(false);
            return Stack(
              //fit: StackFit.loose,
              //alignment: Alignment.centerRight,
              children: [
                !controller.value.isInitialized
                    ? const SpinKitCircle(
                        color: LarosaColors.primary,
                      )
                    : GestureDetector(
                        onTap: () async {
                          setState(() {
                            snippets[index]['liked'] =
                                !snippets[index]['liked'];

                            if (snippets[index]['liked']) {
                              likesCount = likesCount++;
                            } else {
                              likesCount = likesCount--;
                            }
                          });

                          await _likePost(
                            snippets[index]['id'],
                            index,
                          );
                        },
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: GestureDetector(
                              onTap: () {
                                controller.pause();
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  //VideoPlayer(controller),
                                  CachedVideoPlayerPlus(controller),

                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    height: 100,
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 5,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.all(1.0),
    decoration: BoxDecoration(
      //ipe gradient kama background za kwenye posts
      color: Colors.black.withOpacity(0.6), // Black background with 60% opacity
      borderRadius: BorderRadius.circular(10), // Rounded corners for the background
    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                snippets[index]['profile_picture'] == null
                                    ? ClipOval(
                                        child: Image.asset(
                                          'assets/images/EXPLORE.png',
                                          height: 30,
                                          width: 30,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : CircleAvatar(
                                        backgroundImage:
                                            CachedNetworkImageProvider(
                                          snippets[index]['profile_picture'],
                                        ),
                                      ),
                                const Gap(10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // https://storage.googleapis.com/explore-test-1/reels/post_16_2024_8_25_19_40_29_2.mp4
                                    // SizedBox(
                                    //   width: 300,
                                    //   child: Text(
                                    //     '${snippets[index]['names']}',
                                    //     overflow: TextOverflow.visible, // Allows the text to wrap
                                    //     softWrap: true, // Ensures the text wraps if it exceeds the width
                                    //     maxLines: null, // Allows for unlimited lines
                                    //     style: TextStyle(
                                    //       // Add any styles you prefer
                                    //     ),
                                    //   ),
                                    // ),
                                    Text(snippets[index]['name']),
                                    Text(
                                      '${snippets[index]['duration']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Gap(5),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * .80,
                              child: Text(
                                EmojiParser().emojify(
                                  snippets[index]['caption'],
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(color: LarosaColors.light),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 40,
                              ),
                            ),
                    
                    Positioned(
                      bottom: 20,
                      left: 10,
                      child: ValueListenableBuilder<double>(
                        valueListenable: _progressIndicators[index],
                        builder: (context, value, child) {
                          return Container(
                            width: MediaQuery.of(context).size.width - 20, // Adjusted width for a smaller slider
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2.0, // Reduce the height of the track
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0), // Reduce the thumb size
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0), // Control the thumb hover size
                              ),
                              child: Slider(
                                value: value,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (newValue) {
                                  _seekToPosition(index, newValue);
                                },
                                activeColor: LarosaColors.grey,
                                inactiveColor: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                    
                    
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Positioned(
                //   bottom: 0,
                //   left: 0,
                //   right: 0,
                //   child: ValueListenableBuilder<double>(
                //     valueListenable: _progressIndicators[index],
                //     builder: (context, value, child) {
                //       return LinearProgressIndicator(
                //         value: value,
                //         backgroundColor: Theme.of(context).colorScheme.primary,
                //         valueColor: AlwaysStoppedAnimation<Color>(
                //           Theme.of(context).colorScheme.secondaryContainer,
                //         ),
                //       );
                //     },
                //   ),
                // ),
                Positioned.directional(
                  textDirection: TextDirection.ltr,
                  child: IconButton(
                    onPressed: _togglePlayPause,
                    icon: _isPaused
                        ? const Icon(
                            Iconsax.play,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  top: 0,
                  right: 5,
                  child: Container(
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 1,
                          sigmaY: 1,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.black.withOpacity(.2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      print('likes count: $likesCount');

                                      setState(() {
                                        snippets[index]['liked'] =
                                            !snippets[index]['liked'];

                                        if (snippets[index]['liked']) {
                                          likesCount = likesCount + 1;
                                          print('adding: $likesCount');
                                        } else {
                                          likesCount = likesCount - 1;
                                          print('minusing: $likesCount');
                                        }
                                      });

                                      print('likes count: $likesCount');

                                      await _likePost(
                                        snippets[index]['id'],
                                        index,
                                      );
                                    },
                                    icon: snippets[index]['liked']
                                        ? SvgPicture.asset(
                                            'assets/icons/SolarHeartAngleBold.svg',
                                            width: 25,
                                            height: 25,
                                            colorFilter: const ColorFilter.mode(
                                              Colors.red,
                                              BlendMode.srcIn,
                                            ),
                                            semanticsLabel: 'Like icon',
                                          )
                                        : SvgPicture.asset(
                                            "assets/icons/SolarHeartAngleLinear.svg",
                                            width: 25,
                                            height: 25,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              BlendMode.srcIn,
                                            ),
                                            semanticsLabel: 'Like icon',
                                          ),
                                  ),
                                  Text(
                                    likesCount.toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          fontSize: 15,
                                        ),
                                  )
                                ],
                              ),

                              // favourite
                              Column(
                                children: [
                                  IconButton(
                                      onPressed: () async {
                                        await _favouritePost(
                                            snippets[index]['id']);
                                      },
                                      icon: SvgPicture.asset(
                                        !snippets[index]['favorite']
                                            ? SvgIconsPaths.starOutline
                                            : SvgIconsPaths.starBold,
                                        width: 25,
                                        height: 25,
                                        colorFilter: ColorFilter.mode(
                                          snippets[index]['favorite']
                                              ? LarosaColors.gold
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                          BlendMode.srcIn,
                                        ),
                                        semanticsLabel: 'Star icon',
                                      )),
                                  Text(
                                    snippets[index]['favorites'].toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          fontSize: 15,
                                        ),
                                  )
                                ],
                              ),
                              // comment
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      // Get.bottomSheet(
                                      //   backgroundColor: Theme.of(context)
                                      //       .scaffoldBackgroundColor,
                                      //   isScrollControlled: true,
                                      //   enableDrag: true,
                                      //   CommentSection(
                                      //     postId: snippets[index]['id'],
                                      //   ),
                                      // );
                                    },
                                    icon: Icon(
                                      Iconsax.message,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                  ),
                                  Text(
                                    snippets[index]['comments'].toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          fontSize: 15,
                                        ),
                                  )
                                ],
                              ),
                              // Sharea
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      HelperFunctions.shareLink(
                                          '/post/${snippets[index]['id']}');
                                    },
                                    icon: SvgPicture.asset(
                                      'assets/svg_icons/share.svg',
                                      width: 25,
                                      height: 25,
                                      colorFilter: ColorFilter.mode(
                                        Theme.of(context).colorScheme.secondary,
                                        BlendMode.srcIn,
                                      ),
                                      semanticsLabel: 'Like icon',
                                    ),
                                  ),
                                  Text(
                                    snippets[index]['shares'].toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          fontSize: 15,
                                        ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }

  void _onLoadMoreVideos() {
    // Load More Videos
  }

  void _updateProgress(CachedVideoPlayerPlusController controller) {
    int controllerIndex = _controllers.indexOf(controller);
    if (controllerIndex == -1) {
      return;
    }
    final progress = controller.value.position.inMilliseconds /
        controller.value.duration.inMilliseconds;
    _progressIndicators[controllerIndex].value = progress;
  }
}
