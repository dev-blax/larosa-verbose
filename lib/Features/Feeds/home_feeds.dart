import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';
import 'package:larosa_block/Features/Feeds/Components/post_component.dart';
import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:larosa_block/Features/Feeds/Components/topbar.dart';
import 'package:larosa_block/Features/Feeds/Components/topbar_two.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomeFeedsScreen extends StatefulWidget {
  const HomeFeedsScreen({super.key});

  @override
  State<HomeFeedsScreen> createState() => _HomeFeedsScreenState();
}

class _HomeFeedsScreenState extends State<HomeFeedsScreen> {
  final Map<int, ValueNotifier<bool>> _postPlayStates = {};

  void _updatePostState(int postId, bool isPlaying) {
    if (_postPlayStates[postId] == null) {
      _postPlayStates[postId] = ValueNotifier(isPlaying);
    } else {
      _postPlayStates[postId]!.value = isPlaying;
    }
  }

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<HomeFeedsController>(context, listen: false);
    controller.scrollController.addListener(() {
      if (controller.scrollController.position.atEdge) {
        bool isBottom = controller.scrollController.position.pixels != 0;
        if (isBottom && !controller.isFetchingMore) {
          controller.fetchMorePosts();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeFeedsController>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: LarosaColors.secondary,
        onRefresh: () async {
          await controller.fetchPosts(true);
        },
        child: Stack(
          children: [
            CustomScrollView(
              controller: controller.scrollController,
              slivers: [
                // SliverAppBar(
                //   elevation: 20,
                //   // backgroundColor: Colors.blue,
                //   floating: true,
                //   bottom: const PreferredSize(
                //     preferredSize: Size.fromHeight(35.0),
                //     child: Text(''),
                //   ),
                //   automaticallyImplyLeading: false,
                //   flexibleSpace: Container(
                //     color: Colors.red,
                //     child: const Column(
                //       mainAxisSize: MainAxisSize.max,
                //       children: [
                //         TopBar1(),
                //         TopBar2(),
                //       ],
                //     ),
                //   ),
                // ),
               SliverAppBar(
  elevation: 0, // Remove shadow for a seamless look
  floating: true,
  pinned: false,
  snap: false,
  automaticallyImplyLeading: false,
  backgroundColor: Colors.transparent, // Make the app bar background transparent
  flexibleSpace: ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0), // Add blur effect
      child: Container(
        color:Theme.of(context).colorScheme.surface.withOpacity(.3), // Ensure the background is fully transparent
        child: const Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            TopBar1(), // Your custom widget
            TopBar2(), // Your custom widget
          ],
        ),
      ),
    ),
  ),
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(35.0),
    child: Text(''), // Placeholder for bottom spacing
  ),
),

                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -23),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: controller.isLoading,
                      builder: (context, isLoading, child) {
                        if (isLoading && controller.posts.isEmpty) {
                          return _buildShimmerLoading();
                        } else if (controller.posts.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50.0),
                              child: Text('Fetching posts'),
                            ),
                          );
                        } else {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 100.0, top: 0),
                            child: ListView.builder(
                              itemCount: controller.posts.length +
                                  (controller.isFetchingMore ? 1 : 0) +
                                  1, // +1 for "Hello world"
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                // Check if we are at the last item for "Hello world"
                                if (index == controller.posts.length) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.only(bottom: 0.0, top: 20),
                                    child: Center(
                                      child: CupertinoActivityIndicator(
                                        radius:
                                            15.0, // Adjust the size as needed
                                      ),
                                    ),
                                  );
                                }
                                // Check if it's loading more data
                                else if (index == controller.posts.length + 1 &&
                                    controller.isFetchingMore) {
                                  return const Padding(
                                    padding: EdgeInsets.only(bottom: 70.0),
                                    child: CupertinoActivityIndicator(
                                      radius: 15.0, // Adjust the size as needed
                                    ),
                                  );
                                }
                                // Regular post item
                                else {
                                  final post = controller.posts[index];

                                  if (_postPlayStates[post['id']] == null) {
                                    _postPlayStates[post['id']] =
                                        ValueNotifier(false);
                                  }
                                  if (_postPlayStates[post['id']] == null) {
                                    _postPlayStates[post['id']] =
                                        ValueNotifier(false);
                                  }

                                  return VisibilityDetector(
                                    key: Key('post-${post['id']}-$index'),
                                    onVisibilityChanged: (info) {
                                      bool isPlaying =
                                          info.visibleFraction > 0.5;
                                      _updatePostState(post['id'], isPlaying);
                                    },
                                    child: ValueListenableBuilder<bool>(
                                      valueListenable:
                                          _postPlayStates[post['id']]!,
                                      builder: (context, isPlaying, child) {
                                        return PostComponent(
                                          post: post,
                                          isPlaying: isPlaying,
                                        );
                                      },
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: BottomNavigation(
                activePage: ActivePage.feeds,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Shimmer loading widget definition
  Widget _buildShimmerLoading() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10,
          ),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 10,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 80,
                        height: 10,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: 150,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.favorite_border,
                      color: Colors.grey[300], size: 25),
                  // const SizedBox(width: 10),
                  Icon(Icons.star_border, color: Colors.grey[300], size: 25),
                  // const SizedBox(width: 10),
                  Icon(Icons.chat_bubble_outline,
                      color: Colors.grey[300], size: 25),
                  Icon(Icons.share_outlined, color: Colors.grey[300], size: 25),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 15,
                        width: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.star, color: Colors.grey[300], size: 20),
                    ],
                  ),
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: 150,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 10,
                    width: 150,
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
