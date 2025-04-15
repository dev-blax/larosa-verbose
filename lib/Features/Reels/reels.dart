import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:like_button/like_button.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../../Services/dio_service.dart';
import '../../Services/log_service.dart';
import '../Feeds/Components/carousel.dart';
import '../Feeds/Components/comments_component.dart';
import 'widgets/profile_and_caption.dart';
import 'widgets/reels_loading_shimmer.dart';

class DeReelsScreen extends StatefulWidget {
  const DeReelsScreen({super.key});

  @override
  State<DeReelsScreen> createState() => _DeReelsScreenState();
}

class _DeReelsScreenState extends State<DeReelsScreen> {
  final PageController _pageController = PageController();
  List<Map<String, dynamic>> snippets = [];
  bool _isLoading = true;
  final DioService _dioService = DioService();

  double opacity = 0.0;
  bool _showExplosion = false;

  int _currentPage = 1;
  bool _isFetchingMore = false;

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSnippets();
  }

  Future<void> _loadSnippets({bool loadMore = false}) async {
    if (_isFetchingMore) return;

    setState(() {
      _isFetchingMore = loadMore;
    });


    try {
      final response = await _dioService.dio.post(
        LarosaLinks.reelsFetch,
        data: {
          'profileId': AuthService.getProfileId(),
          'countryId': "1",
          'page': _currentPage,
        },
      );


      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        setState(() {
          if (loadMore) {
            snippets.addAll(data.cast<Map<String, dynamic>>());
          } else {
            snippets = data.cast<Map<String, dynamic>>();
          }

          LogService.logInfo('Snippets loaded: ${snippets[0]}');

          _isLoading = false;
          _isFetchingMore = false;
          _currentPage++;
        });
      } else {
        HelperFunctions.showToast('Cannot Load Snippets', false);
        setState(() {
          _isFetchingMore = false;
        });
      }
    } catch (e) {
      HelperFunctions.displaySnackbar(
        'An unknown error occurred!',
        context,
        false,
      );
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  Future<void> _favoritePost(int postId, int index) async {
    String token = AuthService.getToken();

    if (token.isEmpty) {
      return;
    }

    try {
      final response = await _dioService.dio.post(
        LarosaLinks.reelsFavourite,
        data: {
          "profileId": AuthService.getProfileId(),
          "postId": postId,
        },
      );

      if (response.statusCode == 302) {
        await AuthService.refreshToken();
        await _favoritePost(postId, index);
        return;
      }

      if (response.statusCode != 200) {
        return;
      }
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
      return;
    }

    try {
      final response = await _dioService.dio.post(
        LarosaLinks.reelsLike,
        data: {
          "likerId": AuthService.getProfileId(),
          "postId": postId,
        },
      );

      if (response.statusCode == 200) {
      } else if (response.statusCode == 302 || response.statusCode == 403) {
        await AuthService.refreshToken();
        await _likePost(postId, index);
        return;
      } else {
        
      }
    } catch (e) {
      //HelperFunctions.displaySnackbar('An unknown error occurred');
    }
  }

  void toggleLike(int index) {
    setState(() {
      // Toggle the like state
      snippets[index]['liked'] = !snippets[index]['liked'];
      snippets[index]['likes'] += snippets[index]['liked'] ? 1 : -1;

      // Show the heart animation and explosion effect
      if (snippets[index]['liked']) {
        opacity = 1.0;
        _showExplosion = true;
      }
    });

    // Reset animations after a delay
    if (snippets[index]['liked']) {
      Future.delayed(const Duration(milliseconds: 13000), () {
        setState(() {
          opacity = 0.0; // Hide the heart
          _showExplosion = false; // Hide explosion
        });
      });
    }

    // Call the like API
    _likePost(snippets[index]['id'], index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            _isLoading
                ? const ReelsLoadingShimmer()
                : GestureDetector(
                    onDoubleTap: () {
                      final currentIndex = _pageController.page?.round() ?? 0;
                      toggleLike(currentIndex);
                    },
                    onTap: () {
                      final currentIndex = _pageController.page?.round() ?? 0;
                      setState(() {
                        snippets[currentIndex]['isPlaying'] =
                            !(snippets[currentIndex]['isPlaying'] ?? true);
                      });
                    },
                    child: Container(
                        child: PageView.builder(
                      controller: _pageController,
                      itemCount: snippets.length + 1,
                      scrollDirection: Axis.vertical,
                      onPageChanged: (index) {
                        if (index == snippets.length - 1) {
                          _loadSnippets(loadMore: true);
                        }

                        setState(() {
                          for (var i = 0; i < snippets.length; i++) {
                            snippets[i]['isPlaying'] = i == index;
                          }
                          currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        if (index == snippets.length) {
                          return Center(
                            child: _isFetchingMore
                                ? const CircularProgressIndicator()
                                : const Text(
                                    'No more videos',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          );
                        }

                        final snippet = snippets[index];
                        snippet['isPlaying'] ??= true;

                        LogService.logInfo(snippet.toString());

                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            CenterSnapCarousel(
                              mediaUrls: [snippet['names']],
                              isPlayingState: snippet['isPlaying'],
                              postHeight: MediaQuery.of(context).size.height,
                            ),
                            if (!snippet['isPlaying'])
                              Icon(
                                Icons.play_circle_outline,
                                size: 70,
                                color: Colors.white.withOpacity(0.7),
                              ),
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
                            ProfileAndCaption(
                              profileImageUrl: snippet['profileImageUrl'] ?? '',
                              name: snippet['name'] ?? 'Unknown',
                              username: snippet['username'] ?? 'Unknown',
                              caption: snippet['caption'] ?? '',
                              onProfileTap: _navigateToProfile,
                            ),
                          ],
                        );
                      },
                    )),
                  ),
          ],
        ));
  }

  void _navigateToProfile() {
    final snippet = snippets[currentIndex];
    if (snippet['profileId'] == AuthService.getProfileId()) {
      context.pushNamed('homeprofile');
      return;
    }

    final accountType = snippet['accountType'] == 'BUSINESS' ? '2' : '1';
    context.push('/profilevisit/?profileId=${snippet['profileId']}&accountType=$accountType');
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
          MediaQuery.of(context).size.height / 2 - 100,
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
                      text, 
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 14.0, 
                        fontWeight: FontWeight.bold, 
                      ),
                    );
                  },
                  countPostion: CountPostion
                      .bottom, 
                  likeCountPadding: const EdgeInsets.only(
                      top: 8.0), 
                  onTap: (bool isLiked) async {
                    toggleLike(snippets.indexOf(snippet));
                    return !isLiked;
                  },
                ),
                const SizedBox(height: 5),
              ],
            ),
            const SizedBox(height: 5),

            // Favorite Button with Count Below
            Column(
              children: [
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
                          postId: postId,
                          names: snippet['names'],
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
                const Text(
                  'Share', 
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
