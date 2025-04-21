// import 'package:hive_flutter/hive_flutter.dart';

// class HiveService {
//   static final HiveService _instance = HiveService._internal();

//   factory HiveService() {
//     return _instance;
//   }

//   HiveService._internal();

//   Future<void> init() async {
//     await Hive.initFlutter();
//   }

//   Future<Box<T>> openBox<T>(String boxName) async {
//     return await Hive.openBox<T>(boxName);
//   }

//   Future<void> closeBox(String boxName) async {
//     var box = Hive.box(boxName);
//     await box.close();
//   }

//   Future<void> putData<T>(String boxName, String key, T value) async {
//     var box = await openBox<T>(boxName);
//     await box.put(key, value);
//   }

//   T? getData<T>(String boxName, String key, {T? defaultValue}) {
//     var box = Hive.box<T>(boxName);
//     return box.get(key, defaultValue: defaultValue);
//   }

//   Future<void> deleteData<T>(String boxName, String key) async {
//     var box = await openBox<T>(boxName);
//     await box.delete(key);
//   }

//   Future<void> clearBox<T>(String boxName) async {
//     var box = await openBox<T>(boxName);
//     await box.clear();
//   }

//   Future<void> compactBox(String boxName) async {
//     var box = await openBox(boxName);
//     await box.compact();
//   }

//   bool containsKey<T>(String boxName, String key) {
//     var box = Hive.box<T>(boxName);
//     return box.containsKey(key);
//   }

//   // Example method to handle a custom object
//   void registerAdapter<T>(TypeAdapter<T> adapter) {
//     if (!Hive.isAdapterRegistered(adapter.typeId)) {
//       Hive.registerAdapter(adapter);
//     }
//   }
// }





import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  Future<void> init() async {
    await Hive.initFlutter();
  }

  /// Opens the box if not already open, otherwise returns existing.
  Future<Box<T>> openBox<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName);
  }

  /// Closes the box only if it's open.
  Future<void> closeBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
  }

  /// Writes data, ensuring the box is open.
  Future<void> putData<T>(String boxName, String key, T value) async {
    final box = await openBox<T>(boxName);
    await box.put(key, value);
  }

  /// Reads data from an already-open box.
  T? getData<T>(String boxName, String key, {T? defaultValue}) {
    final box = Hive.box<T>(boxName);
    return box.get(key, defaultValue: defaultValue);
  }


  /// Deletes a key, opening the box if necessary.
  Future<void> deleteData<T>(String boxName, String key) async {
    // Always open with the right generic exactly once:
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<T>(boxName);
    }
    final Box<T> box = Hive.box<T>(boxName);
    await box.delete(key);
  }


  /// Clears all data, opening the box if necessary.
  Future<void> clearBox<T>(String boxName) async {
    final box = Hive.isBoxOpen(boxName)
      ? Hive.box<T>(boxName)
      : await Hive.openBox<T>(boxName);
    await box.clear();
  }

  /// Compacts the box, opening it if necessary.
  Future<void> compactBox(String boxName) async {
    final box = Hive.isBoxOpen(boxName)
      ? Hive.box(boxName)
      : await Hive.openBox(boxName);
    await box.compact();
  }

  /// Checks for key existence in an already-open box.
  bool containsKey<T>(String boxName, String key) {
    final box = Hive.box<T>(boxName);
    return box.containsKey(key);
  }

  /// Registers a custom adapter if not already registered.
  void registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }
}
