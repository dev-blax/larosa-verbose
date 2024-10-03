import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();

  factory HiveService() {
    return _instance;
  }

  HiveService._internal();

  Future<void> init() async {
    await Hive.initFlutter();
  }

  Future<Box<T>> openBox<T>(String boxName) async {
    return await Hive.openBox<T>(boxName);
  }

  Future<void> closeBox(String boxName) async {
    var box = Hive.box(boxName);
    await box.close();
  }

  Future<void> putData<T>(String boxName, String key, T value) async {
    var box = await openBox<T>(boxName);
    await box.put(key, value);
  }

  T? getData<T>(String boxName, String key, {T? defaultValue}) {
    var box = Hive.box<T>(boxName);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> deleteData<T>(String boxName, String key) async {
    var box = await openBox<T>(boxName);
    await box.delete(key);
  }

  Future<void> clearBox<T>(String boxName) async {
    var box = await openBox<T>(boxName);
    await box.clear();
  }

  Future<void> compactBox(String boxName) async {
    var box = await openBox(boxName);
    await box.compact();
  }

  bool containsKey<T>(String boxName, String key) {
    var box = Hive.box<T>(boxName);
    return box.containsKey(key);
  }

  // Example method to handle a custom object
  void registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }
}
