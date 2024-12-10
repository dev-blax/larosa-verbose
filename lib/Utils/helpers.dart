// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:go_router/go_router.dart';
// import 'package:hive/hive.dart';
// import 'package:intl/intl.dart';
// import 'package:logger/logger.dart';
// import 'package:mime/mime.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:toastification/toastification.dart';

// enum RequestType {
//   get,
//   post,
//   delete,
// }

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// class HelperFunctions {
//   static displaySnackbar(String message, BuildContext context, bool success) {
//     // Get.snackbar(

//     toastification.show(
//       type: success ? ToastificationType.info : ToastificationType.error,
//       title: Text(message),
//       context: context,
//       // backgroundColor: success ? Colors.blue : Colors.red,
//     );
//   }

//   static Future<double> getMaxImageHeight(List<String> imagePaths) async {
//     double maxHeight = 0;

//     for (var path in imagePaths) {
//       final File imageFile = File(path);
//       final decodedImage =
//           await decodeImageFromList(imageFile.readAsBytesSync());

//       if (decodedImage.height > maxHeight) {
//         maxHeight = decodedImage.height.toDouble();
//       }
//     }

//     return maxHeight;
//   }

//   static larosaLogger(String message) {
//     var logger = Logger();
//     logger.i(message);
//   }

//   static shareLink(String endPoint) {
//     Share.shareUri(
//       Uri.https(
//         'explorelarosa.netlify.app',
//         endPoint,
//       ),
//     );
//   }

//   static bool isValidEmail(String email) {
//     final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
//     return emailRegex.hasMatch(email);
//   }

//   static String formatLastMessageTime(DateTime messageTime) {
//     final DateTime now = DateTime.now();
//     final Duration difference = now.difference(messageTime);

//     if (difference.inMinutes < 60) {
//       // Messages from the last hour
//       return "${difference.inMinutes} min ago";
//     } else if (difference.inHours < 24) {
//       // Messages from today
//       return DateFormat('h:mm a').format(messageTime); // e.g., "1:15 PM"
//     } else if (difference.inDays == 1) {
//       // Messages from yesterday
//       return "Yesterday at ${DateFormat('h:mm a').format(messageTime)}";
//     } else if (difference.inDays < 7) {
//       // Messages from the past week
//       return "${DateFormat('EEEE').format(messageTime)} at ${DateFormat('h:mm a').format(messageTime)}"; // e.g., "Wednesday at 9:20 AM"
//     } else if (messageTime.year == now.year) {
//       // Messages from this year
//       return DateFormat('MMM d at h:mm a')
//           .format(messageTime); // e.g., "July 23 at 2:30 PM"
//     } else {
//       // Messages from previous years
//       return DateFormat('MMM d, yyyy at h:mm a')
//           .format(messageTime); // e.g., "March 15, 2022 at 4:00 PM"
//     }
//   }

//   static void showToast(String message, bool primary) {
//     toastification.show(
//       type: primary ? ToastificationType.info : ToastificationType.error,
//       title: Text(message),
//       autoCloseDuration: const Duration(seconds: 5),
//       style: ToastificationStyle.fillColored,
//     );

//     // Fluttertoast.showToast(
//     //   msg: message,
//     //   toastLength: Toast.LENGTH_SHORT,
//     //   gravity: ToastGravity.TOP,
//     //   timeInSecForIosWeb: 1,
//     //   backgroundColor: primary ? Colors.blue : Colors.red,
//     //   textColor: Colors.white,
//     //   fontSize: 16.0,
//     // );
//   }

//   static void logout(BuildContext context) {
//     var userbox = Hive.box('userBox');

//     userbox.deleteFromDisk();

//     context.go('/login');
//   }

//   static bool isVideo(String url) {
//     final mimeType = lookupMimeType(url);
//     return mimeType != null && mimeType.startsWith('video/');
//   }

//   // Place this outside any class in your helpers file
//   static String formatPrice(double price) {
//     String priceStr = price.toStringAsFixed(0);
//     RegExp regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');
//     return priceStr.replaceAllMapped(regExp, (match) => ',');
//   }

