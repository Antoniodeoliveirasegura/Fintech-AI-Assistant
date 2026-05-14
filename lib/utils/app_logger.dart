import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void debug(String message, {String scope = 'app', Object? error}) {
    if (!kDebugMode) return;

    final suffix = error == null ? '' : ' error=$error';
    debugPrint('[$scope] $message$suffix');
  }
}
