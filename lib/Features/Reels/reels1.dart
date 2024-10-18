import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HomeFeedsScreenTest extends StatefulWidget {
  @override
  _HomeFeedsScreenTestState createState() => _HomeFeedsScreenTestState();
}

class _HomeFeedsScreenTestState extends State<HomeFeedsScreenTest> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isBuffering = true; // Add this state to check if video is buffering

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  void initializeVideo() async {
    _controller = VideoPlayerController.network(
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4'
      // 'https://storage.googleapis.com/explore-test-1/posts/post_18_2024_8_15_10_8_9_1.mp4',
    );

    try {
      await _controller.initialize();
      _isInitialized = true;
      _isBuffering = false; // Video initialized, stop buffering
      _controller.setLooping(true);
      _controller.play();
      setState(() {});
    } catch (error) {
      print("Error initializing video: $error");
      setState(() {
        _isBuffering = false; // Stop buffering if there's an error
      });
    }

    _controller.addListener(() {
      if (_controller.value.hasError) {
        print("Video Player Error: ${_controller.value.errorDescription}");
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player Debug'),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : _isBuffering
                ? CircularProgressIndicator() // Show buffering indicator
                : Text('Error loading video'),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
