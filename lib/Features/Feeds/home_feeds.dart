import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:larosa_block/Features/Feeds/Components/post_component.dart';
import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';

class HomeFeedsScreen extends StatefulWidget {
  const HomeFeedsScreen({super.key});

  @override
  State<HomeFeedsScreen> createState() => _HomeFeedsScreenState();
}

class _HomeFeedsScreenState extends State<HomeFeedsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeFeedsController>().fetchPosts();
    });
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        context.read<HomeFeedsController>().fetchPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeFeedsController>(
      builder: (context, controller, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Feed'),
          ),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => controller.refreshPosts(),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: controller.posts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == controller.posts.length) {
                      if (controller.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CupertinoActivityIndicator(),
                          ),
                        );
                      }
                      if (controller.hasError && !controller.isOffline) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(height: 8),
                                const Text('Error loading posts'),
                                TextButton(
                                  onPressed: () => controller.fetchPosts(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    return PostComponent(
                      post: controller.posts[index],
                      isPlaying: _isPlaying,
                    );
                  },
                ),
              ),
              if (controller.isOffline)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.orange.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'You\'re offline. Showing cached content.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}