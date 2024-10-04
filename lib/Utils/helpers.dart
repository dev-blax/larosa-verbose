import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum RequestType {
  get,
  post,
  delete,
}

class HelperFunctions {
  static displaySnackbar(String message) {
    // Get.snackbar(
    //   'Explore Larosa',
    //   message,
    //   duration: const Duration(seconds: 1),
    // );
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


  static void showToast(String message, bool primary){
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: primary ? Colors.blue : Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  static void logout(BuildContext context) {
    // Do your logout logic here (e.g., clear tokens, session, etc.)

    context.go('/login');
  }

  static bool isVideo(String url) {
    final mimeType = lookupMimeType(url);
    return mimeType != null && mimeType.startsWith('video/');
  }
}
