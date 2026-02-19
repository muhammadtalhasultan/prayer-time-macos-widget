import 'package:flutter/services.dart';

class StatusBar {
  static const _channel = MethodChannel('com.prayertime/statusbar');
  static Future<void> setTitle(String title) async {
    try {
      await _channel.invokeMethod('updateStatusTitle', {'title': title});
    } catch (_) {
      // ignore
    }
  }
}
