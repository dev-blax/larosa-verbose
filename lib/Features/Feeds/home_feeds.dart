// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:larosa_block/Components/bottom_navigation.dart';
// import 'package:larosa_block/Features/Feeds/Components/post_component.dart';
// import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';
// import 'package:provider/provider.dart';
// import 'package:larosa_block/Features/Feeds/Components/topbar.dart';
// import 'package:larosa_block/Features/Feeds/Components/topbar_two.dart';

// class HomeFeedsScreen extends StatefulWidget {
//   const HomeFeedsScreen({super.key});

//   @override
//   _HomeFeedsScreenState createState() => _HomeFeedsScreenState();
// }

// class _HomeFeedsScreenState extends State<HomeFeedsScreen> {
//   late ScrollController _scrollController;

//   @override
//   void initState() {
//     super.initState();
//     _scrollController = ScrollController();
//     _scrollController.addListener(_onScroll);
//   }

//   void _onScroll() {
//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 200) {
//       // Fetch more posts when user reaches near the end
//       final controller =
//           Provider.of<HomeFeedsController>(context, listen: false);
//       controller.fetchMorePosts();
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = Provider.of<HomeFeedsController>(context);

//     return RefreshIndicator(
//       onRefresh: () async {
//         controller.fetchPosts(true);
//       },
//       child: Scaffold(
//         body: Stack(
//           children: [
//             CustomScrollView(
//               controller: _scrollController,
//               slivers: [
//                 SliverAppBar(
//                   elevation: 20,
//                   backgroundColor: Colors.blue,
//                   floating: true,
//                   bottom: const PreferredSize(
//                     preferredSize: Size.fromHeight(60.0),
//                     child: Text(''),
//                   ),
//                   automaticallyImplyLeading: false,
//                   flexibleSpace: Container(
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).scaffoldBackgroundColor,
//                     ),
//                     child: const Column(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         TopBar1(),
//                         TopBar2(),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SliverList(
//                   delegate: SliverChildBuilderDelegate(
//                     (context, index) {
//                       if (index < controller.posts.length) {
//                         return PostComponent(post: controller.posts[index]);
//                       } else {
//                         return const Center(
//                           child: Padding(
//                             padding: EdgeInsets.all(16.0),
//                             child: SpinKitCircle(
//                               color: Colors.blue,
//                             ),
//                           ),
//                         );
//                       }
//                     },
//                     childCount: controller.posts.length + 1,
//                   ),
//                 ),
//               ],
//             ),
//             const Positioned(
//               bottom: 10,
//               left: 10,
//               right: 10,
//               child: BottomNavigation(
//                 activePage: ActivePage.feeds,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//START

// import 'package:flutter/material.dart';
// import 'package:larosa_block/Components/bottom_navigation.dart';
// import 'package:larosa_block/Features/Feeds/Components/post_component.dart';
// import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';
// import 'package:provider/provider.dart';
// import 'package:larosa_block/Features/Feeds/Components/topbar.dart';
// import 'package:larosa_block/Features/Feeds/Components/topbar_two.dart';

// class HomeFeedsScreen extends StatelessWidget {
//   const HomeFeedsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final controller = Provider.of<HomeFeedsController>(context);

//     return Scaffold(
//       body: RefreshIndicator(
//         onRefresh: () async {
//           controller.fetchPosts(true);
//         },
//         child: Stack(
//           children: [
//             CustomScrollView(
//               slivers: [
//                 SliverAppBar(
//                   elevation: 20,
//                   backgroundColor: Colors.blue,
//                   floating: true,
//                   bottom: const PreferredSize(
//                     preferredSize: Size.fromHeight(35.0),
//                     child: Text(''),
//                   ),
//                   automaticallyImplyLeading: false,
//                   flexibleSpace: Container(
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).scaffoldBackgroundColor,
//                     ),
//                     child: const Column(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         TopBar1(),
//                         TopBar2(),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SliverToBoxAdapter(
//                   child: SingleChildScrollView(
//                     child: Column(
//                       children: [
//                         ...controller.posts.map((post) {
//                           return PostComponent(post: post);
//                         }),
//                         const SizedBox(height: 100),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const Positioned(
//               bottom: 10,
//               left: 10,
//               right: 10,
//               child: BottomNavigation(
//                 activePage: ActivePage.feeds,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

