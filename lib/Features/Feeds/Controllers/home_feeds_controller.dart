import 'package:flutter/material.dart';
import 'package:larosa_block/Features/Feeds/Models/cached_post.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Services/hive_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:larosa_block/Services/log_service.dart';
import '../../../Utils/links.dart';

class HomeFeedsController extends ChangeNotifier {
  final DioService _dioService = DioService();
  final HiveService _hiveService = HiveService();
  static const String _boxName = 'cached_posts';
  
  List<dynamic> _posts = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _itemsPerPage = 3;
  bool _isOffline = false;

  List<dynamic> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get hasMore => _hasMore;
  bool get isOffline => _isOffline;

  HomeFeedsController() {
    _initConnectivityListener();
    _initHive();
  }

  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CachedPostAdapter());
    }
    await _hiveService.openBox<CachedPost>(_boxName);
  }

  void _initConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((event) async {
      final wasOffline = _isOffline;
      _isOffline = event == ConnectivityResult.none;
      
      // If we're coming back online and had been offline, try to fetch fresh content
      if (wasOffline && !_isOffline) {
        await refreshPosts();
      }
      notifyListeners();
    });
  }

  Future<void> fetchPosts({bool refresh = false}) async {
    if (_isLoading) return;
    
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _posts = [];
    } else if (!_hasMore) {
      return;
    }

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _isOffline = connectivityResult == ConnectivityResult.none;

      if (_isOffline) {
        LogService.logInfo('we are offline');
        // Load from Hive cache if offline
        final box = await _hiveService.openBox<CachedPost>(_boxName);
        final cachedPosts = box.values
            .skip((_currentPage - 1) * _itemsPerPage)
            .take(_itemsPerPage)
            .map((post) => post.toJson())
            .toList();
        
        if (refresh) {
          _posts = cachedPosts;
        } else {
          _posts.addAll(cachedPosts);
        }
        
        _hasMore = cachedPosts.length == _itemsPerPage;
      } else {
        // Load from network if online
        final response = await _dioService.dio.post(
          '${LarosaLinks.baseurl}/feeds/fetch',
          data: {
            'countryId': 1,
            'page': _currentPage,
            'itemsPerPage': _itemsPerPage,
          },
        );

        if (response.statusCode == 200) {
          final newPosts = response.data as List;          
          
          // Cache the new posts in Hive
          final box = await _hiveService.openBox<CachedPost>(_boxName);
          for (var post in newPosts) {
            final cachedPost = CachedPost.fromJson(post);
            await box.put(cachedPost.id, cachedPost);
          }
          
          if (refresh) {
            _posts = newPosts;
          } else {
            _posts.addAll(newPosts);
          }
          
          _hasMore = newPosts.length == _itemsPerPage;
        } else {
          LogService.logError('Failed to fetch posts: ${response.statusCode}');
        }
      }

      _currentPage++;
    } catch (e) {
      _hasError = true;
      // If error occurs and we're not offline, try loading from cache
      if (!_isOffline) {
        try {
          final box = await _hiveService.openBox<CachedPost>(_boxName);
          final cachedPosts = box.values
              .skip((_currentPage - 1) * _itemsPerPage)
              .take(_itemsPerPage)
              .map((post) => post.toJson())
              .toList();
          
          if (refresh) {
            _posts = cachedPosts;
          } else {
            _posts.addAll(cachedPosts);
          }
          
          _hasMore = cachedPosts.length == _itemsPerPage;
          _hasError = false; // Clear error if we successfully loaded from cache
        } catch (cacheError) {
          // If both network and cache fail, keep error state
          _hasError = true;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPosts() async {
    // Clear old cache before refreshing
    final box = await _hiveService.openBox<CachedPost>(_boxName);
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final oldPosts = box.values.where((post) => post.timestamp < thirtyDaysAgo);
    for (var post in oldPosts) {
      await box.delete(post.id);
    }
    return fetchPosts(refresh: true);
  }
}
