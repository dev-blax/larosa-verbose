import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:mime/mime.dart';

class ImagePostsComponent extends StatefulWidget {
  final int profileId;
  const ImagePostsComponent({super.key, required this.profileId});

  @override
  State<ImagePostsComponent> createState() => _ImagePostsComponentState();
}

class _ImagePostsComponentState extends State<ImagePostsComponent> {
  List<dynamic> imagePosts = [];

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
        // Get.snackbar('Explore Larosa', response.body);
        return;
      }

      final List<dynamic> data = json.decode(response.body);
      print('posts: $data');

      // Filter out videos and keep only images
      setState(() {
        imagePosts = data.where((post) {
          String firstMedia = post['names'].split(',').toList()[0];
          return !_isVideo(firstMedia);
        }).toList();
      });
    } catch (e) {
      print('Do something');
    }
  }

  bool _isVideo(String url) {
    final mimeType = lookupMimeType(url);
    return mimeType != null && mimeType.startsWith('video/');
  }

  @override
  void initState() {
    _fetchLikedPosts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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

        return Animate(
          effects: const [
            ShimmerEffect(),
          ],
          child: GestureDetector(
            onTap: () {
              context.push(
                '/profilePosts?title=Posts&activePost=$index',
                extra: imagePosts,
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
