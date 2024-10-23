// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:mime/mime.dart';
// import 'package:cached_video_player_plus/cached_video_player_plus.dart';
// import 'package:shimmer/shimmer.dart';

// class CenterSnapCarousel extends StatefulWidget {
//   final List<String> mediaUrls;

//   const CenterSnapCarousel({super.key, required this.mediaUrls});

//   @override
//   State<CenterSnapCarousel> createState() => _CenterSnapCarouselState();
// }

// class _CenterSnapCarouselState extends State<CenterSnapCarousel> {
//   final ScrollController _scrollController = ScrollController();
//   final Map<int, CachedVideoPlayerPlusController> _videoControllers = {};
//   final Map<int, double> _heights = {}; // Store heights of each media item

//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
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

//   void _onScroll() {
//     setState(() {});
//   }

//   bool _isVideo(String url) {
//     final mimeType = lookupMimeType(url);
//     return mimeType != null && mimeType.startsWith('video/');
//   }

//   void _togglePlayPause(int index) {
//     final controller = _videoControllers[index];
//     if (controller != null) {
//       setState(() {
//         controller.value.isPlaying ? controller.pause() : controller.play();
//       });
//     }
//   }

//   Future<void> _calculateMediaHeights() async {
//     for (int i = 0; i < widget.mediaUrls.length; i++) {
//       String url = widget.mediaUrls[i];
//       if (!_isVideo(url)) {
//         // For images
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
//             // print('Calculated height of image at index $i: $calculatedHeight');
//             completer.complete();
//           }),
//         );
//         await completer.future;
//       } else {
//         // For videos
//         _videoControllers[i] =
//             CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
//               ..initialize().then((_) {
//                 final double aspectRatio =
//                     _videoControllers[i]!.value.aspectRatio;
//                 // ignore: use_build_context_synchronously
//                 final double calculatedHeight =
//                     MediaQuery.of(context).size.width / aspectRatio;
//                 setState(() {
//                   _heights[i] = calculatedHeight;
//                 });
//                 // print('Calculated height of video at index $i: $calculatedHeight');
//               }).catchError((error) {
//                 // print('Error initializing video at index $i: $error');
//               });
//       }
//     }
//   }

//   Widget _buildShimmerLoader(double width, double height) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[800]!,
//       highlightColor: Colors.grey[500]!,
//       child: Container(
//         width: width,
//         height: height,
//         color: Colors.grey[300],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onPanEnd: (_) {},
//       child: SingleChildScrollView(
//         controller: _scrollController,
//         scrollDirection: Axis.horizontal,
//         physics: CustomSnapScrollPhysics(
//           itemWidth: MediaQuery.of(context).size.width,
//         ),
//         child: Row(
//           children: widget.mediaUrls.map((url) {
//             final index = widget.mediaUrls.indexOf(url);

//             double calculatedHeight = _heights[index] ??
//                 MediaQuery.of(context).size.width /
//                     (16 / 9); // Default height if not yet calculated

//             if (_isVideo(url)) {
//               if (!_videoControllers.containsKey(index)) {
//                 _videoControllers[index] =
//                     CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
//                       ..initialize().then((_) {
//                         setState(() {});
//                         _videoControllers[index]!.pause();
//                       }).catchError((error) {
//                         print(
//                             'Error initializing video at index $index: $error');
//                       });
//               }
//               final controller = _videoControllers[index]!;

//               return Stack(
//                 alignment: Alignment.centerRight,
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
//                     GestureDetector(
//                       onTap: () => _togglePlayPause(index),
//                       child: Padding(
//                         padding: const EdgeInsets.only(right: 6.0),
//                         child: Icon(
//                           controller.value.isPlaying
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
// }

// class CustomSnapScrollPhysics extends ScrollPhysics {
//   final double itemWidth;

//   const CustomSnapScrollPhysics({super.parent, required this.itemWidth});

//   @override
//   CustomSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
//     return CustomSnapScrollPhysics(
//         parent: buildParent(ancestor), itemWidth: itemWidth);
//   }

//   double _getTargetPixels(
//       ScrollMetrics position, Tolerance tolerance, double velocity) {
//     double page = position.pixels / itemWidth;
//     if (velocity < -tolerance.velocity) {
//       page -= 0.5;
//     } else if (velocity > tolerance.velocity) {
//       page += 0.5;
//     }
//     return page.roundToDouble() * itemWidth;
//   }

//   @override
//   Simulation? createBallisticSimulation(
//       ScrollMetrics position, double velocity) {
//     if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
//       final double target = _getTargetPixels(position, tolerance, velocity);
//       return ScrollSpringSimulation(
//         spring,
//         position.pixels,
//         target.clamp(position.minScrollExtent, position.maxScrollExtent),
//         velocity,
//         tolerance: Tolerance.defaultTolerance,
//       );
//     }
//     return super.createBallisticSimulation(position, velocity);
//   }
// }


import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mime/mime.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

class CenterSnapCarousel extends StatefulWidget {
  final List<String> mediaUrls;

  const CenterSnapCarousel({super.key, required this.mediaUrls});

  @override
  State<CenterSnapCarousel> createState() => _CenterSnapCarouselState();
}

