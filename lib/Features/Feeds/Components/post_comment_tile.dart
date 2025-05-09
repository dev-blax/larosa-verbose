import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Services/navigation_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';
import 'package:larosa_block/Utils/links.dart';
import 'like_button_component.dart';

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
  bool isLiked = false;
  bool isLiking = false;
  int likeCount = 0;
  List<dynamic> replies = [];
  bool isLoadingReplies = false;
  bool showReplies = false;

  @override
  void initState() {
    super.initState();
    LogService.logFatal(' ${widget.comment}');
    isLiked = widget.comment['liked'] ?? false;
    likeCount = widget.comment['likes'] ?? 0;
    if (widget.comment['replies'] != null && widget.comment['replies'] > 0) {
      _fetchReplies();
    }
  }

  Future<void> _fetchReplies() async {
    if (isLoadingReplies) return;

    setState(() {
      isLoadingReplies = true;
    });

    try {
      final dio = DioService().dio;
      final url = '${LarosaLinks.baseurl}/comments/post/reply';
      
      final response = await dio.post(
        url,
        data: {
          'parentId': widget.comment['id'],
          'postId': widget.postId,
        },
      );

      if (response.statusCode == 200) {
        LogService.logFatal('replies ${response.data}');
        setState(() {
          replies = response.data;
          showReplies = true;
        });
      }
    } catch (error) {
      LogService.logError('Failed to fetch replies: $error');
    } finally {
      setState(() {
        isLoadingReplies = false;
      });
    }
  }

  Future<void> _handleLike() async {
    if (isLiking) return;

    setState(() {
      isLiking = true;
    });

    try {
      final dio = DioService().dio;
      final url = '${LarosaLinks.baseurl}/comments/like';
      
      final response = await dio.post(
        url,
        data: {
          'likerId': AuthService.getProfileId(),
          'commentId': widget.comment['id'],
        },
      );

      if (response.statusCode == 200) {
        LogService.logFatal('like response ${response.data}');
        setState(() {
          isLiked = !isLiked;
          likeCount += isLiked ? 1 : -1;
        });
      }
    } catch (error) {
      LogService.logError('Failed to like comment: $error');
      NavigationService.showSnackBar('Failed to like comment');
    } finally {
      setState(() {
        isLiking = false;
      });
    }
  }

  Widget _buildReplySection() {
    if (!showReplies) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 32.0, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoadingReplies)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            ...replies.map((reply) => _buildReplyTile(reply)),
        ],
      ),
    );
  }

  Widget _buildReplyTile(dynamic reply) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundImage: reply['profilePicture'] == null
                    ? const AssetImage('assets/images/EXPLORE.png')
                    : CachedNetworkImageProvider(reply['profilePicture']),
              ),
              const Gap(4),
              Text(
                reply['username'] ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(4),
          Container(
            margin: const EdgeInsets.only(left: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.25)
                  : Colors.black.withOpacity(0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              HelperFunctions.emojifyAText(reply['message'] ?? ''),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final replyCount = widget.comment['replies'] ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
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
              const Gap(4),
              Row(
                children: [
                  // Like button
                  LarosaLikeButton(
                    isLiked: isLiked,
                    likeCount: likeCount,
                    onTap: (isLiked) => _handleLike(),
                    size: 16,
                  ),
                  const Gap(12),
                  // Reply button
                  GestureDetector(
                    onTap: () => widget.onReply(
                      widget.comment['username'] ?? '',
                      widget.comment['id'],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.reply,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const Gap(4),
                          Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (replyCount > 0) ...[
                    const Gap(12),
                    // View replies button
                    GestureDetector(
                      onTap: () {
                        if (showReplies) {
                          setState(() => showReplies = false);
                        } else {
                          _fetchReplies();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              showReplies 
                                ? CupertinoIcons.chevron_up
                                : CupertinoIcons.chevron_down,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const Gap(4),
                            Text(
                              showReplies ? 'Hide Replies' : '$replyCount ${replyCount == 1 ? 'Reply' : 'Replies'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              if (widget.isSending || widget.hasFailed)
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, top: 10),
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
                ),
            ],
          ),
          _buildReplySection(),
        ],
      ),
    );
  }
}
