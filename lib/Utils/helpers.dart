import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';

enum RequestType {
  get,
  post,
  delete,
}

class HelperFunctions {
  static displaySnackbar(String message) {
    Get.snackbar(
      'Explore Larosa',
      message,
      duration: const Duration(seconds: 1),
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

  static bool isVideo(String url) {
    final mimeType = lookupMimeType(url);
    return mimeType != null && mimeType.startsWith('video/');
  }
}