class _CenterSnapCarouselState extends State<CenterSnapCarousel> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, CachedVideoPlayerPlusController> _videoControllers = {};
  final Map<int, bool> _isPlaying = {}; // Track play/pause state for each video
  final Map<int, double> _heights = {}; // Store heights of each media item
  int? _currentlyPlayingIndex;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _calculateMediaHeights();
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

  void _onScroll() {
    setState(() {});
  }

  bool _isVideo(String url) {
    final mimeType = lookupMimeType(url);
    return mimeType != null && mimeType.startsWith('video/');
  }

  void _togglePlayPause(int index) {
    final controller = _videoControllers[index];
    if (controller != null) {
      setState(() {
        if (controller.value.isPlaying) {
          controller.pause();
          _isPlaying[index] = false;
        } else {
          controller.play();
          _isPlaying[index] = true;
        }
      });
    }
  }

  Future<void> _calculateMediaHeights() async {
  for (int i = 0; i < widget.mediaUrls.length; i++) {
    String url = widget.mediaUrls[i];
    if (!_isVideo(url)) {
      // For images
      final image = Image.network(url);
      final completer = Completer<void>();
      image.image.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) {
          final double aspectRatio = info.image.width / info.image.height;
          final double calculatedHeight = MediaQuery.of(context).size.width / aspectRatio;
          setState(() {
            _heights[i] = calculatedHeight;
          });
          completer.complete();
        }),
      );
      await completer.future;
    } else {
      // For videos
      _videoControllers[i] = CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          final double aspectRatio = _videoControllers[i]!.value.aspectRatio;
          final double calculatedHeight = MediaQuery.of(context).size.width / aspectRatio;
          setState(() {
            _heights[i] = calculatedHeight;
            _isPlaying[i] = false; // Initialize play state as false
          });
          _videoControllers[i]!.setLooping(true); // Set video to loop
        }).catchError((error) {
          print('Error initializing video at index $i: $error');
        });
    }
  }
}


  void _handleVisibilityChange(int index, double visibleFraction) {
    final controller = _videoControllers[index];

    if (controller == null) return;

    setState(() {
      if (visibleFraction > 0.5) {
        // Video is in view and should be played
        if (_currentlyPlayingIndex != index) {
          // Pause the currently playing video (if any) and play the new one
          if (_currentlyPlayingIndex != null && _videoControllers[_currentlyPlayingIndex!] != null) {
            _videoControllers[_currentlyPlayingIndex!]!.pause();
            _isPlaying[_currentlyPlayingIndex!] = false; // Update play state for paused video
          }
          controller.play();
          _isPlaying[index] = true; // Update play state for new video
          _currentlyPlayingIndex = index;
        }
      } else {
        // Video is out of view and should be paused
        if (_currentlyPlayingIndex == index) {
          controller.pause();
          _isPlaying[index] = false; // Update play state for paused video
          _currentlyPlayingIndex = null;
        }
      }
    });
  }

  Widget _buildShimmerLoader(double width, double height) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[500]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[300],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (_) {},
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: CustomSnapScrollPhysics(
          itemWidth: MediaQuery.of(context).size.width,
        ),
        child: Row(
          children: widget.mediaUrls.map((url) {
            final index = widget.mediaUrls.indexOf(url);

            double calculatedHeight =
                _heights[index] ?? MediaQuery.of(context).size.width / (16 / 9);

            if (_isVideo(url)) {
              if (!_videoControllers.containsKey(index)) {
                _videoControllers[index] = CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
                  ..initialize().then((_) {
                    setState(() {});
                    _videoControllers[index]!.pause();
                  }).catchError((error) {
                    print('Error initializing video at index $index: $error');
                  });
              }
              final controller = _videoControllers[index]!;

              return VisibilityDetector(
                key: Key('video-$index'),
                onVisibilityChanged: (info) {
                  _handleVisibilityChange(index, info.visibleFraction);
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width,
                      child: AspectRatio(
                        aspectRatio: controller.value.isInitialized
                            ? controller.value.aspectRatio
                            : 16 / 9,
                        child: controller.value.isInitialized
                            ? CachedVideoPlayerPlus(controller)
                            : _buildShimmerLoader(
                                MediaQuery.of(context).size.width,
                                calculatedHeight),
                      ),
                    ),
                    if (controller.value.isInitialized)
                      Positioned(
                        right: 10,
                        // bottom: 10,
                        child: GestureDetector(
                          onTap: () => _togglePlayPause(index),
                          child: Icon(
                            _isPlaying[index] == true
                                ? CupertinoIcons.pause
                                : CupertinoIcons.play,
                            size: 30.0,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      )
                  ],
                ),
              );
            } else {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: calculatedHeight,
                ),
                child: CachedNetworkImage(
                  width: MediaQuery.of(context).size.width,
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildShimmerLoader(
                    MediaQuery.of(context).size.width,
                    calculatedHeight,
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              );
            }
          }).toList(),
        ),
      ),
    );
  }
}

class CustomSnapScrollPhysics extends ScrollPhysics {
  final double itemWidth;

  const CustomSnapScrollPhysics({super.parent, required this.itemWidth});

  @override
  CustomSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomSnapScrollPhysics(
        parent: buildParent(ancestor), itemWidth: itemWidth);
  }

  double _getTargetPixels(
      ScrollMetrics position, Tolerance tolerance, double velocity) {
    double page = position.pixels / itemWidth;
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    return page.roundToDouble() * itemWidth;
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      final double target = _getTargetPixels(position, tolerance, velocity);
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target.clamp(position.minScrollExtent, position.maxScrollExtent),
        velocity,
        tolerance: Tolerance.defaultTolerance,
      );
    }
    return super.createBallisticSimulation(position, velocity);
  }
}
