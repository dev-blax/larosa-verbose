// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';

// class VideoPlayerWidget extends StatefulWidget {
//   final String url;

//   const VideoPlayerWidget({Key? key, required this.url}) : super(key: key);

//   @override
//   _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
// }

// class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
//   late VideoPlayerController _videoPlayerController;
//   ChewieController? _chewieController;

//   @override
//   void initState() {
//     super.initState();
//     _videoPlayerController = VideoPlayerController.network(widget.url)
//       ..addListener(() {
//         setState(
//             () {}); // Rebuild the widget when the state of the controller changes
//       })
//       ..setLooping(false);
//     _initializePlayer();
//   }

//   Future<void> _initializePlayer() async {
//     try {
//       await _videoPlayerController.initialize();
//       _chewieController = ChewieController(
//         videoPlayerController: _videoPlayerController,
//         autoPlay: true,
//         looping: true,
//         showControlsOnInitialize: true,
//         materialProgressColors: ChewieProgressColors(
//           playedColor: Colors.grey,
//           handleColor: Colors.grey,
//           backgroundColor: Colors.black12,
//           bufferedColor: Colors.grey.withOpacity(0.3),
//         ),
//       );
//       setState(() {});
//     } catch (e) {
//       debugPrint('Error initializing video player: $e');
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
//     return GestureDetector(
//       onTap: () {
//         print('hello');
//         // Toggle play and pause on tap
//         if (_videoPlayerController.value.isPlaying) {
//           _videoPlayerController.pause();
//         } else {
//           _videoPlayerController.play();
//         }
//         setState(() {}); // Update the UI based on the play/pause state
//       },
//       child: Stack(
//         children: [
//           Positioned.fill(
//             child: _chewieController != null &&
//                     _videoPlayerController.value.isInitialized
//                 ? Chewie(
//                     controller: _chewieController!,
//                   )
//                 : const Center(child: CircularProgressIndicator()),
//           ),
//           // Optionally, you can add a play/pause overlay icon
//           if (!_videoPlayerController.value.isPlaying)
//             const Positioned(
//               top: 0,
//               bottom: 0,
//               left: 0,
//               right: 0,
//               child: Icon(
//                 Icons.play_arrow,
//                 size: 50.0,
//                 color: Colors.white,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
