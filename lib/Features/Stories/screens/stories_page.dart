import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Features/Stories/providers/story_provider.dart';
import 'package:larosa_block/Features/Stories/widgets/story_viewer.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:provider/provider.dart';

class StoriesPage extends StatefulWidget {
  const StoriesPage({super.key});

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoryProvider>().fetchFollowedStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(
            CupertinoIcons.back,
          ),
        ),
        title: const Text('Stories'),
        centerTitle: true,
        actions: [
          _AddStoryButton(),
        ],
      ),
      body: SafeArea(
        child: Consumer<StoryProvider>(
          builder: (context, storyProvider, child) {
            if (storyProvider.isLoading) {
              return const Center(
                child: CupertinoActivityIndicator(),
              );
            }

            if (storyProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 48,
                      color: CupertinoColors.systemRed,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      storyProvider.error!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: () => storyProvider.fetchFollowedStories(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final userStories =
                            storyProvider.followedStories[index];
                        return _StoryAvatar(
                          userStories: userStories,
                          onTap: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => StoryViewer(
                                  userStories: userStories,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: storyProvider.followedStories.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final UserStories userStories;
  final VoidCallback onTap;

  const _StoryAvatar({
    required this.userStories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: userStories.hasUnseenStories
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF833AB4),
                        Color(0xFFF77737),
                        Color(0xFFE1306C),
                      ],
                    )
                  : null,
              border: !userStories.hasUnseenStories
                  ? Border.all(
                      color: CupertinoColors.systemGrey3,
                      width: 2,
                    )
                  : null,
            ),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: CupertinoColors.systemGrey,

              // child: Image.network(
              //   userStories.name[0],
              //   fit: BoxFit.cover,
              // ),

              child: ClipOval(
                child: CachedNetworkImage(
                  height: double.infinity,
                  width: double.infinity,
                  imageUrl: userStories.stories[0].names[0],
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) => Text(
                    userStories.name[0],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
             
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userStories.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStoryButton extends StatelessWidget {
  const _AddStoryButton();

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: () => context.pushNamed('create_story'),
      child: const Icon(CupertinoIcons.plus_circle_fill),
    );
  }
}