//END

// import 'package:cached_video_player_plus/cached_video_player_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:larosa_block/Components/bottom_navigation.dart';
// import 'package:larosa_block/Features/Feeds/Components/post_component.dart';
// import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';
// import 'package:provider/provider.dart';
// import 'package:larosa_block/Features/Feeds/Components/topbar.dart';
// import 'package:larosa_block/Features/Feeds/Components/topbar_two.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:visibility_detector/visibility_detector.dart';
// import 'Controllers/video_controller.dart';
// class HomeFeedsScreen extends StatelessWidget {
//   const HomeFeedsScreen({super.key});

//   bool _isVideo(String contentType) {
//     return contentType.startsWith('video/');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = Provider.of<HomeFeedsController>(context);
//     final VideoController videoController = Get.put(VideoController());

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: RefreshIndicator(
//         onRefresh: () async {
//           await controller.fetchPosts(true);
//         },
//         child: Stack(
//           children: [
//             CustomScrollView(
//               slivers: [
//                 SliverAppBar(
//                   elevation: 20,
//                   backgroundColor: Colors.blue,
//                   floating: true,
//                   bottom: const PreferredSize(
//                     preferredSize: Size.fromHeight(35.0),
//                     child: Text(''),
//                   ),
//                   automaticallyImplyLeading: false,
//                   flexibleSpace: Container(
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).scaffoldBackgroundColor,
//                     ),
//                     child: const Column(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         TopBar1(),
//                         TopBar2(),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SliverToBoxAdapter(
//                   child: ValueListenableBuilder<bool>(
//                     valueListenable: controller.isLoading,
//                     builder: (context, isLoading, child) {
//                       if (isLoading) {
//                         return _buildShimmerLoading();
//                       } else if (controller.posts.isEmpty) {
//                         return const Center(
//                           child: Padding(
//                             padding: EdgeInsets.only(top: 50.0),
//                             child: Text('No posts available'),
//                           ),
//                         );
//                       } else {
//                         return SingleChildScrollView(
//                           child: Column(
//                             children: [
//                               ...controller.posts.map((post) {
//                                 String contentType = post['contentTypes'] ?? '';
//                                 bool isVideo = _isVideo(contentType);

//                                 if (isVideo) {
//                                   final videoControllerInstance =
//                                       CachedVideoPlayerPlusController.networkUrl(Uri.parse(post['names']));
//                                   videoController.addVideoController(post['id'], videoControllerInstance);
//                                 }

//                                 return VisibilityDetector(
//                                   key: Key('post-${post['id']}'),
//                                   onVisibilityChanged: (info) {
//                                     if (info.visibleFraction > 0.5) {
//                                       print('Post ID ${post['id']} is in view');

//                                       // Check if the post is a video before playing
//                                       if (isVideo) {
//                                         videoController.playVideo(post['id']);
//                                       }
//                                     } else {
//                                       print('Post ID ${post['id']} is out of view');

