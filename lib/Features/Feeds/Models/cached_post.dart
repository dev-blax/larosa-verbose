import 'package:hive/hive.dart';

part 'cached_post.g.dart';

@HiveType(typeId: 1)
class CachedPost {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Map<String, dynamic> data;

  @HiveField(2)
  final int timestamp;

  @HiveField(3)
  final String mediaUrls;

  CachedPost({
    required this.id,
    required this.data,
    required this.timestamp,
    required this.mediaUrls,
  });

  factory CachedPost.fromJson(Map<String, dynamic> json) {
    return CachedPost(
      id: json['id'].toString(),
      data: json,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      mediaUrls: json['names'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => data;
}
