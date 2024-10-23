// import 'package:flutter/material.dart';
// import 'package:chewie/chewie.dart';
// import 'package:video_player/video_player.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// class VideoPlayerWidget extends StatefulWidget {
//   final String videoUrl;

//   VideoPlayerWidget({required this.videoUrl});

//   @override
//   _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
// }

// class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
//   late VideoPlayerController _videoPlayerController;
//   ChewieController? _chewieController;

//   @override
//   void initState() {
//     super.initState();
//     _initializePlayer();
//   }

//   Future<void> _initializePlayer() async {
//     try {
//       // Use DefaultCacheManager to get the cached file or download if not cached
//       final fileInfo = await DefaultCacheManager().getSingleFile(widget.videoUrl);

//       _videoPlayerController = VideoPlayerController.file(fileInfo)
//         ..initialize().then((_) {
//           _chewieController = ChewieController(
//             videoPlayerController: _videoPlayerController,
//             autoPlay: false,
//             looping: false,
//             aspectRatio: _videoPlayerController.value.aspectRatio,
//             materialProgressColors: ChewieProgressColors(
//               playedColor: Colors.blue,
//               handleColor: Colors.blueAccent,
//               backgroundColor: Colors.grey,
//               bufferedColor: Colors.lightGreen,
//             ),
//             placeholder: const Center(child: CircularProgressIndicator()),
//             autoInitialize: true,
//           );

//           // Update the state once the video is initialized
//           if (mounted) {
//             setState(() {});
//           }
//         });
//     } catch (e) {
//       print("Error loading video: $e");
//     }
//   }

//   @override
//   void dispose() {
//     _videoPlayerController.dispose();
//     _chewieController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return _chewieController != null &&
//             _chewieController!.videoPlayerController.value.isInitialized
//         ? AspectRatio(
//             aspectRatio: _videoPlayerController.value.aspectRatio,
//             child: Chewie(
//               controller: _chewieController!,
//             ),
//           )
//         : const Center(child: CircularProgressIndicator());
//   }
// }
