import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:gap/gap.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Features/Feeds/Components/comments_shimmer.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Services/navigation_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/links.dart';
import 'carousel.dart';
import 'post_comment_tile.dart';

class CommentSection extends StatefulWidget {
  final int postId;
  final String names;
  final Function(int newCommentCount) onCommentAdded;

  const CommentSection({
    super.key,
    required this.postId,
    required this.names,
    required this.onCommentAdded,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> postComments = [];
  List<String> mediaFiles = [];

  bool _isLoading = true;
  String? replyToUsername;
  int? parentCommentId;
  bool isCommenting = false;
  var parser = EmojiParser();

  Map<int, Map<String, dynamic>> commentStatus = {};

  Future<bool> _sendComment(
    String comment,
    bool isReply,
    int parentCommentId, {
    int? commentId,
  }) async {
    final dio = DioService().dio;
    final processedComment = parser.unemojify(comment);
    final endpoint = isReply ? '/comments/reply' : '/comments/new';
    final url = '${LarosaLinks.baseurl}$endpoint';

    int newCommentId = commentId ?? DateTime.now().millisecondsSinceEpoch;
    setState(() {
      commentStatus[newCommentId] = {
        'isSending': true,
        'hasFailed': false,
        'content': comment
      };
    });

    LogService.logDebug('Sending ${isReply ? "reply" : "comment"} to: $url');

    try {
      final data = {
        'profileId': AuthService.getProfileId(),
        'postId': widget.postId.toString(),
        'message': processedComment,
      };

      if (isReply) {
        data['parentId'] = parentCommentId.toString();
      }

      LogService.logDebug('Sending data: $data');
      final response = await dio.post(url, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _commentController.clear();
          replyToUsername = null;
          this.parentCommentId = null;
          commentStatus[newCommentId] = {
            'isSending': false,
            'hasFailed': false
          };
        });

        NavigationService.showSnackBar('Comment sent successfully');
        await fetchComments();
        widget.onCommentAdded(postComments.length);
        return true;
      } else {
        throw Exception('Failed to send comment: ${response.statusCode}');
      }
    } catch (error) {
      LogService.logError('Failed to send comment: $error');
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

  @override
  void initState() {
    fetchComments();
    mediaFiles = widget.names.split(',').map((e) => e.trim()).toList();
    super.initState();
  }

  Widget _buildVideoPlayer(String url) {
    return CenterSnapCarousel(
      mediaUrls: [url],
      isPlayingState: false,
    );
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
    try {
      final dio = DioService().dio;
      final url = '${LarosaLinks.baseurl}/comments/post';

      LogService.logDebug('Requesting comments from: $url');

      final response = await dio.post(
        url,
        data: {
          'postId': widget.postId.toString(),
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        LogService.logFatal(' ${data[0]}');

        setState(() {
          postComments = data.reversed.toList();
          _isLoading = false;
          widget.onCommentAdded(postComments.length);
        });
      }
    } catch (error) {
      LogService.logError('Failed to fetch comments: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? CommentsShimmer()
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
                                if (!hasVideoFiles)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Opacity(
                                      opacity: 1.0 - percentCollapsed,
                                      child: SizedBox(
                                        height: 300,
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
                            final isReply = replyToUsername != null;
                            final pCommentId = parentCommentId;

                            setState(() {
                              isCommenting = true;
                              // Optimistically add the comment to the list with sending state
                              postComments.insert(
                                0,
                                {
                                  'id': DateTime.now().millisecondsSinceEpoch,
                                  'username': 'Current User',
                                  'message': commentText,
                                  'profilePicture': null,
                                  'duration': 'Just now',
                                  'replyCount': 0,
                                  'likeCount': 0,
                                  'isLikedByMe': false,
                                  'parentId': isReply ? pCommentId : null,
                                  'isSending': true,
                                  'hasFailed': false,
                                },
                              );
                              _commentController.clear();
                            });

                            bool success = await _sendComment(
                              commentText,
                              isReply,
                              pCommentId ?? 0,
                            );

                            if (success) {
                              // Comment was sent successfully
                              setState(() {
                                replyToUsername = null;
                                parentCommentId = null;
                              });
                              await fetchComments(); // Refresh to get the actual comment data
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
