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
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                elevation: 20,
                backgroundColor: Colors.blue,
                floating: true,
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(60.0),
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
              // SliverToBoxAdapter(
              //   child: SingleChildScrollView(
              //     child: Column(
              //       children: [
              //         ...controller.posts.map((post) {
              //           return PostComponent(post: post);
              //         }),
              //         const SizedBox(height: 100),
              //       ],
              //     ),
              //   ),
              // ),
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
    );
  }
}
