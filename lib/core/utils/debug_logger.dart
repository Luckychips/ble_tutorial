//lib
import 'package:flutter/foundation.dart';

DebugLogger get logger => DebugLogger.instance;

class DebugLogger {
  DebugLogger._();
  static final instance = DebugLogger._();

  void d(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }
}