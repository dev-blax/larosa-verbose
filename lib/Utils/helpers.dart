import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';

enum RequestType {
  get,
  post,
  delete,
}

class HelperFunctions {
  static displaySnackbar(String message, BuildContext context, bool success) {
    // Get.snackbar(

    toastification.show(
      type: success ? ToastificationType.info : ToastificationType.error,
      title: Text(message),
      context: context,
      backgroundColor: success ? Colors.blue : Colors.red,
    );
  }

  static larosaLogger(String message) {
    var logger = Logger();
    logger.i(message);
  }

  static shareLink(String endPoint) {
    Share.shareUri(
      Uri.https(
        'explorelarosa.netlify.app',
        endPoint,
      ),
    );
  }

  static String formatLastMessageTime(DateTime messageTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(messageTime);

    if (difference.inMinutes < 60) {
      // Messages from the last hour
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      // Messages from today
      return DateFormat('h:mm a').format(messageTime); // e.g., "1:15 PM"
    } else if (difference.inDays == 1) {
      // Messages from yesterday
      return "Yesterday at ${DateFormat('h:mm a').format(messageTime)}";
    } else if (difference.inDays < 7) {
      // Messages from the past week
      return "${DateFormat('EEEE').format(messageTime)} at ${DateFormat('h:mm a').format(messageTime)}"; // e.g., "Wednesday at 9:20 AM"
    } else if (messageTime.year == now.year) {
      // Messages from this year
      return DateFormat('MMM d at h:mm a')
          .format(messageTime); // e.g., "July 23 at 2:30 PM"
    } else {
      // Messages from previous years
      return DateFormat('MMM d, yyyy at h:mm a')
          .format(messageTime); // e.g., "March 15, 2022 at 4:00 PM"
    }
  }

  static void showToast(String message, bool primary) {
    toastification.show(
      type: primary ? ToastificationType.info : ToastificationType.error,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 5),
      style: ToastificationStyle.flat,
    );

    // Fluttertoast.showToast(
    //   msg: message,
    //   toastLength: Toast.LENGTH_SHORT,
    //   gravity: ToastGravity.TOP,
    //   timeInSecForIosWeb: 1,
    //   backgroundColor: primary ? Colors.blue : Colors.red,
    //   textColor: Colors.white,
    //   fontSize: 16.0,
    // );
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
}
