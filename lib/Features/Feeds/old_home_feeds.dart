import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';
import 'package:larosa_block/Components/loading_shimmer.dart';
import 'package:larosa_block/Features/Feeds/Components/old_post_component.dart';
import 'package:larosa_block/Features/Feeds/Controllers/old_home_feeds_controller.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:provider/provider.dart';
import 'package:larosa_block/Features/Feeds/Components/topbar.dart';
import 'package:larosa_block/Features/Feeds/Components/topbar_two.dart';
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

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset(0, -.7),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // final controller = Provider.of<OldHomeFeedsController>(context, listen: false);
    // controller.scrollController.removeListener(_onScroll);
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
                        ? Offset(0, Platform.isIOS ? -220 : -210) 
                        : const Offset(
                            0, -23),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: controller.isLoading,
                      builder: (context, isLoading, child) {
                        if (isLoading && controller.posts.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 112.0),
                            child: Column(
                              children: List.generate(
                                12,
                                (index) => const LoadingShimmer(),
                              ),
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
  }}