import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OldHomeFeedsController extends ChangeNotifier {
  List<dynamic> _posts = [];
  List<dynamic> get posts => _posts;
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ScrollController scrollController = ScrollController();
  final Map<int, bool> _postPlayStates = {};
  final DioService _dioService = DioService();
  bool isFetchingMore = false;
  int currentPage = 0; 
  final int itemsPerPage = 10;

  OldHomeFeedsController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
      if (_posts.isEmpty) {
        fetchPosts(false);
      }
    });

    scrollController.addListener(() {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      final twoPostsHeight = 800.0;
      
      if (maxScroll - currentScroll <= twoPostsHeight) {
        fetchMorePosts();
      }
    });
  }

  Future<void> fetchPosts(bool refresh) async {
    if (refresh) {
      currentPage = 0; 
      LogService.logError('clearing');
      _posts.clear(); 
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
  Map<String, dynamic> body = {
    'countryId': '1',
    'page': currentPage.toString(),
    'itemsPerPage': itemsPerPage.toString(),
  };

  if (profileId != null) {
    body['profileId'] = profileId.toString();
  }

  try {


    final response = await _dioService.dio.post(
      LarosaLinks.allFeeds,
      data: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = response.data;
      if (isPaginated) {
        _posts.addAll(data);
        currentPage++;
      } else {
        _posts = data;
      }

      await _savePostsToLocalStorage(_posts);
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
      _posts = jsonDecode(postsString);
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
