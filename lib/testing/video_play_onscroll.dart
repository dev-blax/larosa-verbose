import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../Features/Feeds/Controllers/home_feeds_controller.dart';
import 'video_player.dart';

class VideoFeedsPage extends StatelessWidget {
  const VideoFeedsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeFeedsController(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media Feeds'),
        ),
        body: Consumer<HomeFeedsController>(
          builder: (context, controller, child) {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.posts.isEmpty) {
              return const Center(child: Text('No media available.'));
            }
            return ListView.builder(
              controller: controller.scrollController,
              itemCount: controller.posts.length,
              itemBuilder: (context, index) {
                var post = controller.posts[index];
                // Parse and ensure names is a List<String>
                List<String> mediaUrls = (post['names'] as String)
                    .split(',')
                    .map((e) => e.trim())
                    .toList();
                return MediaCarousel(mediaUrls: mediaUrls);
              },
            );
          },
        ),
      ),
    );
  }
}

class MediaCarousel extends StatelessWidget {
  final List<String> mediaUrls;

  const MediaCarousel({super.key, required this.mediaUrls});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 800.0,
      ),
      child: PageView.builder(
        itemCount: mediaUrls.length,
        itemBuilder: (context, index) {
          String url = mediaUrls[index];
          if (url.endsWith('.mp4') || url.endsWith('.mov')) {
            // return VideoPlayerWidget(videoUrl: url);
          } else {
            return CachedNetworkImage(
              imageUrl: url,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.contain,
            );
          }
        },
      ),
    );
  }
}
