import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelfImagePostsComponent extends StatefulWidget {
  final int profileId;
  const SelfImagePostsComponent({super.key, required this.profileId});

  @override
  State<SelfImagePostsComponent> createState() =>
      _SelfImagePostsComponentState();
}

class _SelfImagePostsComponentState extends State<SelfImagePostsComponent> {
  List<dynamic> imagePosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPostsFromLocalStorage();
  }

  Future<void> _loadPostsFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedPosts = prefs.getString('imagePosts_${widget.profileId}');
    if (storedPosts != null) {
      setState(() {
        imagePosts = json.decode(storedPosts);
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
        Get.snackbar('Explore Larosa', response.body);
        return;
      }

      final List<dynamic> data = json.decode(response.body);

      final List<dynamic> filteredPosts = data.where((post) {
        String firstMedia = post['names'].split(',').toList()[0];
        return !_isVideo(firstMedia);
      }).toList();

      setState(() {
        imagePosts = filteredPosts;
        _isLoading = false;
      });

      // Save the fetched posts to local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(
          'imagePosts_${widget.profileId}', json.encode(filteredPosts));
    } catch (e) {
      //HelperFunctions.displaySnackbar('Failed to fetch Strings');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isVideo(String url) {
    final mimeType = lookupMimeType(url);
    return mimeType != null && mimeType.startsWith('video/');
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
        itemCount: 6, // Show a few skeleton items while loading
        itemBuilder: (context, index) {
          return const SkeletonLoader();
        },
      );
    }

    if (imagePosts.isEmpty) {
      return const Center(
        child: Text('No posts available.'),
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

        return Animate(
          effects: const [
            ShimmerEffect(),
          ],
          child: GestureDetector(
            onTap: () {
           

            context.push(
                '/profilePosts?title=Strings&activePost=$index',
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

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    ).animate().shimmer();
  }
}
