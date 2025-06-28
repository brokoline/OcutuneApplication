// Udviklet med hjælp af ChatGPT

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ocutune_light_logger/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Performance Tests', () {
    testWidgets('App startup time', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();
      app.main();
      await tester.pumpAndSettle();
      stopwatch.stop();

      final startupMs = stopwatch.elapsedMilliseconds;
      print('Startup time: ${startupMs} ms');
      expect(
        startupMs < 2000,
        true,
        reason: 'App startup should be below 2000ms, but was ${startupMs}ms',
      );
    });

    testWidgets('Frame build & raster durations', (WidgetTester tester) async {
      final timings = <FrameTiming>[];
      binding.addTimingsCallback((List<FrameTiming>? list) {
        if (list != null) timings.addAll(list);
      });

      app.main();
      // Collect for a few seconds
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Exclude first two frames to skip initial jank
      final validTimings = timings.skip(2).toList();
      print('Collected ${validTimings.length} frames (skipped initial 2)');

      // Log slow frames
      final slowFrames = validTimings.where((t) {
        final build = t.buildDuration.inMilliseconds ?? 0;
        final raster = t.rasterDuration.inMilliseconds ?? 0;
        return build > 16 || raster > 16;
      }).toList();
      print('Slow frames count: ${slowFrames.length}');
      for (var t in slowFrames) {
        print('build=${t.buildDuration.inMilliseconds}ms, '
            'raster=${t.rasterDuration.inMilliseconds}ms');
      }

      // Allow up to 5% slow frames
      final maxAllowed = (validTimings.length * 0.05).ceil();
      expect(
        slowFrames.length <= maxAllowed,
        true,
        reason: 'Allowed up to $maxAllowed slow frames, but found ${slowFrames.length}',
      );
    });
  });
}
