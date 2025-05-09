import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:like_button/like_button.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:video_player/video_player.dart';

import '../../../Services/auth_service.dart';
import '../../../Utils/colors.dart';
import '../../../Utils/helpers.dart';
import '../../../Utils/svg_paths.dart';
import '../../Feeds/Components/comments_component.dart';
import '../../Reels/widgets/profile_and_caption.dart';

class FullScreenVideoViewer extends StatefulWidget {
  final String videoUrl;
  final dynamic post;

  const FullScreenVideoViewer({
    super.key,
    required this.videoUrl,
    required this.post,
  });

  @override
  State<FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<FullScreenVideoViewer> {
  late VideoPlayerController _videoController;
  bool _showExplosion = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..initialize().then((_) {
            setState(() {});
            _videoController.play();
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  void toggleLike() {
    setState(() {
      widget.post['liked'] = !widget.post['liked'];
      widget.post['likes'] += widget.post['liked'] ? 1 : -1;

      if (widget.post['liked']) {
        _showExplosion = true;
        Future.delayed(const Duration(milliseconds: 1300), () {
          if (mounted) {
            setState(() {
              _showExplosion = false;
            });
          }
        });
      }
    });
  }

  Future<void> _favoritePost() async {
    setState(() {
      widget.post['favorite'] = !widget.post['favorite'];
      widget.post['favorites'] += widget.post['favorite'] ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Video Player
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController.value.isPlaying) {
                  _videoController.pause();
                  _isPlaying = false;
                } else {
                  _videoController.play();
                  _isPlaying = true;
                }
              });
            },
            onDoubleTap: toggleLike,
            child: Center(
              child: _videoController.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),

          // Play/Pause Icon Overlay
          if (!_isPlaying)
            Icon(
              Icons.play_circle_outline,
              size: 70,
              color: Colors.white.withOpacity(0.7),
            ),

          // Like Animation
          if (_showExplosion)
            LottieBuilder.asset(
              'assets/lotties/like_explode.json',
              width: 250,
              height: 250,
              repeat: false,
            ),

          // Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Interactions
          Positioned(
            bottom: MediaQuery.of(context).size.height / 2 - 100,
            right: 0.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    children: [
                      LikeButton(
                        size: 26.0,
                        isLiked: widget.post['liked'] ?? false,
                        likeCount: widget.post['likes'] ?? 0,
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
                            text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                        countPostion: CountPostion.bottom,
                        likeCountPadding: const EdgeInsets.only(top: 8.0),
                        onTap: (bool isLiked) async {
                          toggleLike();
                          return !isLiked;
                        },
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Column(
                    children: [
                      LikeButton(
                        size: 26.0,
                        isLiked: widget.post['favorite'] ?? false,
                        likeCount: widget.post['favorites'] ?? 0,
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
                            text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                        countPostion: CountPostion.bottom,
                        likeCountPadding: const EdgeInsets.only(top: 10.0),
                        onTap: (bool isFavorite) async {
                          await _favoritePost();
                          return !isFavorite;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          showMaterialModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) => Container(
                              constraints: const BoxConstraints(minHeight: 200),
                              child: CommentSection(
                                postId: widget.post['id'],
                                names: widget.post['names'],
                                onCommentAdded: (int newCommentCount) {
                                  setState(() {
                                    widget.post['comments'] = newCommentCount;
                                  });
                                },
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
                        (widget.post['comments'] ?? 0).toString(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          HelperFunctions.shareLink(
                              widget.post['id'].toString());
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
                      const Text(
                        'Share',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Profile and Caption
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: ProfileAndCaption(
              profileImageUrl: widget.post['profileImageUrl'] ?? '',
              name: widget.post['name'] ?? 'Unknown',
              username: widget.post['username'] ?? 'Unknown',
              caption: widget.post['caption'] ?? '',
              onProfileTap: () {
                // Implement profile navigation here
                if (widget.post['profileId'] == AuthService.getProfileId()) {
                  context.pushNamed('homeprofile');
                  return;
                }

                final accountType =
                    widget.post['accountType'] == 'BUSINESS' ? '2' : '1';
                context.push(
                    '/profilevisit/?profileId=${widget.post['profileId']}&accountType=$accountType');
              },
            ),
          ),
        ],
      ),
    );
  }
}
