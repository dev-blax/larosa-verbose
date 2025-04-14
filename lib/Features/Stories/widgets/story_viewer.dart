import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:larosa_block/Features/Stories/providers/story_provider.dart';
import 'package:provider/provider.dart';

class StoryViewer extends StatefulWidget {
  final UserStories userStories;

  const StoryViewer({
    super.key,
    required this.userStories,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentIndex = 0;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });

    _startProgress();
    context
        .read<StoryProvider>()
        .markStoriesAsSeen(widget.userStories.profileId);
  }

  void _startProgress() {
    _progressController.forward(from: 0);
  }

  void _nextStory() {
    if (_currentIndex < widget.userStories.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleTapDown(TapDownDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    setState(() {
      _isPaused = true;
      _progressController.stop();
    });

    if (tapPosition < screenWidth / 2) {
      _previousStory();
    } else {
      _nextStory();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPaused = false;
      _progressController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CupertinoColors.black,
      body: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onLongPressStart: (_) {
          setState(() {
            _isPaused = true;
            _progressController.stop();
          });
        },
        onLongPressEnd: (_) {
          setState(() {
            _isPaused = false;
            _progressController.forward();
          });
          HapticFeedback.lightImpact();
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _progressController.forward(from: 0);
                });
              },
              itemCount: widget.userStories.stories.length,
              itemBuilder: (context, index) {
                final story = widget.userStories.stories[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    
                    // Image.network(
                    //   story.names[0],
                    // ),
                    CachedNetworkImage(
                      imageUrl: story.names[0],
                      placeholder: (context, url) => const CupertinoActivityIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black87,
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          story.captions[0],
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: List.generate(
                          widget.userStories.stories.length,
                          (index) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  double progress = 0.0;
                                  if (index == _currentIndex) {
                                    progress = _progressController.value;
                                  } else if (index < _currentIndex) {
                                    progress = 1.0;
                                  }
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: CupertinoColors
                                          .white.withOpacity(0.3),
                                      valueColor:
                                          const AlwaysStoppedAnimation<
                                              Color>(
                                        CupertinoColors.white,
                                      ),
                                      minHeight: 3,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: CupertinoColors.systemGrey6,
                            child: Text(
                              widget.userStories.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.userStories.name,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Icon(
                              CupertinoIcons.xmark,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
