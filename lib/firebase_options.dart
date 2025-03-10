// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCDmdyqTA9D7rUAy-iWc2VD1P6bdUU5AZA',
    appId: '1:370358339116:web:c711d6148a9363cccff389',
    messagingSenderId: '370358339116',
    projectId: 'explore-larosa-bf556',
    authDomain: 'explore-larosa-bf556.firebaseapp.com',
    storageBucket: 'explore-larosa-bf556.firebasestorage.app',
    measurementId: 'G-9Z6HQVHB2Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAXTBlcVZwIKHP7Ob2v6S25Ffa5FImjtSs',
    appId: '1:370358339116:android:7634e4f3ede70f90cff389',
    messagingSenderId: '370358339116',
    projectId: 'explore-larosa-bf556',
    storageBucket: 'explore-larosa-bf556.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCX8HeVUUBuMVwPyXKPS-W2O3SSrVHrO9E',
    appId: '1:370358339116:ios:61de597233ce4546cff389',
    messagingSenderId: '370358339116',
    projectId: 'explore-larosa-bf556',
    storageBucket: 'explore-larosa-bf556.firebasestorage.app',
    iosBundleId: 'com.example.larosaBlock',
  );
}
