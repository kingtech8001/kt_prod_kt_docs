import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void debug(String tag, String message, [dynamic data]) {
    if (kDebugMode) {
      final buffer = StringBuffer('[KT_VAULT] 🔵 [$tag] $message');
      if (data != null) {
        buffer.write('\n  Payload: $data');
      }
      // ignore: avoid_print
      print(buffer.toString());
    }
  }

  static void info(String tag, String message, [dynamic data]) {
    final buffer = StringBuffer('[KT_VAULT] 🟢 [$tag] $message');
    if (data != null) {
      buffer.write('\n  Data: $data');
    }
    // ignore: avoid_print
    print(buffer.toString());
  }

  static void warning(String tag, String message, [dynamic data]) {
    final buffer = StringBuffer('[KT_VAULT] 🟡 [$tag] $message');
    if (data != null) {
      buffer.write('\n  Context: $data');
    }
    // ignore: avoid_print
    print(buffer.toString());
  }

  static void error(
    String tag,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic contextData,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('==================== [KT_VAULT ERROR] ====================');
    buffer.writeln('🔴 TAG: $tag');
    buffer.writeln('🔴 MESSAGE: $message');
    if (error != null) {
      buffer.writeln('🔴 ERROR OBJECT (${error.runtimeType}): $error');
    }
    if (contextData != null) {
      buffer.writeln('🔴 CONTEXT DATA: $contextData');
    }
    if (stackTrace != null) {
      buffer.writeln('🔴 STACK TRACE:\n$stackTrace');
    }
    buffer.writeln('==========================================================');
    // ignore: avoid_print
    print(buffer.toString());
  }
}
