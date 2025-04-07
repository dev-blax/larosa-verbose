import 'package:dio/dio.dart' as Dio;
import 'package:flutter/foundation.dart';
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:http_parser/http_parser.dart' as parser;

class Story {
  final int storyId;
  final List<String> captions;
  final List<String> names;
  final DateTime time;

  Story({
    required this.storyId,
    required this.captions,
    required this.names,
    required this.time,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      storyId: json['id'],
      captions: List<String>.from(json['captions']),
      names: List<String>.from(json['names']),
      time: DateTime.parse(json['time']),
    );
  }
}

class UserStories {
  final int profileId;
  final String name;
  final String username;
  final List<Story> stories;
  bool hasUnseenStories;

  UserStories({
    required this.profileId,
    required this.name,
    required this.username,
    required this.stories,
    this.hasUnseenStories = true,
  });

  factory UserStories.fromJson(Map<String, dynamic> json) {
    return UserStories(
      profileId: json['profileId'],
      name: json['name'],
      username: json['username'],
      stories: (json['stories'] as List)
          .map((story) => Story.fromJson(story))
          .toList(),
    );
  }
}

class StoryProvider extends ChangeNotifier {
  final DioService _dioService = DioService();
  List<UserStories> _followedStories = [];
  bool _isLoading = false;
  String? _error;

  List<UserStories> get followedStories => _followedStories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFollowedStories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      LogService.logInfo('Fetching followed stories');
      final response = await _dioService.dio.get(
        '${LarosaLinks.baseurl}/story/user/followed-stories',
      );

      LogService.logInfo('Fetched followed stories');
      LogService.logInfo('Response: ${response.data}');

      if (response.statusCode == 200) {
        _followedStories = (response.data as List)
            .map((json) => UserStories.fromJson(json))
            .toList();
      }
    } catch (e) {
      LogService.logError('Error fetching stories: $e');
      _error = 'Failed to load stories';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadStory(List<String> filePaths, List<String> captions) async {
    try {
      final formData = Dio.FormData();

      for (var i = 0; i < filePaths.length; i++) {
        formData.files.add(
          MapEntry(
            'file',
            await Dio.MultipartFile.fromFile(
              filePaths[i],
              contentType: parser.MediaType("image", "*"),
            ),
          ),
        );
        formData.fields.add(
          MapEntry('caption', captions[i]),
        );
      }

      LogService.logInfo('Uploading story with ${formData.files.length} files');
      
      final response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/story/upload',
        data: formData,
      );

      if (response.statusCode == 201) {
        await fetchFollowedStories();
        LogService.logInfo('Story uploaded successfully');
        return true;
      } 

      LogService.logError('Failed to upload story: ${response.data}');
      return false;
    } catch (e) {
      LogService.logError('Error uploading story: $e');
      return false;
    }
  }

  Future<bool> deleteStory(int storyId) async {
    try {
      final response = await _dioService.dio.delete(
        '${LarosaLinks.baseurl}/story/delete/$storyId',
        data: {'profileId': AuthService.getProfileId()},
      );

      if (response.statusCode == 200) {
        await fetchFollowedStories();
        return true;
      }
      return false;
    } catch (e) {
      LogService.logError('Error deleting story: $e');
      return false;
    }
  }

  void markStoriesAsSeen(int profileId) {
    final userStoriesIndex =
        _followedStories.indexWhere((user) => user.profileId == profileId);
    if (userStoriesIndex != -1) {
      _followedStories[userStoriesIndex].hasUnseenStories = false;
      notifyListeners();
    }
  }
}
