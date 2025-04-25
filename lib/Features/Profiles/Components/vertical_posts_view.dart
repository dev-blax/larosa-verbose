import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:larosa_block/Features/Feeds/Components/old_post_component.dart';
import 'package:video_player/video_player.dart';

class VerticalPostsView extends StatefulWidget {
  final List<dynamic> posts;
  final int initialIndex;

  const VerticalPostsView({
    super.key,
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<VerticalPostsView> createState() => _VerticalPostsViewState();
}

class _VerticalPostsViewState extends State<VerticalPostsView> {
  late PageController _pageController;
  late VideoPlayerController? _videoController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideoController();
  }

  void _initializeVideoController() {
    if (_isVideo(_getCurrentMediaUrl())) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(_getCurrentMediaUrl()))
            ..initialize().then((_) {
              setState(() {});
              _videoController?.play();
            });
    }
  }

  String _getCurrentMediaUrl() {
    return widget.posts[_currentIndex]['names'].split(',').toList()[0];
  }

  bool _isVideo(String url) {
    return url.toLowerCase().endsWith('.mp4') ||
        url.toLowerCase().endsWith('.mov') ||
        url.toLowerCase().endsWith('.avi');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CupertinoNavigationBar(
        middle: Text(
          'Posts',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: widget.posts.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _videoController?.dispose();
            _videoController = null;
            _initializeVideoController();
          });
        },
        itemBuilder: (context, index) {
          final post = widget.posts[index];

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                if (notification.metrics.axis == Axis.vertical) {
                  return true;
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: OldPostCompoent(post: post, isPlaying: false),
              ),
            ),
          );
        },
      ),
    );
  }
}
