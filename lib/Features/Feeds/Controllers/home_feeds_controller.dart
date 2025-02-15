import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeFeedsController extends ChangeNotifier {
  List<dynamic> posts = [];
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();
  final Map<int, bool> _postPlayStates = {}; // Track play/pause state of each post
  bool isFetchingMore = false;
  int currentPage = 0; // Start from 0 as you mentioned
  final int itemsPerPage = 10;

  HomeFeedsController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
      if (posts.isEmpty) {
        fetchPosts(false);
      }
    });

    // Listen for scroll events to detect when the user reaches the bottom
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        fetchMorePosts();
      }
    });
  }

  Future<void> fetchPosts(bool refresh) async {
    if (refresh) {
      currentPage = 0; // Reset to 0 when refreshing
      LogService.logError('clearing');
      posts.clear(); // Clear existing posts when refreshing
    }
    try {
      isLoading.value = true;
      final int? profileId = AuthService.getProfileId();
      await _fetchPostsFromServer(profileId);
    } catch (e) {
      await _loadPostsFromLocalStorage();
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> fetchMorePosts() async {
    if (isFetchingMore) return;

    try {
      isFetchingMore = true;
      final int? profileId = AuthService.getProfileId();
      await _fetchPostsFromServer(profileId, isPaginated: true);
    } catch (e) {
      LogService.logError('Error fetching more posts: $e');
    } finally {
      isFetchingMore = false;
      notifyListeners();
    }
  }

  Future<void> _fetchPostsFromServer(int? profileId, {bool isPaginated = false}) async {
  String token = AuthService.getToken();
  Map<String, String> headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    'Authorization': token.isNotEmpty ? 'Bearer $token' : '',
  };

  var url = Uri.https(LarosaLinks.nakedBaseUrl, LarosaLinks.allFeeds);

  Map<String, dynamic> body = {
    'countryId': '1',
    'page': currentPage.toString(),
    'itemsPerPage': itemsPerPage.toString(),
  };

  if (profileId != null) {
    body['profileId'] = profileId.toString();
  }

  try {
    final response = await http.post(
      url,
      body: jsonEncode(body),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      if (isPaginated) {
        posts.addAll(data);
        currentPage++;
      } else {
        posts = data;
      }

      await _savePostsToLocalStorage(posts);
      notifyListeners();
    } else if (response.statusCode == 302 || response.statusCode == 403 || response.statusCode == 401) {
      bool refreshed = await AuthService.booleanRefreshToken();

      if(refreshed){
        await _fetchPostsFromServer(profileId, isPaginated: isPaginated);
      }else{
        throw Exception('Failed to refresh token');
        //await HelperFunctions.logout();
      }
      
    } else {
      throw Exception('Failed to load posts');
    }
  } catch (e) {
    LogService.logError('Error fetching posts: $e');
    throw Exception('Failed to load posts');
  }
}


  Future<void> _savePostsToLocalStorage(List<dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('posts', jsonEncode(data));
  }

  Future<void> _loadPostsFromLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? postsString = prefs.getString('posts');
    if (postsString != null) {
      posts = jsonDecode(postsString);
      notifyListeners();
    }
  }

  Future<void> _saveScrollPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('scrollPosition', scrollController.offset);
  }

  Future<void> _restoreScrollPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? scrollPosition = prefs.getDouble('scrollPosition');
    if (scrollPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollController.jumpTo(scrollPosition);
      });
    }
  }

  void updatePostState(int postId, bool isPlaying) {
    _postPlayStates[postId] = isPlaying;
    notifyListeners();
  }

  // Manage the play/pause state of posts
  bool getPostState(int postId) {
    return _postPlayStates[postId] ?? false; // Default to paused if not set
  }

  @override
  void dispose() {
    _saveScrollPosition();
    super.dispose();
  }
}