//   static Future<void> showNotification({
//     required String title,
//     required String body,
//     bool isError = false,
//   }) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'ride_channel', // Channel ID
//       'Ride Notifications', // Channel name
//       channelDescription: 'Notifications for ride requests and updates',
//       importance: Importance.max,
//       priority: Priority.high,
//       color: Colors.blue,
//       enableVibration: true,
//     );

//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);

//     await flutterLocalNotificationsPlugin.show(
//       isError ? 1 : 0, // Unique notification ID
//       title,
//       body,
//       notificationDetails,
//     );
//   }

//     static Future<void> showNotificationForChannelMessage({
//     required String title,
//     required String body,
//     required String channelId,
//   }) async {
//     // Define a unique channel for messages
//     AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       channelId, // Channel ID for the specific channel
//       'Channel Messages', // Channel name
//       channelDescription: 'Notifications for messages from channels',
//       importance: Importance.max,
//       priority: Priority.high,
//       color: Colors.green, // Adjust the color if needed
//       enableVibration: true,
//       playSound: true,
//     );

//     NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);

//     // Display the notification
//     await flutterLocalNotificationsPlugin.show(
//       channelId.hashCode, // Unique notification ID based on the channel ID
//       title,
//       body,
//       notificationDetails,
//     );
//   }

// }



import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class HelperFunctions {
  static Future<void> initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        if (response.payload != null) {
          debugPrint('Notification payload: ${response.payload}');
          // Add logic here for notification tap handling
        }
      },
    );
  }

  static void displaySnackbar(String message, BuildContext context, bool success) {
    toastification.show(
      type: success ? ToastificationType.info : ToastificationType.error,
      title: Text(message),
      context: context,
    );
  }

  static Future<double> getMaxImageHeight(List<String> imagePaths) async {
    double maxHeight = 0;

    for (var path in imagePaths) {
      final File imageFile = File(path);
      final decodedImage =
          await decodeImageFromList(imageFile.readAsBytesSync());

      if (decodedImage.height > maxHeight) {
        maxHeight = decodedImage.height.toDouble();
      }
    }

    return maxHeight;
  }

  static void larosaLogger(String message) {
    var logger = Logger();
    logger.i(message);
  }

  static void shareLink(String endPoint) {
    Share.shareUri(
      Uri.https('explorelarosa.netlify.app', endPoint),
    );
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  static String formatLastMessageTime(DateTime messageTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(messageTime);

    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return DateFormat('h:mm a').format(messageTime);
    } else if (difference.inDays == 1) {
      return "Yesterday at ${DateFormat('h:mm a').format(messageTime)}";
    } else if (difference.inDays < 7) {
      return "${DateFormat('EEEE').format(messageTime)} at ${DateFormat('h:mm a').format(messageTime)}";
    } else if (messageTime.year == now.year) {
      return DateFormat('MMM d at h:mm a').format(messageTime);
    } else {
      return DateFormat('MMM d, yyyy at h:mm a').format(messageTime);
    }
  }

  static void showToast(String message, bool primary) {
    toastification.show(
      type: primary ? ToastificationType.info : ToastificationType.error,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 5),
      style: ToastificationStyle.fillColored,
    );
  }

  static void logout(BuildContext context) {
    var userbox = Hive.box('userBox');
    userbox.deleteFromDisk();
    context.go('/login');
  }

  static bool isVideo(String url) {
    final mimeType = lookupMimeType(url);
    return mimeType != null && mimeType.startsWith('video/');
  }

  static String formatPrice(double price) {
    String priceStr = price.toStringAsFixed(0);
    RegExp regExp = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return priceStr.replaceAllMapped(regExp, (match) => ',');
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    bool isError = false,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'ride_channel',
      'Ride Notifications',
      channelDescription: 'Notifications for ride requests and updates',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.blue,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      isError ? 1 : 0,
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> showNotificationForChannelMessage({
    required String title,
    required String body,
    required String channelId,
  }) async {
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      'Channel Messages',
      channelDescription: 'Notifications for messages from channels',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.green,
      enableVibration: true,
      playSound: true,
    );

    NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      channelId.hashCode,
      title,
      body,
      notificationDetails,
    );
  }
}
