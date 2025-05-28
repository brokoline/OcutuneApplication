import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class OcutuneForegroundHandler extends TaskHandler {
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp) async {
    print('✅ Foreground task STARTED at $timestamp');

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final now = DateTime.now().toIso8601String();
      print('🕒 Tick: $now');
    });
  }

  @override

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('🛑 Task stopped at $timestamp');
    _timer?.cancel();
  }

  @override
  void onButtonPressed(String id) {
    print('🔘 Button "$id" pressed');
  }

  @override
  void onNotificationPressed() {
    print('🔔 Notification pressed');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // TODO: implement onRepeatEvent
  }
}
