import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void warning(String message) {
    if (kDebugMode) debugPrint('[WARN] $message');
  }

  static void configurationFailure(String service) {
    warning(
        '$service could not be initialized. Check local build configuration.');
  }
}
