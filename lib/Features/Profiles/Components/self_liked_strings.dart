import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class SelfLikedStringsComponent extends StatefulWidget {
  final int profileId;
  const SelfLikedStringsComponent({super.key, required this.profileId});

  @override
  State<SelfLikedStringsComponent> createState() =>
      _SelfLikedStringsComponentState();
}

class _SelfLikedStringsComponentState extends State<SelfLikedStringsComponent> {
  List<dynamic> imagePosts = [];
  final Map<int, String> _videoThumbnails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPostsFromLocalStorage();
  }

  Future<void> _loadPostsFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? postsJson = prefs.getString('likedPosts');

    if (postsJson != null) {
      setState(() {
        imagePosts = json.decode(postsJson);
        _isLoading = false;
      });
    }

    _fetchLikedPosts();
  }

  Future<void> _fetchLikedPosts() async {
    String token = AuthService.getToken();
    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
    };

    var url = Uri.https(
      LarosaLinks.nakedBaseUrl,
      '/feeds/fetch/liked-posts',
    );

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'profileId': widget.profileId,
          'pageNumber': 0,
        }),
        headers: headers,
      );

      if (response.statusCode != 200) {
        //Get.snackbar('Explore Larosa', response.body);
        return;
      }

      final List<dynamic> data = json.decode(response.body);

      // Filter out only image posts
      setState(() {
        imagePosts = data.where((post) {
          String firstMedia = post['names'].split(',').toList()[0];
          return !_isVideo(firstMedia);
        }).toList();
      });

      // Save to local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('likedPosts', json.encode(imagePosts));

      // Generate thumbnails for videos
      for (int i = 0; i < imagePosts.length; i++) {
        String firstMedia = imagePosts[i]['names'].split(',').toList()[0];
        if (_isVideo(firstMedia)) {
          _generateVideoThumbnail(firstMedia, i);
        }
      }
    } catch (e) {
      //HelperFunctions.displaySnackbar('');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isVideo(String url) {
    final mimeType = lookupMimeType(url);
    return mimeType != null && mimeType.startsWith('video/');
  }

  Future<void> _generateVideoThumbnail(String url, int index) async {
    final directory = await getTemporaryDirectory();
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: url,
      thumbnailPath: directory.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 640,
      quality: 90,
    );

    if (thumbnailPath != null) {
      setState(() {
        _videoThumbnails[index] = thumbnailPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && imagePosts.isEmpty) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 1,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return const ShimmerEffectSkeleton();
        },
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1,
      ),
      itemCount: imagePosts.length,
      itemBuilder: (context, index) {
        String firstMedia = imagePosts[index]['names'].split(',').toList()[0];

        if (_isVideo(firstMedia)) {
          String? thumbnailPath = _videoThumbnails[index];
          return GestureDetector(
            onTap: () {
              //   => Get.to(ProfilePostsScreen(
              //   title: 'Liked Strings',
              //   posts: imagePosts,
              //   activePost: index,
              // ))

              context.push(
                '/profilePosts?title=LikedStrings&activePost=$index',
                extra: imagePosts,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  if (thumbnailPath != null)
                    Image.file(
                      File(thumbnailPath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  else
                    const Center(
                      child: SpinKitCircle(
                        color: LarosaColors.primary,
                      ),
                    ),
                  // Play icon overlay
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset(
                      'assets/svg_icons/reels.svg',
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.secondary,
                        BlendMode.srcIn,
                      ),
                      height: 25,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Animate(
          effects: const [
            ShimmerEffect(),
          ],
          child: GestureDetector(
            onTap: () {
              context.push(
                '/profilePosts?title=Liked Strings&activePost=$index',
                extra: imagePosts,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: firstMedia,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                placeholder: (context, url) => CupertinoActivityIndicator(color: LarosaColors.primary,),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerEffectSkeleton extends StatelessWidget {
  const ShimmerEffectSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
      ),
    ).animate().shimmer();
  }
}