//                                       // Check if the post is a video before pausing
//                                       if (isVideo) {
//                                         videoController.pauseVideo(post['id']);
//                                       }
//                                     }
//                                   },
//                                   child: Column(
//                                     children: [
//                                       PostComponent(post: post),
//                                     ],
//                                   ),
//                                 );
//                               }),
//                               const SizedBox(height: 100),
//                             ],
//                           ),
//                         );
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const Positioned(
//               bottom: 10,
//               left: 10,
//               right: 10,
//               child: BottomNavigation(
//                 activePage: ActivePage.feeds,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Shimmer loading widget definition
//   Widget _buildShimmerLoading() {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Shimmer.fromColors(
//             baseColor: Colors.grey[900]!,
//             highlightColor: Colors.grey[700]!,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.grey[300],
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         width: 120,
//                         height: 10,
//                         color: Colors.grey[300],
//                       ),
//                       const SizedBox(height: 5),
//                       Container(
//                         width: 80,
//                         height: 10,
//                         color: Colors.grey[300],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Shimmer.fromColors(
//             baseColor: Colors.grey[900]!,
//             highlightColor: Colors.grey[700]!,
//             child: Container(
//               height: 300,
//               margin: const EdgeInsets.symmetric(horizontal: 16.0),
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Shimmer.fromColors(
//             baseColor: Colors.grey[900]!,
//             highlightColor: Colors.grey[700]!,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: 10,
//                     width: double.infinity,
//                     color: Colors.grey[300],
//                   ),
//                   const SizedBox(height: 5),
//                   Container(
//                     height: 10,
//                     width: double.infinity,
//                     color: Colors.grey[300],
//                   ),
//                   const SizedBox(height: 5),
//                   Container(
//                     height: 10,
//                     width: 150,
//                     color: Colors.grey[300],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// import 'package:cached_video_player_plus/cached_video_player_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:larosa_block/Components/bottom_navigation.dart';
// import 'package:larosa_block/Features/Feeds/Components/post_component.dart';
// import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';
// import 'package:provider/provider.dart';
// import 'package:larosa_block/Features/Feeds/Components/topbar.dart';
// import 'package:larosa_block/Features/Feeds/Components/topbar_two.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:visibility_detector/visibility_detector.dart';

// class HomeFeedsScreen extends StatelessWidget {
//   const HomeFeedsScreen({super.key});

//   bool _isVideo(String contentType) {
//     return contentType.startsWith('video/');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final controller = Provider.of<HomeFeedsController>(context);

//     final Map<int, bool> _postPlayStates =
//       {}; // Track play/pause state of each post

//       void updatePostState(int postId, bool isPlaying) {
//     _postPlayStates[postId] = isPlaying;
//   }

//   // Manage the play/pause state of posts
//   bool getPostState(int postId) {
//     return _postPlayStates[postId] ?? false; // Default to paused if not set
//   }

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: RefreshIndicator(
//         onRefresh: () async {
//           await controller.fetchPosts(true);
//         },
//         child: Stack(
//           children: [
//             CustomScrollView(
//               slivers: [
//                 SliverAppBar(
//                   elevation: 20,
//                   backgroundColor: Colors.blue,
//                   floating: true,
//                   bottom: const PreferredSize(
//                     preferredSize: Size.fromHeight(35.0),
//                     child: Text(''),
//                   ),
//                   automaticallyImplyLeading: false,
//                   flexibleSpace: Container(
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).scaffoldBackgroundColor,
//                     ),
//                     child: const Column(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         TopBar1(),
//                         TopBar2(),
//                       ],
//                     ),
//                   ),
//                 ),
//                 SliverToBoxAdapter(
//                   child: ValueListenableBuilder<bool>(
//                     valueListenable: controller.isLoading,
//                     builder: (context, isLoading, child) {
//                       if (isLoading) {
//                         return _buildShimmerLoading();
//                       } else if (controller.posts.isEmpty) {
//                         return const Center(
//                           child: Padding(
//                             padding: EdgeInsets.only(top: 50.0),
//                             child: Text('No posts available'),
//                           ),
//                         );
//                       } else {
//                         return SingleChildScrollView(
//                           child: Column(
//                             children: [
//                               ...controller.posts.map((post) {
//                                 String contentType = post['contentTypes'] ?? '';
//                                 bool isVideo = _isVideo(contentType);
//                                 bool isPlaying = false;

//                                 return VisibilityDetector(
//                                   key: Key('post-${post['id']}'),
//                                   onVisibilityChanged: (info) {
//                                     if (info.visibleFraction > 0.5) {
//                                       print('Post ID ${post['id']} is in view');
//                                       isPlaying = true;
//                                     } else {
//                                       print('Post ID ${post['id']} is out of view');
//                                       isPlaying = false;
//                                     }

//                                     // Pass the state to the PostComponent using setState if needed
//                                     updatePostState(post['id'], isPlaying);
//                                   },
//                                   child: Column(
//                                     children: [
//                                       PostComponent(
//                                         post: post,
//                                         isPlaying: getPostState(post['id']),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               }),
//                               const SizedBox(height: 100),
//                             ],
//                           ),
//                         );
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const Positioned(
//               bottom: 10,
//               left: 10,
//               right: 10,
//               child: BottomNavigation(
//                 activePage: ActivePage.feeds,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Shimmer loading widget definition
//   Widget _buildShimmerLoading() {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Shimmer.fromColors(
//               baseColor: Colors.grey[900]!,
//               highlightColor: Colors.grey[700]!,
//               child: Row(
//                 children: [
//                   Container(
//                     width: 40,
//                     height: 40,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: Colors.grey[300],
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         width: 120,
//                         height: 10,
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       Container(
//                         width: 80,
//                         height: 10,
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Shimmer.fromColors(
//               baseColor: Colors.grey[900]!,
//               highlightColor: Colors.grey[700]!,
//               child: Container(
//                 height: 300,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Shimmer.fromColors(
//               baseColor: Colors.grey[900]!,
//               highlightColor: Colors.grey[700]!,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     height: 10,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(5),
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Container(
//                     height: 10,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(5),
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Container(
//                     height: 10,
//                     width: 150,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[300],
//                       borderRadius: BorderRadius.circular(5),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }






import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';
import 'package:larosa_block/Features/Feeds/Components/post_component.dart';
import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';
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

  bool _isVideo(String contentType) {
    return contentType.startsWith('video/');
  }

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
        onRefresh: () async {
          await controller.fetchPosts(true);
        },
        child: Stack(
          children: [
            CustomScrollView(
              controller: controller.scrollController,
              slivers: [
                SliverAppBar(
                  elevation: 20,
                  backgroundColor: Colors.blue,
                  floating: true,
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(35.0),
                    child: Text(''),
                  ),
                  automaticallyImplyLeading: false,
                  flexibleSpace: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        TopBar1(),
                        TopBar2(),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: controller.isLoading,
                    builder: (context, isLoading, child) {
                      if (isLoading && controller.posts.isEmpty) {
                        return _buildShimmerLoading();
                      } else if (controller.posts.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50.0),
                            child: Text('No posts available'),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 100.0),
                          child: ListView.builder(
                            itemCount: controller.posts.length + (controller.isFetchingMore ? 1 : 0),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              if (index < controller.posts.length) {
                                final post = controller.posts[index];
                          
                                if (_postPlayStates[post['id']] == null) {
                                  _postPlayStates[post['id']] = ValueNotifier(false);
                                }
                          
                                return VisibilityDetector(
                                  key: Key('post-${post['id']}-${index}'), // Unique key for each post
                                  onVisibilityChanged: (info) {
                                    bool isPlaying = info.visibleFraction > 0.5;
                                    _updatePostState(post['id'], isPlaying);
                                  },
                                  child: ValueListenableBuilder<bool>(
                                    valueListenable: _postPlayStates[post['id']]!,
                                    builder: (context, isPlaying, child) {
                                      return PostComponent(
                                        post: post,
                                        isPlaying: isPlaying,
                                      );
                                    },
                                  ),
                                );
                              } else {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom:100.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[900]!,
            highlightColor: Colors.grey[700]!,
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
            baseColor: Colors.grey[900]!,
            highlightColor: Colors.grey[700]!,
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
            baseColor: Colors.grey[900]!,
            highlightColor: Colors.grey[700]!,
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
            baseColor: Colors.grey[900]!,
            highlightColor: Colors.grey[700]!,
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
            baseColor: Colors.grey[900]!,
            highlightColor: Colors.grey[700]!,
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
            baseColor: Colors.grey[900]!,
            highlightColor: Colors.grey[700]!,
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
