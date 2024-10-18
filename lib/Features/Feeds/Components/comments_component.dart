import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/links.dart';

class CommentSection extends StatefulWidget {
  final int postId;
  const CommentSection({super.key, required this.postId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> postComments = [];
  bool _isLoading = true;
  String? replyToUsername;
  int? parentCommentId;
  bool isCommenting = false;

  Map<String, String> headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
  };

  Future<void> _sendComment(
    String comment,
    bool isReply,
    int parentCommentId,
  ) async {
    String token = AuthService.getToken();

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    if (token.isEmpty) {
      //Get.off(const SigninScreen());
      return;
    }

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      isReply ? '/comments/reply' : '/comments/new',
    );

    try {
      var body = isReply
          ? {
              'profileId': AuthService.getProfileId(),
              'postId': widget.postId,
              'parentId': parentCommentId,
              'message': comment,
            }
          : {
              'profileId': AuthService.getProfileId(),
              'postId': widget.postId,
              'message': comment,
            };

      final response = await http.post(
        url,
        body: jsonEncode(body),
        headers: headers,
      );

      if (response.statusCode == 201) {
        setState(() {
          _commentController.clear();
          replyToUsername = null;
          this.parentCommentId = null;
        });

        //HelperFunctions.displaySnackbar('Your comment has been added');

        await fetchComments();

        return;
      } else if (response.statusCode == 403 || response.statusCode == 302) {
        await AuthService.refreshToken();
        _sendComment(comment, isReply, parentCommentId);
        return;
      } else {
        // HelperFunctions.displaySnackbar('Failed to Comment');
      }
    } catch (e) {
      Get.snackbar('Explore Larosa', 'An error occured! Try again');
    }
  }

  @override
  void initState() {
    fetchComments();
    super.initState();
  }

  Future<void> fetchComments() async {
    var url = Uri.https(LarosaLinks.nakedBaseUrl, '/comments/post');
    try {
      LogService.logDebug('Requesting comments');
      final response = await http.post(
        url,
        body: jsonEncode({
          'postId': widget.postId.toString(),
        }),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          postComments = data;
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode == 403 || response.statusCode == 302) {
        await AuthService.refreshToken();
        fetchComments();
      } else {
        //print('some problems: ${response.statusCode}');
        //HelperFunctions.displaySnackbar('Failed to fetch comments');
      }
    } catch (e) {
      // HelperFunctions.displaySnackbar('Failed to fetch comments');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SpinKitCircle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const Gap(20),
                const Text('loading comments...')
              ],
            ),
          )
        : SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Post file of the comment',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(),
                  postComments.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Text('Be the first to comment on this post'),
                          ),
                        )
                      : Column(
                          children: [
                            ...postComments.map((postComment) {
                              return PostCommentTile(
                                  comment: postComment,
                                  onReply: (username, commentId) {
                                    setState(() {
                                      replyToUsername = username;
                                      parentCommentId = commentId;
                                    });
                                  },
                                  postId: widget.postId);
                            })
                          ],
                        ),
                  if (replyToUsername != null)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Replying to $replyToUsername',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: () {
                            setState(() {
                              replyToUsername = null;
                              parentCommentId = null;
                            });
                          },
                        )
                      ],
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LarosaColors.blueGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                              ),
                              hintStyle: const TextStyle(color: Colors.white),
                              hintText: replyToUsername != null
                                  ? 'Write your reply!'
                                  : 'Write your comment!',
                              border: const OutlineInputBorder(),
                            ),
                            onSubmitted: (value) async {
                              if (value.isEmpty) {
                                Get.snackbar(
                                  'Explore Larosa',
                                  'You can not post an empty comment',
                                );
                                return;
                              }
                              await _sendComment(
                                value,
                                replyToUsername != null,
                                parentCommentId ?? 0,
                              );
                            },
                          ),
                        ),
                        const Gap(5),
                        GestureDetector(
                          onTap: () async {
                            if (_commentController.text.isNotEmpty ||
                                isCommenting) {
                              setState(() {
                                isCommenting = true;
                              });
                              await _sendComment(
                                _commentController.text,
                                replyToUsername != null,
                                parentCommentId ?? 0,
                              );

                              setState(() {
                                isCommenting = false;
                              });
                            } else {
                              // HelperFunctions.displaySnackbar(
                              //   'Cannot comment',
                              // );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LarosaColors.blueGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: isCommenting
                                ? const SpinKitCircle(
                                    color: LarosaColors.light,
                                    size: 25,
                                  )
                                : const Row(
                                    children: [
                                      Text(
                                        'Send',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Gap(5),
                                      Icon(
                                        Iconsax.send_14,
                                        color: Colors.white,
                                      )
                                    ],
                                  ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}

class PostCommentTile extends StatefulWidget {
  final dynamic comment;
  final int postId;
  final Function(String, int) onReply;

  const PostCommentTile({
    super.key,
    required this.comment,
    required this.onReply,
    required this.postId,
  });

  @override
  State<PostCommentTile> createState() => _PostCommentTileState();
}

class _PostCommentTileState extends State<PostCommentTile> {
  Map<String, String> headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
  };

  Future<void> _fetchCommentReplies(int commentId) async {
    var url = Uri.https(LarosaLinks.nakedBaseUrl, '/comments/post/reply ');
    try {
      print('postid : ${widget.postId}, commentId: $commentId ');
      //return;
      final response = await http.post(
        url,
        body: jsonEncode({
          "postId": widget.postId,
          "Long parentId": commentId,
        }),
        headers: headers,
      );

      print('response code: ${response.statusCode} ');
    } catch (e) {
      print('error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('comment: ${widget.comment}');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: widget.comment['profilePicture'] == null
                        ? const AssetImage(
                            'assets/images/EXPLORE.png',
                          )
                        : const AssetImage(
                            'assets/images/EXPLORE.png',
                          ),
                  ),
                  const Gap(5),
                  Text(
                    widget.comment['username'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              // if (widget.comment['replies'] >= 1)
              //   TextButton(
              //     onPressed: () async {
              //       await _fetchCommentReplies(widget.comment['id']);
              //     },
              //     child:
              //         Text('${widget.comment['replies'].toString()} replies'),
              //   ),

              Text(widget.comment['duration']),
            ],
          ),
          const Gap(5),
          Container(
            decoration: BoxDecoration(
              gradient: LarosaColors.blueGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Text(
              widget.comment['message'],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const Gap(5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('12.9.2024'),
                  TextButton(
                    onPressed: () {
                      widget.onReply(
                          widget.comment['username'], widget.comment['id']);
                    },
                    child: const Text('Reply'),
                  ),
                ],
              ),
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.message,
                        size: 18,
                      ),
                      const Gap(5),
                      Text(widget.comment['replies'].toString()),
                    ],
                  ),
                  const Gap(20),
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/SolarHeartAngleBold.svg',
                        width: 20,
                        colorFilter: const ColorFilter.mode(
                          Colors.red,
                          BlendMode.srcIn,
                        ),
                        semanticsLabel: 'Like icon',
                      ),
                      const Gap(5),
                      Text(widget.comment['likes'].toString()),
                    ],
                  ),
                ],
              )
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}
