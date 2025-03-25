// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:video_player/video_player.dart';

// class PostComponent extends StatefulWidget {
//   final dynamic post;
//   final bool isPlaying;
//   const PostComponent({
//     super.key,
//     required this.post,
//     required this.isPlaying,
//   });

//   @override
//   State<PostComponent> createState() => _PostComponentState();
// }

// class _PostComponentState extends State<PostComponent> {
//   int _currentMediaIndex = 0;
//   final Map<String, VideoPlayerController> _videoControllers = {};
//   List<String> _mediaList = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeMedia();
//   }

//   void _initializeMedia() {
//     if (widget.post['names'] != null) {
//       _mediaList = widget.post['names'].toString().split(',');
//       // Initialize video controllers for video files
//       for (var media in _mediaList) {
//         if (_isVideoFile(media.trim())) {
//           _initializeVideoController(media.trim());
//         }
//       }
//     }
//   }

//   bool _isVideoFile(String path) {
//     return path.toLowerCase().endsWith('.mp4') ||
//         path.toLowerCase().endsWith('.mov') ||
//         path.toLowerCase().endsWith('.avi');
//   }

//   Future<void> _initializeVideoController(String videoPath) async {
//     final controller = VideoPlayerController.networkUrl(Uri.parse(videoPath));
//     _videoControllers[videoPath] = controller;
//     await controller.initialize();
//     if (mounted) setState(() {});
//   }

//   @override
//   void dispose() {
//     for (var controller in _videoControllers.values) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   Widget _buildMediaWidget(String mediaPath) {
//     mediaPath = mediaPath.trim();
//     if (_isVideoFile(mediaPath)) {
//       final controller = _videoControllers[mediaPath];
//       if (controller == null || !controller.value.isInitialized) {
//         return const Center(
//           child: CupertinoActivityIndicator(),
//         );
//       }
//       return Stack(
//         alignment: Alignment.center,
//         children: [
//           AspectRatio(
//             aspectRatio: controller.value.aspectRatio,
//             child: VideoPlayer(controller),
//           ),
//           if (!controller.value.isPlaying)
//             IconButton(
//               icon: const Icon(Icons.play_arrow, size: 50, color: Colors.white),
//               onPressed: () {
//                 setState(() {
//                   controller.play();
//                 });
//               },
//             ),
//         ],
//       );
//     } else {
//       // Image
//       return CachedNetworkImage(
//         imageUrl: mediaPath,
//         fit: BoxFit.contain,
//         width: double.infinity,
//         errorWidget: (context, error, stackTrace) => const Center(
//           child: Icon(Icons.error_outline, color: Colors.red),
//         ),
//         placeholder: (context, url) => const Center(
//           child: CupertinoActivityIndicator(),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
      
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // User info
//           Row(
//             children: [
//               CircleAvatar(
//                 backgroundImage: widget.post['profile_picture'] != null
//                     ? NetworkImage(widget.post['profile_picture'])
//                     : null,
//                 child: widget.post['profile_picture'] == null
//                     ? const Icon(Icons.person)
//                     : null,
//               ),
//               const SizedBox(width: 8),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.post['name'] ?? 'Unknown',
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   Text(widget.post['duration'] ?? ''),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           // Caption
//           if (widget.post['caption'] != null) Text(widget.post['caption']),
//           const SizedBox(height: 8),
//           // Media Carousel
//           if (_mediaList.isNotEmpty) ...[
//             CarouselSlider(
//               options: CarouselOptions(
//                 height: widget.post['height'] != null
//                     ? (widget.post['height'] as num).toDouble() /
//                         MediaQuery.of(context).devicePixelRatio
//                     : MediaQuery.of(context).size.width * 9 / 16,
//                 viewportFraction: 1.0,
//                 enableInfiniteScroll: _mediaList.length > 1,
//                 onPageChanged: (index, reason) {
//                   setState(() {
//                     _currentMediaIndex = index;
//                     // Pause all videos when sliding
//                     for (var controller in _videoControllers.values) {
//                       controller.pause();
//                     }
//                   });
//                 },
//               ),
//               items: _mediaList.map((media) {
//                 return Container(
//                   width: MediaQuery.of(context).size.width,
//                   margin: const EdgeInsets.symmetric(horizontal: 5.0),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8.0),
//                     child: _buildMediaWidget(media),
//                   ),
//                 );
//               }).toList(),
//             ),
//             if (_mediaList.length > 1) ...[
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: _mediaList.asMap().entries.map((entry) {
//                   return Container(
//                     width: 8.0,
//                     height: 8.0,
//                     margin: const EdgeInsets.symmetric(horizontal: 4.0),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Theme.of(context).primaryColor.withValues(
//                             alpha: _currentMediaIndex == entry.key ? 0.9 : 0.4,
//                           ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ],
//           ],
//           const SizedBox(height: 8),
//           // Stats
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _buildStat(widget.post['likes']?.toString() ?? '0', 'Likes'),
//               _buildStat(
//                   widget.post['comments']?.toString() ?? '0', 'Comments'),
//               _buildStat(widget.post['shares']?.toString() ?? '0', 'Shares'),
//             ],
//           ),
//           const Divider(),
//         ],
//       ),
//     );
//   }

//   Widget _buildStat(String count, String label) {
//     return Row(
//       children: [
//         Text(count),
//         IconButton(
//           onPressed: () {},
//           icon: Icon(CupertinoIcons.heart_fill),
//         ),
//       ],
//     );
//   }
// }
