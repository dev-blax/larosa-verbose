import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:larosa_block/Features/Feeds/Components/post_component.dart';

class ProfilePostsScreen extends StatefulWidget {
  final List<dynamic> posts;
  final int activePost;
  final String title;
  const ProfilePostsScreen({
    super.key,
    required this.posts,
    required this.activePost, required this.title,
  });

  @override
  State<ProfilePostsScreen> createState() => _ProfilePostsScreenState();
}

class _ProfilePostsScreenState extends State<ProfilePostsScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActivePost();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActivePost() {
    double offset = 0.0;
    for (int i = 0; i < widget.activePost; i++) {
      final context = _getContextForIndex(i);
      if (context != null) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        offset += box.size.height;
      }
    }
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  BuildContext? _getContextForIndex(int index) {
    final key = _postKeys[index];
    return key.currentContext;
  }

  final List<GlobalKey> _postKeys = [];

  @override
  Widget build(BuildContext context) {
    // Create a GlobalKey for each post
    _postKeys.clear();
    for (int i = 0; i < widget.posts.length; i++) {
      _postKeys.add(GlobalKey());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black38,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Iconsax.arrow_left_2,
          ),
        ),
        title:  Text(widget.title, style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...widget.posts.map((post) {
                    return PostComponent(post: post);
                  }),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          // SliverList(
          //   delegate: SliverChildBuilderDelegate(
          //     (context, index) {
          //       final post = widget.posts[index];
          //       return Container(
          //         key: _postKeys[index],
          //         child: PostComponent(post: post),
          //       );
          //     },
          //     childCount: widget.posts.length,
          //   ),
          // ),
        ],
      ),
    );
  }
}
