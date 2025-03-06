import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'larosa_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE cached_posts(
            id TEXT PRIMARY KEY,
            data TEXT,
            timestamp INTEGER,
            media_urls TEXT,
            media_files TEXT
          )
        ''');
      },
    );
  }

  Future<void> cachePosts(List<dynamic> posts) async {
    final db = await database;
    final batch = db.batch();

    for (var post in posts) {
      batch.insert(
        'cached_posts',
        {
          'id': post['id'].toString(),
          'data': jsonEncode(post),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'media_urls': post['names'] ?? '',
          'media_files': '' // Will be updated when media is downloaded
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List> getCachedPosts({int limit = 10, int offset = 0}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_posts',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) {
      final data = jsonDecode(map['data']);
      return data;
    }).toList();
  }

  Future<void> clearOldCache() async {
    final db = await database;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    await db.delete(
      'cached_posts',
      where: 'timestamp < ?',
      whereArgs: [thirtyDaysAgo],
    );
  }
}
