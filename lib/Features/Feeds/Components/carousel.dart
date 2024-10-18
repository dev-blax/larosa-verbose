import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:video_player/video_player.dart';
import 'package:mime/mime.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';

class CenterSnapCarousel extends StatefulWidget {
  final List<String> mediaUrls;

  const CenterSnapCarousel({super.key, required this.mediaUrls});

  @override
  State<CenterSnapCarousel> createState() => _CenterSnapCarouselState();
}

class _CenterSnapCarouselState extends State<CenterSnapCarousel> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, CachedVideoPlayerPlusController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
        controller.value.isPlaying ? controller.pause() : controller.play();
      });
    }
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

            if (_isVideo(url)) {
              if (!_videoControllers.containsKey(index)) {
                _videoControllers[index] =
                    // VideoPlayerController.networkUrl(Uri.parse(url))
                    //   ..initialize().then((_) {
                    //     setState(() {});
                    //     _videoControllers[index]!.pause();
                    //   });
                  CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
                   ..initialize().then((_) {
                        setState(() {});
                        _videoControllers[index]!.pause();
                      });
                    
              }
              final controller = _videoControllers[index]!;

              return Stack(
                alignment: Alignment.centerRight,
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
                          : Center(
                              child: Image.asset(
                                'assets/gifs/loader.gif',
                                width: MediaQuery.of(context).size.width,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  if (controller.value.isInitialized)
                    GestureDetector(
  onTap: () => _togglePlayPause(index),
  child: Padding(
    padding: const EdgeInsets.only(right:6.0),
    child: Icon(
      controller.value.isPlaying
          ? CupertinoIcons.pause
          : CupertinoIcons.play,
      size: 30.0, // Adjust the size to fit nicely within the container
      color: Colors.white.withOpacity(0.7),
    ),
  ),
)

                ],
              );
            } else {
              return ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 600,
                ),
                child: CachedNetworkImage(
                  width: MediaQuery.of(context).size.width,
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: Image.asset(
                      'assets/gifs/loader.gif',
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                    ),
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
