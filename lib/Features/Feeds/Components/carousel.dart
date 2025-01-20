//SMOOTHLY SLIDING SLIDER
//BY DEFAULT CONTROLLERS TO HIDE UNTILL GENSTURE DETECTURE
//REDUCE THE WIDTH OF THE SLIDER
//SMOOTHLY SLIDING OF SLIDER ON TOUCH

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:mime/mime.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:shimmer/shimmer.dart';

class CenterSnapCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final bool isPlayingState;
  final double? postHeight;

  const CenterSnapCarousel({
    super.key,
    required this.mediaUrls,
    required this.isPlayingState,
    this.postHeight,
  });

  @override
  State<CenterSnapCarousel> createState() => _CenterSnapCarouselState();
}

class _CenterSnapCarouselState extends State<CenterSnapCarousel> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, CachedVideoPlayerPlusController> _videoControllers = {};

  final Map<int, bool> _manualControlStates =
      {}; // Track manual play/pause states
  final Map<int, Duration> _videoPositions =
      {}; // Track video positions for sliders
  final Map<int, bool> _muteStates = {}; // Track mute state for each video

  @override
  void initState() {
    super.initState();
    // _calculateMediaHeights();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _disposeVideoControllers();
    super.dispose();
  }

  void _disposeVideoControllers() {
    _videoControllers.forEach((key, controller) {
      controller.dispose();
    });
  }

  bool _isVideo(String url) {
    final mimeType = lookupMimeType(url);
    return mimeType != null && mimeType.startsWith('video/');
  }

  // Future<void> _calculateMediaHeights() async {
  //   final predefinedHeight = widget.postHeight;

  //   for (int i = 0; i < widget.mediaUrls.length; i++) {
  //     String url = widget.mediaUrls[i];

  //     // Use predefined post height for all media items in the post
  //     if (predefinedHeight != null) {
  //       _heights[i] = predefinedHeight;
  //     } else {
  //       // Calculate height only if no predefined height is given
  //       if (!_isVideo(url)) {
  //         final image = Image.network(url);
  //         final completer = Completer<void>();
  //         image.image.resolve(const ImageConfiguration()).addListener(
  //           ImageStreamListener((info, _) {
  //             final double aspectRatio = info.image.width / info.image.height;
  //             final double calculatedHeight =
  //                 MediaQuery.of(context).size.width / aspectRatio;
  //             setState(() {
  //               _heights[i] = calculatedHeight;
  //             });
  //             completer.complete();
  //           }),
  //         );
  //         await completer.future;
  //       } else {
  //         _videoControllers[i] =
  //             CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
  //               ..initialize().then((_) {
  //                 final double aspectRatio =
  //                     _videoControllers[i]!.value.aspectRatio;
  //                 final double calculatedHeight =
  //                     MediaQuery.of(context).size.width / aspectRatio;
  //                 setState(() {
  //                   _heights[i] = calculatedHeight;
  //                 });
  //                 _videoControllers[i]!.setLooping(true);
  //               });
  //       }
  //     }
  //   }
  // }

  // Future<void> _calculateMediaHeights() async {
  //   for (int i = 0; i < widget.mediaUrls.length; i++) {
  //     String url = widget.mediaUrls[i];
  //     if (!_isVideo(url)) {
  //       final image = Image.network(url);
  //       final completer = Completer<void>();
  //       image.image.resolve(const ImageConfiguration()).addListener(
  //         ImageStreamListener((info, _) {
  //           final double aspectRatio = info.image.width / info.image.height;
  //           final double calculatedHeight =
  //               MediaQuery.of(context).size.width / aspectRatio;
  //           setState(() {
  //             _heights[i] = calculatedHeight;
  //           });
  //           completer.complete();
  //         }),
  //       );
  //       await completer.future;
  //     } else {
  //       _videoControllers[i] =
  //           CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
  //             ..initialize().then((_) {
  //               final double aspectRatio =
  //                   _videoControllers[i]!.value.aspectRatio;
  //               final double calculatedHeight =
  //                   MediaQuery.of(context).size.width / aspectRatio;
  //               setState(() {
  //                 _heights[i] = calculatedHeight;
  //               });
  //               _videoControllers[i]!.setLooping(true);
  //               _addVideoListener(i);
  //               if (widget.isPlayingState == false) {
  //                 _videoControllers[i]!.pause();
  //               }
  //             }).catchError((error) {
  //               print('Error initializing video at index $i: $error');
  //             });
  //     }
  //   }
  // }

  void _addVideoListener(int index) {
    final controller = _videoControllers[index];
    if (controller != null) {
      controller.addListener(() {
        setState(() {
          _videoPositions[index] = controller.value.position;
        });
      });
    }
  }

  void _togglePlayPause(int index) {
    final controller = _videoControllers[index];
    if (controller != null) {
      setState(() {
        if (controller.value.isPlaying) {
          controller.pause();
          _manualControlStates[index] = false;
        } else {
          controller.play();
          _manualControlStates[index] = true;
        }
      });
    }
  }

  void _onSeekStart(int index) {
    final controller = _videoControllers[index];
    if (controller != null && controller.value.isPlaying) {
      controller.pause();
    }
  }

  void _onSeek(int index, double value) {
    final controller = _videoControllers[index];
    if (controller != null) {
      final newPosition = Duration(milliseconds: value.toInt());
      controller.seekTo(newPosition);
      setState(() {
        _videoPositions[index] = newPosition;
      });
    }
  }

  void _onSeekEnd(int index, double value) {
    final controller = _videoControllers[index];
    if (controller != null) {
      final newPosition = Duration(milliseconds: value.toInt());
      controller.seekTo(newPosition);
      controller.play();
      setState(() {
        _videoPositions[index] = newPosition;
      });
    }
  }

  void _toggleMute(int index) {
    final controller = _videoControllers[index];
    if (controller != null) {
      setState(() {
        _muteStates[index] = !_muteStates[index]!;
        controller.setVolume(_muteStates[index]! ? 0 : 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const offset = 0.0;
    final logicalPostHeight = ((widget.postHeight != null
                ? widget.postHeight! / MediaQuery.of(context).devicePixelRatio
                : 300.0) +
            offset)
        .clamp(0.0, MediaQuery.of(context).size.height * 0.9);

    return GestureDetector(
      onPanEnd: (_) {},
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(),
        child: Row(
          children: widget.mediaUrls.map((url) {
            final index = widget.mediaUrls.indexOf(url);

            // double calculatedHeight =
            //     _heights[index] ?? MediaQuery.of(context).size.width / (16 / 9);

            if (_isVideo(url)) {
              if (!_videoControllers.containsKey(index)) {
                _videoControllers[index] =
                    CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
                      ..initialize().then((_) {
                        setState(() {});
                        _addVideoListener(index);
                        if (widget.isPlayingState == false) {
                          _videoControllers[index]!.pause();
                        }
                      }).catchError((error) {
                        LogService.logError(
                          'Error initializing video at index $index: $error',
                        );
                      });
              }
              final controller = _videoControllers[index]!;
              _muteStates[index] = _muteStates[index] ?? false;

              if (_manualControlStates[index] == null) {
                if (widget.isPlayingState == true) {
                  controller.play();
                } else {
                  controller.pause();
                }
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: MediaQuery.of(context).size.width,
                    child: AspectRatio(
                      aspectRatio: controller.value.isInitialized
                          ? controller.value.aspectRatio
                          : 16 / 9, // Fallback aspect ratio
                      child: controller.value.isInitialized
                          ? CachedVideoPlayerPlus(controller)
                          : SizedBox(
                              height: logicalPostHeight,
                              width: MediaQuery.of(context).size.width,
                              child: _buildShimmerLoader(
                                  height: logicalPostHeight),
                            ),
                    ),
                  ),

//                   Container(
//   height: 300,
//   alignment: Alignment.center,
//   width: MediaQuery.of(context).size.width,
//   child: controller.value.isInitialized
//       ? FittedBox(
//           fit: BoxFit.cover, // Ensures the video behaves like "cover" in CSS
//           child: SizedBox(
//             width: controller.value.size.width,
//             height: controller.value.size.height,
//             child: CachedVideoPlayerPlus(controller),
//           ),
//         )
//       : _buildShimmerLoader(),
// ),

// buildMediaContainer(
//         imageUrl: null,
//         videoController: controller,
//         context: context,
//         isVideo: true,
//       ),

                  if (controller.value.isInitialized)
                    Positioned(
                      right: 5, // Align to the right
                      bottom: 100, // Adjust to be near the bottom of the video
                      child: Container(
                        padding: const EdgeInsets.all(
                            8.0), // Add padding for inner content
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.3), // Light black background
                          borderRadius:
                              BorderRadius.circular(10.0), // Rounded corners
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _toggleMute(index),
                              child: Icon(
                                _muteStates[index] == true
                                    ? CupertinoIcons.volume_off
                                    : CupertinoIcons.volume_up,
                                size: 25.0,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(
                                height:
                                    20), // Spacing between mute and play/pause
                            GestureDetector(
                              onTap: () => _togglePlayPause(index),
                              child: Icon(
                                _manualControlStates[index] == true ||
                                        (controller.value.isPlaying &&
                                            _manualControlStates[index] == null)
                                    ? CupertinoIcons.pause
                                    : CupertinoIcons.play,
                                size: 30.0,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: -5, // Maintain the position as provided
                    left: MediaQuery.of(context).size.width *
                        0.00, // Add horizontal padding
                    right: MediaQuery.of(context).size.width *
                        0.00, // Add padding on the right
                    child: Container(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(
                              0.9) // Dark background for dark theme
                          : Colors.white.withOpacity(
                              0.9), // Light background for light theme
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 1.0, // Set the thickness of the slider
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 4.0, // Reduce the thumb size
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius:
                                10.0, // Reduce the size of the overlay around the thumb
                          ),
                        ),
                        child: Slider(
                          activeColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(
                                      0.2) // Light color for dark theme
                                  : Colors.black.withOpacity(
                                      0.3), // Dark color for light theme
                          inactiveColor: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? Colors.grey[
                                  900] // Slightly lighter gray for dark theme
                              : Colors.grey[
                                  300], // Slightly darker gray for light theme
                          value: _videoPositions[index]
                                  ?.inMilliseconds
                                  .toDouble() ??
                              0.0,
                          min: 0.0,
                          max: controller.value.duration.inMilliseconds
                              .toDouble(),
                          onChangeStart: (value) => _onSeekStart(index),
                          onChanged: (value) => _onSeek(index, value),
                          onChangeEnd: (value) => _onSeekEnd(index, value),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return ConstrainedBox(
                constraints: const BoxConstraints(
                    // maxHeight: widget.postHeight ??
                    //     calculatedHeight, // Use postHeight if available, otherwise calculatedHeight
                    ),
                child: CachedNetworkImage(
                  width: MediaQuery.of(context).size.width,
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      _buildShimmerLoader(height: logicalPostHeight),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );

//               return ConstrainedBox(
//   constraints: const BoxConstraints(
//     maxHeight: 300, // Fixed height for the media container
//   ),
//   child: Container(
//     height: 300, // Explicitly set the height
//     width: MediaQuery.of(context).size.width, // Full-width
//     decoration: BoxDecoration(
//       image: DecorationImage(
//         image: CachedNetworkImageProvider(url),
//         fit: BoxFit.cover, // Ensures the image behaves like "cover" in CSS
//       ),
//     ),
//     child: CachedNetworkImage(
//       imageUrl: url,
//       placeholder: (context, url) => _buildShimmerLoader(),
//       errorWidget: (context, url, error) => const Icon(Icons.error),
//     ),
//   ),
// );
            }
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShimmerLoader({double? height}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: height ?? 300,
        color: Colors.grey[100],
      ),
    );
  }

  // Widget _buildShimmerLoader() {
  //   final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  //   return Shimmer.fromColors(
  //     baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
  //     highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
  //     child: Container(
  //       width: MediaQuery.of(context).size.width,
  //       height: 300,
  //       color: Colors.grey[100],
  //     ),
  //   );
  // }


//****//
/// A media container that handles both image and video rendering creatively
Widget buildMediaContainer({
  required String? imageUrl,
  required CachedVideoPlayerPlusController? videoController,
  required BuildContext context,
  required bool isVideo,
}) {
  const double containerHeight = 300;
  return ConstrainedBox(
    constraints: const BoxConstraints(
      maxHeight: containerHeight, // Fixed height for the media container
    ),
    child: Container(
      height: containerHeight,
      width: MediaQuery.of(context).size.width, // Full width
      decoration: isVideo
          ? null
          : BoxDecoration(
              image: imageUrl != null
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(imageUrl),
                      fit: BoxFit.cover, // Ensures the image behaves like "cover" in CSS
                    )
                  : null,
            ),
      child: isVideo
          ? videoController != null && videoController.value.isInitialized
              ? FittedBox(
                  fit: BoxFit.cover, // Ensures the video behaves like "cover" in CSS
                  child: SizedBox(
                    width: videoController.value.size.width,
                    height: videoController.value.size.height,
                    child: CachedVideoPlayerPlus(videoController),
                  ),
                )
              : _buildShimmerLoader()
          : CachedNetworkImage(
              imageUrl: imageUrl!,
              placeholder: (context, url) => _buildShimmerLoader(),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.error, size: 50, color: Colors.redAccent),
            ),
    ),
  );

}
}

// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:mime/mime.dart';
// import 'package:cached_video_player_plus/cached_video_player_plus.dart';
// import 'package:shimmer/shimmer.dart';

// class CenterSnapCarousel extends StatefulWidget {
//   final List<String> mediaUrls;
//   final bool isPlayingState;

//   const CenterSnapCarousel({
//     super.key,
//     required this.mediaUrls,
//     required this.isPlayingState,
//   });

//   @override
//   State<CenterSnapCarousel> createState() => _CenterSnapCarouselState();
// }

// class _CenterSnapCarouselState extends State<CenterSnapCarousel> {
//   final ScrollController _scrollController = ScrollController();
//   final Map<int, CachedVideoPlayerPlusController> _videoControllers = {};
//   final Map<int, double> _heights = {};
//   final Map<int, bool> _manualControlStates = {}; // Track manual play/pause states

//   @override
//   void initState() {
//     super.initState();
//     _calculateMediaHeights();
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _disposeVideoControllers();
//     super.dispose();
//   }

//   void _disposeVideoControllers() {
//     _videoControllers.forEach((key, controller) {
//       controller.dispose();
//     });
//   }

//   bool _isVideo(String url) {
//     final mimeType = lookupMimeType(url);
//     return mimeType != null && mimeType.startsWith('video/');
//   }

//   Future<void> _calculateMediaHeights() async {
//     for (int i = 0; i < widget.mediaUrls.length; i++) {
//       String url = widget.mediaUrls[i];
//       if (!_isVideo(url)) {
//         final image = Image.network(url);
//         final completer = Completer<void>();
//         image.image.resolve(const ImageConfiguration()).addListener(
//           ImageStreamListener((info, _) {
//             final double aspectRatio = info.image.width / info.image.height;
//             final double calculatedHeight =
//                 MediaQuery.of(context).size.width / aspectRatio;
//             setState(() {
//               _heights[i] = calculatedHeight;
//             });
//             completer.complete();
//           }),
//         );
//         await completer.future;
//       } else {
//         _videoControllers[i] =
//             CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
//               ..initialize().then((_) {
//                 final double aspectRatio =
//                     _videoControllers[i]!.value.aspectRatio;
//                 final double calculatedHeight =
//                     MediaQuery.of(context).size.width / aspectRatio;
//                 setState(() {
//                   _heights[i] = calculatedHeight;
//                 });
//                 _videoControllers[i]!.setLooping(true);
//                 // Pause initially if auto-play state is false
//                 if (widget.isPlayingState == false) {
//                   _videoControllers[i]!.pause();
//                 }
//               }).catchError((error) {
//                 print('Error initializing video at index $i: $error');
//               });
//       }
//     }
//   }

//   void _togglePlayPause(int index) {
//     final controller = _videoControllers[index];
//     if (controller != null) {
//       setState(() {
//         if (controller.value.isPlaying) {
//           controller.pause();
//           _manualControlStates[index] = false;
//         } else {
//           controller.play();
//           _manualControlStates[index] = true;
//         }
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onPanEnd: (_) {},
//       child: SingleChildScrollView(
//         controller: _scrollController,
//         scrollDirection: Axis.horizontal,
//         physics: const PageScrollPhysics(),
//         child: Row(
//           children: widget.mediaUrls.map((url) {
//             final index = widget.mediaUrls.indexOf(url);

//             double calculatedHeight =
//                 _heights[index] ?? MediaQuery.of(context).size.width / (16 / 9);

//             if (_isVideo(url)) {
//               if (!_videoControllers.containsKey(index)) {
//                 _videoControllers[index] =
//                     CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
//                       ..initialize().then((_) {
//                         setState(() {});
//                         if (widget.isPlayingState == false) {
//                           _videoControllers[index]!.pause();
//                         }
//                       }).catchError((error) {
//                         print(
//                             'Error initializing video at index $index: $error');
//                       });
//               }
//               final controller = _videoControllers[index]!;

//               // Automatically play or pause based on the auto-play state
//               if (_manualControlStates[index] == null) {
//                 // Only manage auto-play if manual control isn't active
//                 if (widget.isPlayingState == true) {
//                   controller.play();
//                 } else {
//                   controller.pause();
//                 }
//               }

//               return Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   Container(
//                     alignment: Alignment.center,
//                     width: MediaQuery.of(context).size.width,
//                     child: AspectRatio(
//                       aspectRatio: controller.value.isInitialized
//                           ? controller.value.aspectRatio
//                           : 16 / 9,
//                       child: controller.value.isInitialized
//                           ? CachedVideoPlayerPlus(controller)
//                           : _buildShimmerLoader(
//                               MediaQuery.of(context).size.width,
//                               calculatedHeight),
//                     ),
//                   ),
//                   if (controller.value.isInitialized)
//                     Positioned(
//                       right: 10,
//                       child: GestureDetector(
//                         onTap: () => _togglePlayPause(index),
//                         child: Icon(
//                           _manualControlStates[index] == true ||
//                                   (controller.value.isPlaying &&
//                                       _manualControlStates[index] == null)
//                               ? CupertinoIcons.pause
//                               : CupertinoIcons.play,
//                           size: 30.0,
//                           color: Colors.white.withOpacity(0.7),
//                         ),
//                       ),
//                     )
//                 ],
//               );
//             } else {
//               return ConstrainedBox(
//                 constraints: BoxConstraints(
//                   maxHeight: calculatedHeight,
//                 ),
//                 child: CachedNetworkImage(
//                   width: MediaQuery.of(context).size.width,
//                   imageUrl: url,
//                   fit: BoxFit.cover,
//                   placeholder: (context, url) => _buildShimmerLoader(
//                     MediaQuery.of(context).size.width,
//                     calculatedHeight,
//                   ),
//                   errorWidget: (context, url, error) => const Icon(Icons.error),
//                 ),
//               );
//             }
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildShimmerLoader(double width, double height) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[900]!,
//       highlightColor: Colors.grey[700]!,
//       child: Container(
//         width: width,
//         height: height,
//         color: Colors.grey[300],
//       ),
//     );
//   }
// }
