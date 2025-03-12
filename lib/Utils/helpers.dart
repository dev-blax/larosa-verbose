import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Services/google_auth_service.dart';

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

  static void displaySnackbar(
      String message, BuildContext context, bool success) {
    toastification.show(
      type: success ? ToastificationType.info : ToastificationType.error,
      title: Text(message),
      context: context,
    );
  }

  static emojifyAText(String text) {
    final EmojiParser parser = EmojiParser();
    return parser.emojify(text);
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
      Uri.https('explorelarosa.netlify.app'),
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

  static Future<void> launchURL(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch $url'),
        ),
      );
    }
  }

  static Future<void> logout(BuildContext context) async {
    // Clear all Hive boxes
    await Hive.deleteFromDisk();

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final GoogleAuthService googleAuthService = GoogleAuthService();
    await googleAuthService.signOut();

    // Navigate to login
    if (context.mounted) {
      context.go('/login');
    }
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
