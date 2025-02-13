import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Features/Feeds/Components/post_details.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'post_interact.dart';

class ImageViewScreen extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String displayName;
  final dynamic postDetails;
  const ImageViewScreen(
      {super.key,
      required this.imageUrls,
      required this.initialIndex,
      required this.displayName,
      required this.postDetails});

  @override
  State<ImageViewScreen> createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            CupertinoIcons.back,
          ),
        ),
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: widget.imageUrls.length,
            pageController: PageController(initialPage: currentIndex),
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider:
                    CachedNetworkImageProvider(widget.imageUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),

          // Post details
          if (widget.postDetails != null)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  PostInteract(post: widget.postDetails),
                  Gap(10),
                  PostDetails(
                    caption: widget.postDetails['caption'],
                    username: widget.postDetails['username'],
                    date: widget.postDetails['duration'],
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}

