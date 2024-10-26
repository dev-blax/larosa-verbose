import 'package:flutter/material.dart';

class HomeFeedsController with ChangeNotifier {
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final List<Map<String, dynamic>> posts = []; // Assuming your posts structure is like this
  final Map<int, bool> _postPlayStates = {}; // Map to track play/pause state of each post

  Future<void> fetchPosts(bool refresh) async {
    isLoading.value = true;
    // Fetch posts logic here
    // For now, simulate a delay
    await Future.delayed(const Duration(seconds: 2));
    // Populate the 'posts' list with your fetched data
    isLoading.value = false;
  }

  // Method to get the play/pause state of a post
  bool getPostState(int postId) {
    return _postPlayStates[postId] ?? false; // Default to false if not set
  }

  // Method to update the play/pause state of a post
  void updatePostState(int postId, bool isPlaying) {
    _postPlayStates[postId] = isPlaying;
    notifyListeners(); // Notify listeners to update the UI
  }
}
