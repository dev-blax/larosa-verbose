import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/helpers.dart';

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
              SizedBox(height: widget.isSending || widget.hasFailed ? 4 : 0),

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
                )
            ],
          ),
          Gap(widget.isSending || widget.hasFailed ? 8 : 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
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
                      const Icon(CupertinoIcons.chat_bubble, size: 18),
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
