import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:larosa_block/Services/log_service.dart';
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
  final Map<int, bool> _muteStates = {};
  final Map<int, bool?> _manualControlStates = {};
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final width = MediaQuery.of(context).size.width;
    final page = (_scrollController.offset / width).round();
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      LogService.logInfo("Page changed. Current page: $_currentPage");
    }
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
      LogService.logInfo("Disposed video controller at index $key");
    });
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
          _manualControlStates[index] = false;
          LogService.logInfo(
              "Video at index $index paused via manual control.");
        } else {
          controller.play();
          _manualControlStates[index] = true;
          LogService.logInfo(
              "Video at index $index playing via manual control.");
        }
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
        child: Stack(
          children: [
            Row(
              children: widget.mediaUrls.map((url) {
                final index = widget.mediaUrls.indexOf(url);
                if (_isVideo(url)) {
                  if (!_videoControllers.containsKey(index)) {
                    _videoControllers[index] = CachedVideoPlayerPlusController
                        .networkUrl(Uri.parse(url))
                      ..initialize().then((_) {
                        final controller = _videoControllers[index]!;
                        LogService.logInfo(
                            "Initialized video controller at index $index. Video dimensions: ${controller.value.size}, aspectRatio: ${controller.value.aspectRatio}");
                        setState(() {});
                        if (!widget.isPlayingState) {
                          controller.pause();
                          LogService.logInfo(
                              "Video at index $index is paused on initialization.");
                        }
                      }).catchError((error) {
                        LogService.logError(
                          "Error initializing video at index $index: $error",
                        );
                      });
                  }
                  final controller = _videoControllers[index]!;
                  _muteStates[index] = _muteStates[index] ?? false;

                  if (_manualControlStates[index] == null) {
                    if (widget.isPlayingState) {
                      controller.play();
                      LogService.logInfo(
                          "Auto-playing video at index $index due to widget state.");
                    } else {
                      controller.pause();
                      LogService.logInfo(
                          "Auto-pausing video at index $index due to widget state.");
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
                      if (controller.value.isInitialized)
                        Positioned(
                          right: 5,
                          bottom: 100,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10.0),
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
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () => _togglePlayPause(index),
                                  child: Icon(
                                    _manualControlStates[index] == true ||
                                            (controller.value.isPlaying &&
                                                _manualControlStates[index] ==
                                                    null)
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
                    ],
                  );
                } else {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(),
                    child: CachedNetworkImage(
                      width: MediaQuery.of(context).size.width,
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          _buildShimmerLoader(height: logicalPostHeight),
                      errorWidget: (context, url, error) {
                        return const Icon(Icons.error);
                      },
                    ),
                  );
                }
              }).toList(),
            ),
            if (widget.mediaUrls.length > 1)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentPage + 1}/${widget.mediaUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
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

  Widget buildMediaContainer({
    required String? imageUrl,
    required CachedVideoPlayerPlusController? videoController,
    required BuildContext context,
    required bool isVideo,
  }) {
    const double containerHeight = 300;
    LogService.logInfo(
        "Building media container. isVideo: $isVideo, containerHeight: $containerHeight");
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: containerHeight,
      ),
      child: Container(
        height: containerHeight,
        width: MediaQuery.of(context).size.width,
        decoration: isVideo
            ? null
            : BoxDecoration(
                image: imageUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
        child: isVideo
            ? videoController != null && videoController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: videoController.value.size.width,
                      height: videoController.value.size.height,
                      child: CachedVideoPlayerPlus(videoController),
                    ),
                  )
                : _buildShimmerLoader(height: containerHeight)
            : CachedNetworkImage(
                imageUrl: imageUrl!,
                placeholder: (context, url) =>
                    _buildShimmerLoader(height: containerHeight),
                errorWidget: (context, url, error) {
                  LogService.logError(
                      "Error loading image in media container: $error");
                  return const Icon(Icons.error,
                      size: 50, color: Colors.redAccent);
                },
              ),
      ),
    );
  }
}
