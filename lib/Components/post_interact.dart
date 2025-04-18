import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:larosa_block/Utils/svg_paths.dart';
import 'package:like_button/like_button.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Services/auth_service.dart';

import '../Features/Feeds/Components/comments_component.dart';
import '../Utils/colors.dart';
import '../Utils/helpers.dart';
import '../Utils/links.dart';

class PostInteract extends StatefulWidget {
  final dynamic post;
  final Function(dynamic updatedPost)? onPostUpdated;
  const PostInteract({
    super.key, 
    required this.post,
    this.onPostUpdated,
  });

  @override
  State<PostInteract> createState() => _PostInteractState();
}

class _PostInteractState extends State<PostInteract> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 9.0, right: 0.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
          backgroundBlendMode: BlendMode.srcOver,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LikeButton(
                  size: 23.0,
                  likeCount: widget.post['likes'],
                  isLiked: widget.post['isLiked'] ?? false,
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
                      colorFilter: ColorFilter.mode(
                        isLiked
                            ? const Color.fromRGBO(180, 23, 12, 1)
                            : Theme.of(context).colorScheme.secondary,
                        BlendMode.srcIn,
                      ),
                      semanticsLabel: 'LikeIcon',
                    );
                  },
                  likeCountPadding: const EdgeInsets.only(left: 8.0),
                  countBuilder: (int? count, bool isLiked, String text) {
                    return Text(
                      text,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                  onTap: _likePost,
                ),
              ],
            ),

            Row(
              children: [
                LikeButton(
                  size: 23.0,
                  likeCount: widget.post['favorites'],
                  isLiked: widget.post['isFavorited'] ?? false,
                  animationDuration:
                      const Duration(milliseconds: 500),
                  bubblesColor: const BubblesColor(
                    dotPrimaryColor:
                        Color.fromRGBO(255, 215, 0, 1), 
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
                  onTap: _favoritePost,
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
                          onCommentAdded: (int newCommentCount) {
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

  Future<bool> _likePost(bool isLiked) async {
    try {
      final response = await DioService().dio.post(
        'https://${LarosaLinks.nakedBaseUrl}/like/save',
        data: {
          "likerId": AuthService.getProfileId(),
          "postId": widget.post['id'].toString(),
        },
      );

      if (response.statusCode == 200) {
        // Update the post data after successful API call
        widget.post['likes'] = isLiked ? widget.post['likes'] - 1 : widget.post['likes'] + 1;
        widget.post['isLiked'] = !isLiked;
        // Notify parent of the update
        widget.onPostUpdated?.call(widget.post);
        return !isLiked;
      }
      return isLiked;
    } catch (e) {
      return isLiked;
    }
  }

  Future<bool> _favoritePost(bool isFavorited) async {
    try {
      final response = await DioService().dio.post(
        'https://${LarosaLinks.nakedBaseUrl}/favorites/update',
        data: {
          "profileId": AuthService.getProfileId(),
          "postId": widget.post['id'].toString(),
        },
      );

      if (response.statusCode == 200) {
        // Update the post data after successful API call
        widget.post['favorites'] = isFavorited ? widget.post['favorites'] - 1 : widget.post['favorites'] + 1;
        widget.post['isFavorited'] = !isFavorited;
        // Notify parent of the update
        widget.onPostUpdated?.call(widget.post);
        return !isFavorited;
      }
      return isFavorited;
    } catch (e) {
      return isFavorited;
    }
  }
}
