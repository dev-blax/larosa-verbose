import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Features/Feeds/Components/carousel.dart';
import 'package:larosa_block/Features/Feeds/Components/comments_component.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class PostComponent extends StatefulWidget {
  final dynamic post;
  const PostComponent({
    super.key,
    required this.post,
  });

  @override
  State<PostComponent> createState() => _PostComponentState();
}

class _PostComponentState extends State<PostComponent>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likesCount;
  late bool _isFavorite;
  late int _favoriteCount;

  @override
  void initState() {
    _isLiked = widget.post['liked'];
    _likesCount = widget.post['likes'];
    _isFavorite = widget.post['favorite'];
    _favoriteCount = widget.post['favorites'];
    super.initState();
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
        print('response: ${response.statusCode}');
        await AuthService.refreshToken();
        _favouritePost();
      }

      if (response.statusCode != 200) {
        // Get.snackbar(
        //   'Explore Larosa',
        //   response.body,
        // );
        return;
      }
    } catch (e) {
      // Get.snackbar('Explore Larosa', 'An unknown error occurred');
    }
  }

  Future<void> _likePost() async {
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
        await AuthService.refreshToken();
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
        if (!_isLiked) {
          setState(() {
            _isLiked = true;
            _likesCount++;
          });
          await _likePost();
        }
      },
      child: Stack(
        children: [
          CenterSnapCarousel(
            mediaUrls: images,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            height: 150,
            width: MediaQuery.of(context).size.width,
            child: !_isLiked
                ? Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black,
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  )
                : Animate(
                    effects: const [
                      SlideEffect(
                        begin: Offset(.4, 0),
                        end: Offset(0, 0),
                        curve: Curves.elasticOut,
                        duration: Duration(seconds: 1),
                      )
                    ],
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromRGBO(133, 16, 7, 1),
                            Colors.transparent
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            bottom: 10,
            left: 5,
            right: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (widget.post['profileId'] ==
                                AuthService.getProfileId()) {
                              //Get.to(const HomeProfileScreen());
                              return;
                            }
                            // Get.to(
                            //   ProfileVisitScreen(
                            //     isBusiness:
                            //         widget.post['accountType'] != 'PERSONAL',
                            //     profileId: widget.post['profileId'],
                            //   ),
                            //   transition: Transition.size,
                            // );
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

                        const Gap(10),
                        // Name and Location
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (widget.post['profileId'] ==
                                    AuthService.getProfileId()) {
                                  // Get.to(const HomeProfileScreen());
                                  return;
                                }
                                // Get.to(
                                //   ProfileVisitScreen(
                                //     isBusiness: widget.post['accountType'] !=
                                //         'PERSONAL',
                                //     profileId: widget.post['profileId'],
                                //   ),
                                //   transition: Transition.size,
                                // );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    widget.post['name'],
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 214, 208, 208),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Gap(5),
                                  if (widget.post['verification_status'] != 1)
                                    SvgPicture.asset(
                                      'assets/svg_icons/IcSharpVerified.svg',
                                      colorFilter: const ColorFilter.mode(
                                        Colors.grey,
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
                                  Iconsax.location5,
                                  color: Color.fromARGB(255, 214, 208, 208),
                                  size: 15,
                                ),
                                const SizedBox(
                                  width: 3,
                                ),
                                Text(
                                  widget.post['country'],
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 214, 208, 208),
                                    fontSize: 12,
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                // Display the Container only if accountType is 'BUSINESS'
                if (widget.post['accountType'] == 'BUSINESS')
                  Container(
                    width:
                        41, // Set the width and height to be equal for a perfect circle
                    height: 41,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, // Makes the container a circle
                      border: Border.all(
                        color: Colors.grey, // Set the border color here
                        width: 1.0, // Set the border width
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        String username = widget
                            .post['username']; // Replace with your data source
                        double price = double.parse(widget.post['price']
                            .toString()); // Ensure to convert to double
                        String names = widget
                            .post['names']; // Replace with your data source

                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => AddToCartScreen(
                        //       username: username,
                        //       price: price,
                        //       names: names,
                        //     ),
                        //   ),
                        // );
                      },
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedShoppingCartCheckIn01,
                        color: Colors.grey,
                        size: 25,
                      ),
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postInteracts() {
    return Container(
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
              IconButton(
                onPressed: () async {
                  setState(() {
                    _isLiked = !_isLiked;
                    if (_isLiked) {
                      _likesCount++;
                    } else {
                      _likesCount--;
                    }
                  });

                  await _likePost();
                },
                icon: _isLiked
                    ? SvgPicture.asset(
                        'assets/icons/SolarHeartAngleBold.svg',
                        width: 25,
                        height: 25,
                        colorFilter: const ColorFilter.mode(
                          Color.fromRGBO(180, 23, 12, 1),
                          BlendMode.srcIn,
                        ),
                        semanticsLabel: 'Like icon',
                      )
                    : SvgPicture.asset(
                        "assets/icons/SolarHeartAngleLinear.svg",
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
                _likesCount.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              )
            ],
          ),

          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                    if (_isFavorite) {
                      _favoriteCount++;
                    } else {
                      _favoriteCount--;
                    }
                  });

                  _favouritePost();
                },
                icon: _isFavorite
                    ? SvgPicture.asset(
                        SvgIconsPaths.starBold,
                        width: 25,
                        height: 25,
                        colorFilter: const ColorFilter.mode(
                          LarosaColors.gold,
                          BlendMode.srcIn,
                        ),
                        semanticsLabel: 'Star icon',
                      )
                    : SvgPicture.asset(
                        SvgIconsPaths.starOutline,
                        width: 25,
                        height: 25,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.secondary,
                          BlendMode.srcIn,
                        ),
                        semanticsLabel: 'Star icon',
                      ),
              ),
              Text(
                _favoriteCount.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              )
            ],
          ),

          // comment icon
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // Get.bottomSheet(
                  //   persistent: true,
                  //   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  //   isScrollControlled: true,
                  //   enableDrag: true,

                  //   CommentSection(
                  //     postId: widget.post['id'],
                  //   ),
                  // );
                  // Scaffold.of(context).showBottomSheet((context) => Container(
                  //       constraints: const BoxConstraints(minHeight: 200),
                  //       child: CommentSection(
                  //         postId: widget.post['id'],
                  //       ),
                  //     ));

                  // showModalBottomSheet(
                  //   context: context,
                  //   builder: (BuildContext context) => Container(
                  //     constraints: const BoxConstraints(minHeight: 200),
                  //     child: CommentSection(
                  //       postId: widget.post['id'],
                  //     ),
                  //   ),
                  // );

                  showMaterialModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) => Container(
                      constraints: const BoxConstraints(minHeight: 200),
                      child: CommentSection(
                        postId: widget.post['id'],
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Iconsax.message,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 25,
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
              // HelperFunctions.shareLink(
              //   widget.post['id'].toString(),
              // );
            },
            icon: SvgPicture.asset(
              'assets/svg_icons/share.svg',
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.secondary,
                BlendMode.srcIn,
              ),
              height: 25,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _mediaAndIntro(),
        //_mediaTest(),
        _postInteracts(),
        PostDetails(
          caption: widget.post['caption'],
          username: widget.post['username'],
        ),
        //_priceAndLocation(),
      ],
    );
  }
}

class PostDetails extends StatelessWidget {
  final String caption;
  final String username;
  const PostDetails({
    super.key,
    required this.caption,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 0,
      ),
      child: Wrap(
        children: [
          RichText(
            maxLines: 4,
            text: TextSpan(
              text: '$username  ',
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
              children: [
                TextSpan(
                  text: EmojiParser().emojify(caption),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
