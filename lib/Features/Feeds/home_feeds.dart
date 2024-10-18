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

import 'package:flutter/material.dart';
import 'package:larosa_block/Components/bottom_navigation.dart';
import 'package:larosa_block/Features/Feeds/Components/post_component.dart';
import 'package:larosa_block/Features/Feeds/Controllers/home_feeds_controller.dart';
import 'package:provider/provider.dart';
import 'package:larosa_block/Features/Feeds/Components/topbar.dart';
import 'package:larosa_block/Features/Feeds/Components/topbar_two.dart';

class HomeFeedsScreen extends StatelessWidget {
  const HomeFeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeFeedsController>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          controller.fetchPosts(true);
        },
        child: Stack(
          children: [
            CustomScrollView(
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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...controller.posts.map((post) {
                          return PostComponent(post: post);
                        }),
                        const SizedBox(height: 100),
                      ],
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
}
