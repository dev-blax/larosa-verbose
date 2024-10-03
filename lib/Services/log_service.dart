import 'package:logger/logger.dart';

class LogService {
  static void logTrace(String message) {
    var logger = Logger();
    logger.t(message);
  }

  static void logDebug(String message) {
    var logger = Logger();
    logger.d(message);
  }

  static void logInfo(String message) {
    var logger = Logger();
    logger.i(message);
  }

  static void logWarning(String message) {
    var logger = Logger();
    logger.w(message);
  }

  static void logError(String message) {
    var logger = Logger();
    logger.e(message);
  }

  static void logFatal(String message) {
    var logger = Logger();
    logger.f(message);
  }


}
