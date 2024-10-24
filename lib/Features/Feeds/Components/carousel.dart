import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mime/mime.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:shimmer/shimmer.dart';

class CenterSnapCarousel extends StatefulWidget {
  final List<String> mediaUrls;
  final bool isPlayingState;

  const CenterSnapCarousel({
    super.key,
    required this.mediaUrls,
    required this.isPlayingState,
  });

  @override
  State<CenterSnapCarousel> createState() => _CenterSnapCarouselState();
}

class _CenterSnapCarouselState extends State<CenterSnapCarousel> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, CachedVideoPlayerPlusController> _videoControllers = {};
  final Map<int, double> _heights = {};
  final Map<int, bool> _manualControlStates = {}; // Track manual play/pause states

  @override
  void initState() {
    super.initState();
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

  bool _isVideo(String url) {
    final mimeType = lookupMimeType(url);
    return mimeType != null && mimeType.startsWith('video/');
  }

  Future<void> _calculateMediaHeights() async {
    for (int i = 0; i < widget.mediaUrls.length; i++) {
      String url = widget.mediaUrls[i];
      if (!_isVideo(url)) {
        final image = Image.network(url);
        final completer = Completer<void>();
        image.image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((info, _) {
            final double aspectRatio = info.image.width / info.image.height;
            final double calculatedHeight =
                MediaQuery.of(context).size.width / aspectRatio;
            setState(() {
              _heights[i] = calculatedHeight;
            });
            completer.complete();
          }),
        );
        await completer.future;
      } else {
        _videoControllers[i] =
            CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
              ..initialize().then((_) {
                final double aspectRatio =
                    _videoControllers[i]!.value.aspectRatio;
                final double calculatedHeight =
                    MediaQuery.of(context).size.width / aspectRatio;
                setState(() {
                  _heights[i] = calculatedHeight;
                });
                _videoControllers[i]!.setLooping(true);
                // Pause initially if auto-play state is false
                if (widget.isPlayingState == false) {
                  _videoControllers[i]!.pause();
                }
              }).catchError((error) {
                print('Error initializing video at index $i: $error');
              });
      }
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanEnd: (_) {},
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const PageScrollPhysics(),
        child: Row(
          children: widget.mediaUrls.map((url) {
            final index = widget.mediaUrls.indexOf(url);

            double calculatedHeight =
                _heights[index] ?? MediaQuery.of(context).size.width / (16 / 9);

            if (_isVideo(url)) {
              if (!_videoControllers.containsKey(index)) {
                _videoControllers[index] =
                    CachedVideoPlayerPlusController.networkUrl(Uri.parse(url))
                      ..initialize().then((_) {
                        setState(() {});
                        if (widget.isPlayingState == false) {
                          _videoControllers[index]!.pause();
                        }
                      }).catchError((error) {
                        print(
                            'Error initializing video at index $index: $error');
                      });
              }
              final controller = _videoControllers[index]!;

              // Automatically play or pause based on the auto-play state
              if (_manualControlStates[index] == null) {
                // Only manage auto-play if manual control isn't active
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
                      child: GestureDetector(
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
                    )
                ],
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

  Widget _buildShimmerLoader(double width, double height) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[300],
      ),
    );
  }
}

