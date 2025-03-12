import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';
import 'package:larosa_block/Features/Feeds/Components/old_post_component.dart';
import 'package:larosa_block/Features/Feeds/Controllers/old_home_feeds_controller.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:larosa_block/Features/Feeds/Components/topbar.dart';
import 'package:larosa_block/Features/Feeds/Components/topbar_two.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

class OldHomeFeedsScreen extends StatefulWidget {
  const OldHomeFeedsScreen({super.key});

  @override
  State<OldHomeFeedsScreen> createState() => _OldHomeFeedsScreenState();
}

class _OldHomeFeedsScreenState extends State<OldHomeFeedsScreen> with SingleTickerProviderStateMixin {
  final Map<int, ValueNotifier<bool>> _postPlayStates = {};

  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  bool _isVisible = true;

  void _updatePostState(int postId, bool isPlaying) {
    if (_postPlayStates[postId] == null) {
      _postPlayStates[postId] = ValueNotifier(isPlaying);
    } else {
      _postPlayStates[postId]!.value = isPlaying;
    }
  }

  void _onScroll() {
    final controller = Provider.of<OldHomeFeedsController>(context, listen: false);

    if (controller.scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isVisible) {
        setState(() {
          _isVisible = false;
          _animationController.reverse(); 
        });
      }
    } else if (controller.scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isVisible) {
        setState(() {
          _isVisible = true;
          _animationController.forward(); 
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<OldHomeFeedsController>(context, listen: false);
    controller.scrollController.addListener(_onScroll);

    // Initialize animation controller and animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, -.7), // Hidden position
      end: Offset(0, 0), // Visible position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    final controller = Provider.of<OldHomeFeedsController>(context, listen: false);
    controller.scrollController.removeListener(_onScroll);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<OldHomeFeedsController>(context);

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
                SliverAppBar(
                  elevation: 0,
                  floating: false,
                  pinned: true,
                  snap: false,
                  automaticallyImplyLeading: false,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: SlideTransition(
                    position: _offsetAnimation,
                    child: Container(
                      child: const Column(
                        children: [
                          TopBar1(),
                          TopBar2(), 
                        ],
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize:
                        Size.fromHeight(Platform.isIOS ? 36.0 : 36.0),
                    child: const SizedBox.shrink(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: Platform.isIOS
                        ? const Offset(0, -210) 
                        : const Offset(
                            0, -23),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: controller.isLoading,
                      builder: (context, isLoading, child) {
                        if (isLoading && controller.posts.isEmpty) {
                          return Column(
                            children: List.generate(
                              5,
                              (index) => _buildShimmerLoading(),
                            ),
                          );
                        } else if (controller.posts.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 50.0),
                              child: CupertinoActivityIndicator(
                                radius: 15.0,
                                color: LarosaColors.primary,
                              ),
                            ),
                          );
                        } else {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 20.0, top: 0),
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
                                            12.0,
                                            color: LarosaColors.primary,
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
                                      radius: 25.0,
                                      color: LarosaColors.primary
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
                                        return OldPostCompoent(
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
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: BottomNavigation(
                activePage: ActivePage.feeds,
                scrollController: controller.scrollController,
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
          // const SizedBox(
          //   height: 10,
          // ),
          Shimmer.fromColors(
            baseColor: isDarkMode ? Colors.grey[900]! : Colors.grey[400]!,
            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
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
        ],
      ),
    );
  }
}