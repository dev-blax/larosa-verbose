import 'package:flutter/material.dart';
import 'package:larosa_block/Utils/helpers.dart';

class PostDetails extends StatefulWidget {
  final String caption;
  final String username;
  final String date;
  const PostDetails(
      {super.key,
      required this.caption,
      required this.username,
      required this.date});

  @override
  State<PostDetails> createState() => _PostDetailsState();
}

class _PostDetailsState extends State<PostDetails> {
  bool _isExpanded = false;
  static const int maxLines = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.15), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                    color: theme.colorScheme.primary, shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  widget.username,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                widget.date,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          if (widget.caption.isNotEmpty) ...[
            const SizedBox(height: 5),
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      HelperFunctions.emojifyAText(widget.caption),
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: _isExpanded ? null : maxLines,
                      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                    if (widget.caption.length > 100) // Arbitrary length to show read more
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Text(
                          _isExpanded ? 'Show less' : 'Read more',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // List<TextSpan> _buildCaptionWithHashtags(
  //     String caption, TextTheme textTheme) {
  //   // Regex to match hashtags, spaces, and emojis/regular text
  //   final regex = RegExp(
  //       r"(#[\w]+)|(\s+)|([\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E6}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]|[^#\s]+)",
  //       unicode: true);
  //   final matches = regex.allMatches(caption);

  //   return matches.map((match) {
  //     final matchText = match.group(0) ?? "";

  //     // Handle hashtags
  //     if (matchText.startsWith("#")) {
  //       return TextSpan(
  //         text: matchText,
  //         style: textTheme.bodySmall?.copyWith(
  //           fontSize: 12,
  //           color: LarosaColors.primary,
  //           fontWeight: FontWeight.bold,
  //           //fontFamily: 'NotoColorEmoji'
  //         ),
  //         recognizer: TapGestureRecognizer()
  //           ..onTap = () {
  //             context.go(
  //               '/search',
  //               extra: {
  //                 'query': matchText.substring(1)
  //               }, // Pass hashtag without "#"
  //             );
  //           },
  //       );
  //     }

  //     // Handle emojis
  //     if (RegExp(
  //             r"[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E6}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]",
  //             unicode: true)
  //         .hasMatch(matchText)) {
  //       return TextSpan(
  //         text: matchText, // Display emoji
  //         style: textTheme.bodySmall?.copyWith(
  //           fontSize: 14, // Slightly larger font size for emojis
  //           color: Colors.orange, // Custom color for emojis
  //         ),
  //       );
  //     }

  //     // Regular text
  //     return TextSpan(
  //       text: matchText,
  //       style: textTheme.bodySmall?.copyWith(
  //         fontSize: 13,
  //         color: Theme.of(context).colorScheme.onSurface,
  //       ),
  //     );
  //   }).toList();
  // }
}
