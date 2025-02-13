import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:like_button/like_button.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../Features/Feeds/Components/comments_component.dart';
import '../Utils/colors.dart';
import '../Utils/helpers.dart';

class PostInteract extends StatefulWidget {
  final dynamic post;
  const PostInteract({super.key, required this.post});

  @override
  State<PostInteract> createState() => _PostInteractState();
}

class _PostInteractState extends State<PostInteract> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 9.0, right: 0.0),
      child: Container(
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
                  //isLiked: _isLiked,
                  likeCount: widget.post['likes'],
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
                    // _toggleLike();
                    return Future.value(!isLiked);
                  },
                ),
              ],
            ),

            Row(
              children: [
                LikeButton(
                  size: 23.0,
                  // isLiked: _isFavorite,
                  likeCount: widget.post['favorites'],
                  animationDuration:
                      const Duration(milliseconds: 500), // Instant effect
                  bubblesColor: const BubblesColor(
                    dotPrimaryColor:
                        Color.fromRGBO(255, 215, 0, 1), // Gold color
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
                    // Toggle the favorite state and count immediately
                    // _isFavorite = !isLiked;
                    // _favoriteCount =
                    //     _isFavorite ? _favoriteCount + 1 : _favoriteCount - 1;

                    // // Trigger UI update
                    // setState(() {});

                    // // Run _favouritePost in the background
                    // Future.microtask(() => _favouritePost());

                    // Return the new state to `LikeButton`
                    return Future.value(!isLiked);
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
                HelperFunctions.shareLink(
                  widget.post['id'].toString(),
                );
              },
              icon: SvgPicture.asset(
                'assets/svg_icons/share.svg',
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.secondary,
                  BlendMode.srcIn,
                ),
                height: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
