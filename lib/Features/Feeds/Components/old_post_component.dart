import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:like_button/like_button.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Features/Feeds/Components/carousel.dart';
import 'package:larosa_block/Features/Feeds/Components/comments_component.dart';
import 'package:larosa_block/Features/Feeds/Components/report_post.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../../Cart/add_to_cart.dart';
import '../Controllers/business_post_controller.dart';
import 'post_details.dart';

class OldPostCompoent extends StatefulWidget {
  final dynamic post;
  final bool isPlaying;
  const OldPostCompoent({super.key, this.post, required this.isPlaying});

  @override
  State<OldPostCompoent> createState() => _OldPostCompoentState();
}

class _OldPostCompoentState extends State<OldPostCompoent>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likesCount;
  late bool _isFavorite;
  late int _favoriteCount;

  double opacity = 0.0;
  bool _showExplosion = false;

  @override
  void initState() {
    _isLiked = widget.post['liked'];
    _likesCount = widget.post['likes'];
    _isFavorite = widget.post['favorite'];
    _favoriteCount = widget.post['favorites'];
    super.initState();
  }

  void _toggleLike() {
    if (AuthService.getToken().isNotEmpty) {
      setState(() {
        _isLiked = !_isLiked;
        _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;

        if (_isLiked) {
          opacity = 1.0;
          _showExplosion = true;
        }
      });
    }

    _likePost();

    if (_isLiked) {
      Future.delayed(const Duration(milliseconds: 13000), () {
        setState(() {
          opacity = 0.0;
          _showExplosion = false;
        });
      });
    }
  }

  Future<void> _favouritePost() async {
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
          "postId": widget.post['id'].toString(),
        }),
        headers: headers,
      );

      if (response.statusCode == 302) {
        await AuthService.refreshToken();
        _favouritePost();
      }

      if (response.statusCode != 200) {
        return;
      }
    } catch (e) {
      // Get.snackbar('Explore Larosa', 'An unknown error occurred');
    }
  }

  Future<void> _likePost() async {
    String token = AuthService.getToken();

    if (token.isEmpty) {
      LogService.logInfo('no token');
      context.push('/login');
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
          "postId": widget.post['id'].toString(),
        }),
        headers: headers,
      );

      if (response.statusCode == 200) {
      } else if (response.statusCode == 302 || response.statusCode == 403) {
        bool isRefreshed = await AuthService.booleanRefreshToken();
        if (!isRefreshed && mounted) {
          HelperFunctions.logout(context);
          return;
        }
        await _likePost();
        return;
      } else {
        // Get.snackbar('Explore Larosa', 'Error occured');
      }
    } catch (e) {
      //HelperFunctions.displaySnackbar('An unknown error occurred');
    }
  }

  Widget _mediaAndIntro() {
    List<String> images = [];
    for (var image in widget.post['names'].split(',')) {
      images.add(image);
    }

    return GestureDetector(
      onDoubleTap: () async {
        _toggleLike();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          CenterSnapCarousel(
            mediaUrls: images,
            isPlayingState: widget.isPlaying,
            postHeight: widget.post['height'],
          ),
          if (widget.post['reservation_type'] != null)
            Positioned(
              top: 0,
              left: 0,
              child: Stack(
                children: [
                  Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.01),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            widget.post['wifi'] == 0 ||
                                    widget.post['wifi'] == null
                                ? Icon(
                                    CupertinoIcons.wifi_slash,
                                    size: 20,
                                    color: Colors.white.withOpacity(0.8),
                                  )
                                : Icon(
                                    CupertinoIcons.wifi,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                            Gap(5),
                            Text('Wifi', style: TextStyle(color: Colors.white))
                          ],
                        ),
                        Gap(10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            widget.post['swing_pool'] == 0 ||
                                    widget.post['swing_pool'] == null
                                ? SvgPicture.asset(
                                    SvgIconsPaths.poolOff,
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withOpacity(0.8),
                                      BlendMode.srcIn,
                                    ),
                                    height: 20,
                                  )
                                : SvgPicture.asset(
                                    SvgIconsPaths.swimming,
                                    colorFilter: ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                    height: 20,
                                  ),
                            Gap(5),
                            Text('Swimming', style: TextStyle(color: Colors.white))
                          ],
                        ),
                        Gap(10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SvgPicture.asset(
                                  SvgIconsPaths.gymIcon,
                                  colorFilter: ColorFilter.mode(
                                    Colors.white.withOpacity(0.8),
                                    BlendMode.srcIn,
                                  ),
                                  height: 20,
                                ),
                              ],
                            ),
                            Gap(5),
                            Text('Gym', style: TextStyle(color: Colors.white))
                          ],
                        ),
                        Gap(10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            widget.post['parking'] == 0 ||
                                    widget.post['parking'] == null
                                ? SvgPicture.asset(
                                    'assets/svg_icons/LucideCircleParkingOff.svg',
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withOpacity(0.8),
                                      BlendMode.srcIn,
                                    ),
                                    height: 20,
                                  )
                                : SvgPicture.asset(
                                    'assets/svg_icons/HugeiconsParkingAreaCircle.svg',
                                    colorFilter: ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                    height: 20,
                                  ),
                            Gap(5),
                            Text('Parking', style: TextStyle(color: Colors.white))
                          ],
                        ),
                        Gap(10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            widget.post['breakfast'] == 0 ||
                                    widget.post['breakfast'] == null
                                ? SvgPicture.asset(
                                    'assets/svg_icons/PepiconsPencilCupOff.svg',
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withOpacity(0.8),
                                      BlendMode.srcIn,
                                    ),
                                    height: 20,
                                  )
                                : SvgPicture.asset(
                                    SvgIconsPaths.breakfast,
                                    colorFilter: ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                    height: 20,
                                  ),
                            Gap(5),
                            Text('Breakfast', style: TextStyle(color: Colors.white))
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            height: 50,
            width: MediaQuery.of(context).size.width,
            child: Animate(
              key: ValueKey(_isLiked),
              effects: [
                SlideEffect(
                  begin:
                      _isLiked ? const Offset(0.4, 0) : const Offset(-0.4, 0),
                  end: const Offset(0, 0),
                  curve: Curves.elasticOut,
                  duration: const Duration(seconds: 2),
                ),
              ],
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: !_isLiked
                        ? [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.black.withValues(alpha: 0.01),
                          ]
                        : [
                            const Color.fromRGBO(133, 16, 7, 1)
                                .withValues(alpha: 0.9),
                            const Color.fromRGBO(133, 16, 7, 1)
                                .withValues(alpha: 0.01),
                          ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 5,
            right: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (widget.post['profileId'] ==
                            AuthService.getProfileId()) {
                          context.pushNamed('homeprofile');
                          return;
                        }

                        int accountType =
                            widget.post['accountType'] == 'BUSINESS' ? 2 : 1;

                        context.push(
                          '/profilevisit/?profileId=${widget.post['profileId']}&accountType=$accountType',
                        );
                      },
                      child: widget.post['profile_picture'] != null
                          ? CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                widget.post['profile_picture'],
                              ),
                            )
                          : ClipOval(
                              child: Image.asset(
                                'assets/images/EXPLORE.png',
                                height: 43,
                                width: 43,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    const Gap(15),
                    // Name and Location
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (widget.post['profileId'] ==
                                AuthService.getProfileId()) {
                              context.pushNamed('homeprofile');
                              return;
                            }

                            LogService.logInfo(
                                'isBusiness ${widget.post['accountType']}');

                            double accountType =
                                widget.post['accountType'] == 'BUSINESS'
                                    ? 2
                                    : 1;

                            context.push(
                              '/profilevisit/?profileId=${widget.post['profileId']}&accountType=$accountType',
                            );
                          },
                          child: Row(
                            children: [
                              Text(
                                widget.post['name'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Gap(5),
                              if (widget.post['verification_status'] != 1)
                                SvgPicture.asset(
                                  'assets/svg_icons/IcSharpVerified.svg',
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                  height: 16,
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.location,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              widget.post['country'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.post['accountType'] == 'BUSINESS' &&
                    widget.post['price'] != null)
                  Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            'Tsh ${HelperFunctions.formatPrice(widget.post['price']).toString()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Iconsax.star1,
                                color: Colors.yellow,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.post['rate'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 41,
                        height: 41,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (AuthService.getToken().isNotEmpty) {
                              LogService.logTrace(
                                  'post details, post: ${widget.post}');
                              String username = widget.post['username'];
                              double price =
                                  double.parse(widget.post['price'].toString());
                              String names = widget.post['names'];
                              int postId = widget.post['id'];
                              String? reservationType =
                                  widget.post['reservation_type'];
                              int? adults = widget.post['adults'];
                              bool? breakfastIncluded =
                                  widget.post['breakfast_included'];

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddToCartScreen(
                                    username: username,
                                    price: price,
                                    names: names,
                                    postId: postId,
                                    reservationType: reservationType,
                                    adults: adults,
                                    breakfastIncluded: breakfastIncluded,
                                    productId: postId,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please login to add to cart'),
                                ),
                              );
                              context.pushNamed('login');
                            }
                          },
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedShoppingCartCheckIn01,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (_showExplosion)
            LottieBuilder.asset(
              'assets/lotties/like_explode.json',
              width: 250,
              height: 250,
              repeat: false, // Play only once
            ),
        ],
      ),
    );
  }

  Widget _postInteracts() {
    return Container(
      padding: const EdgeInsets.only(left: 8.0, right: 0.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Like Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Second LikeButton (small)
              LikeButton(
                size: 23.0,
                isLiked: _isLiked,
                likeCount: _likesCount,
                animationDuration: const Duration(milliseconds: 500),
                bubblesColor: const BubblesColor(
                  dotPrimaryColor: Color.fromRGBO(180, 23, 12, 1),
                  dotSecondaryColor: Colors.orange,
                  dotThirdColor: Colors.yellow,
                  dotLastColor: Colors.red,
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
                    // width: 25,
                    // height: 25,
                    colorFilter: ColorFilter.mode(
                      isLiked
                          ? const Color.fromRGBO(180, 23, 12, 1)
                          : Theme.of(context).colorScheme.secondary,
                      BlendMode.srcIn,
                    ),
                    semanticsLabel: 'Like icon',
                  );
                },
                likeCountPadding: const EdgeInsets.only(left: 8.0),
                countBuilder: (int? count, bool isLiked, String text) {
                  return Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
                onTap: (bool isLiked) {
                  _toggleLike();
                  return Future.value(_isLiked);
                },
              ),
            ],
          ),
    
          Row(
            children: [
              LikeButton(
                size: 23.0,
                isLiked: _isFavorite,
                likeCount: _favoriteCount,
                animationDuration: const Duration(milliseconds: 500),
                bubblesColor: const BubblesColor(
                  dotPrimaryColor: Color.fromRGBO(255, 215, 0, 1),
                  dotSecondaryColor: Colors.orange,
                  dotThirdColor: Colors.yellow,
                  dotLastColor: Colors.red,
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
                    // width: 25,
                    // height: 25,
                    colorFilter: ColorFilter.mode(
                      isLiked
                          ? LarosaColors.gold
                          : Theme.of(context).colorScheme.secondary,
                      BlendMode.srcIn,
                    ),
                    semanticsLabel: 'Star icon',
                  );
                },
                likeCountPadding: const EdgeInsets.only(left: 8.0),
                countBuilder: (int? count, bool isLiked, String text) {
                  return Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
                onTap: (bool isLiked) {
                  _isFavorite = !isLiked;
                  _favoriteCount =
                      _isFavorite ? _favoriteCount + 1 : _favoriteCount - 1;
                  setState(() {});
                  Future.microtask(() => _favouritePost());
                  return Future.value(_isFavorite);
                },
              ),
            ],
          ),
          // comment icon
          Row(
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
                        onCommentAdded: (newCommentCount) {
                          setState(() {
                            widget.post['comments'] = newCommentCount;
                          });
                        },
                      ),
                    ),
                  );
                },
                icon: Icon(
                  CupertinoIcons.chat_bubble,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 23,
                ),
              ),
              Text(
                widget.post['comments'].toString(),
                style: Theme.of(context).textTheme.bodySmall,
              )
            ],
          ),
    
          // Share
          IconButton(
            onPressed: () {
              showCupertinoModalPopup(
                context: context,
                builder: (context) => CupertinoActionSheet(
                  actions: [
                    CupertinoActionSheetAction(
                      onPressed: () {
                        Navigator.pop(context);
                        HelperFunctions.shareLink(
                          widget.post['id'].toString(),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.share,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Share Post'),
                        ],
                      ),
                    ),
                    CupertinoActionSheetAction(
                      isDestructiveAction: true,
                      onPressed: () {
                        Navigator.pop(context);
                        showCupertinoDialog(
                          context: context,
                          builder: (context) => ReportPostComponent(
                            postId: widget.post['id'].toString(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_triangle,
                              color: CupertinoColors.activeOrange),
                          const SizedBox(width: 8),
                          const Text('Report Post',
                              style: TextStyle(
                                  color: CupertinoColors.activeOrange)),
                        ],
                      ),
                    ),
                    if (widget.post['profileId'] ==
                        AuthService.getProfileId())
                      // Delete Post
                      CupertinoActionSheetAction(
                        onPressed: () async {
                          Navigator.pop(context);
                          
                          final shouldDelete = await showCupertinoDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) => CupertinoAlertDialog(
                              title: const Text('Delete Post'),
                              content: const Text('Are you sure you want to delete this post?'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: const Text('Delete'),
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                ),
                              ],
                            ),
                          );
    
                          if (shouldDelete == true && mounted) {
                            try {
                              final success = await BusinessCategoryProvider.deletePost(widget.post['id']);
                              if (success && mounted) {
                                HelperFunctions.showToast('Post deleted successfully', true);
                              }
                            } catch (e) {
                              if (mounted) {
                                HelperFunctions.showToast('Failed to delete post', false);
                              }
                            }
                        }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.trash,
                              color: CupertinoColors.destructiveRed,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Delete Post',
                              style: TextStyle(
                                color: CupertinoColors.destructiveRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              );
            },
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.secondary,
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _mediaAndIntro(),
          _postInteracts(),
          PostDetails(
            caption: widget.post['caption'],
            username: widget.post['username'],
            date: widget.post['duration'],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 1, bottom: 0), // Eliminates all padding
            child: Divider(
              height: 1,
              thickness: 1,
            ),
          )
        ],
      ),
    );
  }
}
