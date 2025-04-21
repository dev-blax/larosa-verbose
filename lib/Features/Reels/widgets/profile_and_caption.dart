import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ProfileAndCaption extends StatefulWidget {
  final String profileImageUrl;
  final String name;
  final String username;
  final String caption;
  final VoidCallback onProfileTap;

  const ProfileAndCaption({
    super.key,
    required this.profileImageUrl,
    required this.name,
    required this.username,
    required this.caption,
    required this.onProfileTap,
  });

  @override
  _ProfileAndCaptionState createState() => _ProfileAndCaptionState();
}

class _ProfileAndCaptionState extends State<ProfileAndCaption> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final maxLines = 2;
    final textSpan = TextSpan(text: widget.caption);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    );
    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 100);
    final bool hasOverflow = textPainter.didExceedMaxLines;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.5),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 10,
          top: 50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile section
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onProfileTap,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.profileImageUrl.isNotEmpty 
                        ? NetworkImage(widget.profileImageUrl) 
                        : AssetImage('assets/images/EXPLORE.png') as ImageProvider,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          widget.username,
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Colors.white70,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Caption section with read more
            if(widget.caption.isNotEmpty)
            StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.caption,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      maxLines: _isExpanded ? null : maxLines,
                      overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                    if (hasOverflow)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Text(
                          _isExpanded ? 'Show less' : 'Read more',
                          style: const TextStyle(
                            color: Colors.white70,
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
        ),
      ),
    );
  }
}