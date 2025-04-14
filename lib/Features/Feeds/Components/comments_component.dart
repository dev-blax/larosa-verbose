import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:shimmer/shimmer.dart';

import '../../../Utils/helpers.dart';
import 'carousel.dart';

class CommentSection extends StatefulWidget {
  final int postId;
  final String names;
  const CommentSection({
    super.key,
    required this.postId,
    required this.names,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> postComments = [];
  List<String> mediaFiles = []; // List to hold media files (URLs)

  bool _isLoading = true;
  String? replyToUsername;
  int? parentCommentId;
  bool isCommenting = false;
  var parser = EmojiParser();

  Map<String, String> headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
  };

  Map<int, Map<String, dynamic>> commentStatus = {};



  Future<bool> _sendComment(
    String comment,
    bool isReply,
    int parentCommentId, {
    int? commentId,
  }) async {
    String token = AuthService.getToken();
    if (token.isEmpty) return false;

    // Convert emojis to shortcodes
    String processedComment = parser.unemojify(comment);

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      isReply ? '/comments/reply' : '/comments/new',
    );

    int newCommentId = commentId ?? DateTime.now().millisecondsSinceEpoch;
    setState(() {
      commentStatus[newCommentId] = {
        'isSending': true,
        'hasFailed': false,
        'content': comment
      };
    });
    LogService.logInfo('Sending comment $comment');
    LogService.logInfo('processedComment: $processedComment');

    

    try {
      var body = isReply
          ? {
              'profileId': AuthService.getProfileId(),
              'postId': widget.postId,
              'parentId': parentCommentId,
              'message': processedComment,
            }
          : {
              'profileId': AuthService.getProfileId(),
              'postId': widget.postId,
              'message': processedComment,
            };

      final response = await http.post(
        url,
        body: jsonEncode(body),
        headers: {
          "Authorization": 'Bearer $token',
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 201) {
        setState(() {
          _commentController.clear();
          replyToUsername = null;
          this.parentCommentId = null;
          commentStatus[newCommentId] = {
            'isSending': false,
            'hasFailed': false
          };
        });
        await fetchComments();
        return true;
      } else {
        throw Exception('Failed to send comment');
      }
    } catch (e) {
      setState(() {
        commentStatus[newCommentId] = {
          'isSending': false,
          'hasFailed': true,
          'content': comment
        };
      });
      return false;
    }
  }

  void _retryComment(int commentId) {
    String commentContent = commentStatus[commentId]?['content'] ?? '';
    if (commentContent.isNotEmpty) {
      _sendComment(
          commentContent, replyToUsername != null, parentCommentId ?? 0,
          commentId: commentId);
    }
  }

  @override
  void initState() {
    fetchComments();
    mediaFiles = widget.names
        .split(',')
        .map((e) => e.trim())
        .toList(); // Split and trim the URLs
    super.initState();
  }

  Widget _buildVideoPlayer(String url) {
    return CenterSnapCarousel(
      mediaUrls: [url],
      isPlayingState: false,
    ); // Ensure VideoPlayerWidget is a widget class
  }

  Widget _buildMediaFile(String url) {
    if (url.endsWith('.mp4')) {
      return _buildVideoPlayer(url);
    } else if (url.endsWith('.jpg') ||
        url.endsWith('.png') ||
        url.endsWith('.jpeg')) {
      return _buildImage(url);
    } else {
      return const Text('Unsupported file format');
    }
  }

  Widget _buildImage(String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: CachedNetworkImage(
        imageUrl: url,
        placeholder: (context, url) => const Center(
          child: SpinKitCircle(color: Colors.blue),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
        height: 200,
        fit: BoxFit.cover,
      ),
    );
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
          postComments = data.reversed.toList();
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode == 403 || response.statusCode == 302) {
        await AuthService.refreshToken();
        fetchComments();
      } else {
        // Optionally handle other status codes here
      }
    } catch (e) {
      // Optionally handle the error here
    }
  }

  Widget commentsShimmer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post Image Placeholder
                  Shimmer.fromColors(
                    baseColor:
                        isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
                    highlightColor:
                        isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                    child: Container(
                      height: 200, // Height for the image
                      width: double.infinity,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Comment List Placeholder
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: List.generate(10, (index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture and Username Shimmer
                            Row(
                              children: [
                                Shimmer.fromColors(
                                  baseColor: isDarkMode
                                      ? Colors.grey[900]!
                                      : Colors.grey[400]!,
                                  highlightColor: isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[100]!,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Shimmer.fromColors(
                                  baseColor: isDarkMode
                                      ? Colors.grey[900]!
                                      : Colors.grey[400]!,
                                  highlightColor: isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[100]!,
                                  child: Container(
                                    width: 100,
                                    height: 10,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Comment Text Shimmer
                            Shimmer.fromColors(
                              baseColor: isDarkMode
                                  ? Colors.grey[900]!
                                  : Colors.grey[400]!,
                              highlightColor: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[100]!,
                              child: Container(
                                width: double.infinity,
                                height: 15,
                                margin: const EdgeInsets.only(left: 50),
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Shimmer.fromColors(
                              baseColor: isDarkMode
                                  ? Colors.grey[900]!
                                  : Colors.grey[400]!,
                              highlightColor: isDarkMode
                                  ? Colors.grey[700]!
                                  : Colors.grey[100]!,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height: 10,
                                margin: const EdgeInsets.only(left: 50),
                                color: Colors.grey[300],
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Date and Reply Shimmer
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Shimmer.fromColors(
                                  baseColor: isDarkMode
                                      ? Colors.grey[900]!
                                      : Colors.grey[400]!,
                                  highlightColor: isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[100]!,
                                  child: Container(
                                    width: 80,
                                    height: 10,
                                    color: Colors.grey[300],
                                  ),
                                ),
                                Shimmer.fromColors(
                                  baseColor: isDarkMode
                                      ? Colors.grey[900]!
                                      : Colors.grey[400]!,
                                  highlightColor: isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey[100]!,
                                  child: Container(
                                    width: 50,
                                    height: 10,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Comment Input Shimmer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Shimmer.fromColors(
              baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
              highlightColor:
                  isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? commentsShimmer(context)
        : Scaffold(
            body: Column(
              children: [
                Flexible(
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 400,
                        floating: false,
                        pinned: true,
                        backgroundColor: Colors.black,
                        leading: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  LarosaColors.primary.withOpacity(.3),
                                  LarosaColors.purple.withOpacity(.3),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              CupertinoIcons.down_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        flexibleSpace: LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            double percentCollapsed =
                                ((constraints.maxHeight - kToolbarHeight) /
                                        (400 - kToolbarHeight))
                                    .clamp(0.0,
                                        1.0); // Ensure value is between 0 and 1

                            bool hasVideoFiles =
                                mediaFiles.any((url) => url.endsWith('.mp4'));

                            return Stack(
                              children: [
                                // This is the media section when the app bar is expanded
                                Opacity(
                                  opacity: percentCollapsed,
                                  child: PageView.builder(
                                    itemCount: mediaFiles.length,
                                    itemBuilder: (context, index) {
                                      return _buildMediaFile(mediaFiles[index]);
                                    },
                                  ),
                                ),
                                // This is the media section when the app bar is collapsed
                                if (!hasVideoFiles)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Opacity(
                                      opacity: 1.0 - percentCollapsed,
                                      child: SizedBox(
                                        height:
                                            300, // Increased height for the collapsed state
                                        child: PageView.builder(
                                          itemCount: mediaFiles.length,
                                          itemBuilder: (context, index) {
                                            return _buildMediaFile(
                                                mediaFiles[index]);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const Divider(),
                            postComments.isEmpty
                                ? const Center(
                                    child: Text(
                                        'Be the first to comment on this post'),
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
                                          postId: widget.postId,
                                        );
                                      })
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                        child: SizedBox(
                          height: 50,
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white),
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
                                // Get.snackbar(
                                //   'Explore Larosa',
                                //   'You can not post an empty comment',
                                // );
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
                      ),
                      const Gap(5),
                      GestureDetector(
                        onTap: () async {
                          if (_commentController.text.isNotEmpty &&
                              !isCommenting) {
                            String commentText = _commentController.text;

                            setState(() {
                              isCommenting = true;
                              // Optimistically add the comment to the list with sending state
                              postComments.insert(
                                0,
                                {
                                  'id': DateTime.now()
                                      .millisecondsSinceEpoch, // temporary ID
                                  'username':
                                      'Current User', // Replace with actual username if available
                                  'message': commentText,
                                  'profilePicture':
                                      null, // Replace if profile picture available
                                  'duration': 'Just now',
                                  'replies': 0,
                                  'likes': 0,
                                  'isSending': true,
                                  'hasFailed': false,
                                },
                              );
                              _commentController.clear();
                            });

                            bool success = await _sendComment(
                              commentText,
                              replyToUsername != null,
                              parentCommentId ?? 0,
                            );

                            if (success) {
                              // Comment was sent successfully; update UI
                              setState(() {
                                postComments[0]['isSending'] = false;
                              });
                            } else {
                              // Sending failed; update UI to show retry
                              setState(() {
                                postComments[0]['isSending'] = false;
                                postComments[0]['hasFailed'] = true;
                              });
                            }

                            setState(() {
                              isCommenting = false;
                            });
                          } else {
                            // HelperFunctions.displaySnackbar('Cannot comment');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
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
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Gap(5),
                                    Icon(Iconsax.send_14, color: Colors.white),
                                  ],
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
}

class PostCommentTile extends StatefulWidget {
  final dynamic comment;
  final int postId;
  final bool hasFailed;
  final bool isSending;
  final VoidCallback? onRetry;
  final Function(String, int) onReply;

  const PostCommentTile({
    super.key,
    required this.comment,
    required this.onReply,
    required this.postId,
    this.hasFailed = false,
    this.isSending = false,
    this.onRetry,
  });

  @override
  State<PostCommentTile> createState() => _PostCommentTileState();
}

class _PostCommentTileState extends State<PostCommentTile> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
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
                        ? const AssetImage('assets/images/EXPLORE.png')
                        : CachedNetworkImageProvider(
                            widget.comment['profilePicture']),
                  ),
                  const Gap(5),
                  Text(
                    widget.comment['username'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Text(widget.comment['duration'] ?? ''),
            ],
          ),
          const Gap(5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Comment message container
              Container(
                decoration: BoxDecoration(
                  gradient: LarosaColors.blueGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  HelperFunctions.emojifyAText(widget.comment['message'] ?? ''),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(
                  height: widget.isSending || widget.hasFailed
                      ? 4
                      : 0), // Spacing between message and indicators

              if (widget.isSending || widget.hasFailed)
                // Retry and isSending indicators
                Padding(
                  padding: const EdgeInsets.only(
                      left: 30.0, top: 10), // Add left padding
                  child: Row(
                    children: [
                      if (widget.isSending)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.green,
                          ),
                        ),
                      if (widget.hasFailed && widget.onRetry != null)
                        SizedBox(
                          height: 15,
                          width: 10,
                          child: IconButton(
                            icon: const Icon(Icons.refresh,
                                color: Colors.red, size: 16),
                            onPressed: widget.onRetry,
                          ),
                        ),
                    ],
                  ),
                )
            ],
          ),
          Gap(widget.isSending || widget.hasFailed ? 8 : 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('12.9.2024'), // Placeholder date, adjust as needed
                  TextButton(
                    onPressed: () {
                      widget.onReply(widget.comment['username'] ?? '',
                          widget.comment['id']);
                    },
                    child: const Text('Reply'),
                  ),
                ],
              ),
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Iconsax.message, size: 18),
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
