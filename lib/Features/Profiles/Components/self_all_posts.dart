import 'dart:convert';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/colors.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class SelfAllPosts extends StatefulWidget {
  final int profileId;
  const SelfAllPosts({super.key, required this.profileId});

  @override
  State<SelfAllPosts> createState() => _SelfAllPostsState();
}

class _SelfAllPostsState extends State<SelfAllPosts> {
  List<dynamic> posts = [];
  final Map<int, String> _videoThumbnails = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPostsFromLocalStorage();
  }

  Future<void> _loadPostsFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? postsString = prefs.getString('posts_${widget.profileId}');
    if (postsString != null) {
      setState(() {
        posts = jsonDecode(postsString);
        _isLoading = false;
      });
      // Generate video thumbnails for the locally stored posts
      for (int i = 0; i < posts.length; i++) {
        String firstMedia = posts[i]['names'].split(',').toList()[0];
        if (_isVideo(firstMedia)) {
          _generateVideoThumbnail(firstMedia, i);
        }
      }
    }
    _fetchLikedPosts(); // Fetch updated posts from the server
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
      '/feeds/fetch/specific',
    );

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'profileId': widget.profileId,
        }),
        headers: headers,
      );

      if (response.statusCode != 200) {
        //Get.snackbar('Explore Larosa', response.body);
        return;
      }
      final List<dynamic> data = json.decode(response.body);

      // Save posts to local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('posts_${widget.profileId}', jsonEncode(data));

      setState(() {
        posts = data;
        _isLoading = false;
      });

      for (int i = 0; i < posts.length; i++) {
        String firstMedia = posts[i]['names'].split(',').toList()[0];
        if (_isVideo(firstMedia)) {
          _generateVideoThumbnail(firstMedia, i);
        }
      }
    } catch (e) {
      print('An error occurred: $e');
      //Get.snackbar('Error', 'Failed to fetch posts.');
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
    if (_isLoading) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 1,
        ),
        itemCount: 6, // Show 6 skeleton items
        itemBuilder: (context, index) {
          return Animate(
            effects: const [
              ShimmerEffect(),
            ],
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      );
    }

    if (posts.isEmpty) {
      return const Center(
        child: Text(
          'Your Posts will appear here',
          style: TextStyle(
            color: LarosaColors.primary,
            fontSize: 18,
          ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        String firstMedia = posts[index]['names'].split(',').toList()[0];

        if (_isVideo(firstMedia)) {
          String? thumbnailPath = _videoThumbnails[index];
          return GestureDetector(
            onTap: () {
              context.push(
                '/profilePosts?title=Strings&activePost=$index',
                extra: posts,
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
                    )),
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
              //   Get.to(ProfilePostsScreen(
              //   title: 'Strings',
              //   posts: posts,
              //   activePost: index,
              // ))

              context.push(
                '/profilePosts?title=Strings&activePost=$index',
                extra: posts,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: firstMedia,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                placeholder: (context, url) => Image.asset(
                  'assets/gifs/loader.gif',
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
