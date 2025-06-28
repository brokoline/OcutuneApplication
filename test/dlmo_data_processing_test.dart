// test/dlmo_data_processing_test.dart

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocutune_light_logger/services/processing/dlmo_data_processing.dart';

void main() {
  group('buildRecommendationModel', () {
    // rMEQ <8 giver finite boostStart og boostEnd
    final processor = LightDataProcessing(rMEQ: 7);
    final timeWindows = processor.getTimeWindows();
    final model = buildRecommendationModel(processor, 'neutral');

    test('models tidsvinduer matcher getTimeWindows()', () {
      expect(model.dlmo, closeTo(timeWindows['dlmoStart']!, 1e-6));
      expect(model.sleepStart, closeTo(timeWindows['sleepStart']!, 1e-6));
      expect(model.sleepEnd, closeTo(timeWindows['sleepEnd']!, 1e-6));
      expect(model.boostStart, closeTo(timeWindows['boostStart']!, 1e-6));
      expect(model.boostEnd, closeTo(timeWindows['boostEnd']!, 1e-6));
    });

    test('_formatTime håndterer >24 timer korrekt', () {
      final sample = LightRecommendationModel(
        chronotype: 'X',
        dlmo: 20.5,       // 20:30
        sleepStart: 22.0, // 22:00
        sleepEnd: 30.25,  // 30:15
        boostStart: 18.75,// 18:45
        boostEnd: 20.25,  // 20:15
      );
      final lines = patientRecommendationsText(sample);
      expect(lines[1], 'DLMO (Dim Light Melatonin Onset): 20:30');
      expect(lines[2], 'Sengetid (DLMO + 2 timer): 22:00');
      expect(lines[3], 'Opvågning (DLMO + 10 timer): 30:15');
    });
  });

  group('LightDataProcessing methods', () {
    test('getTimeWindows producerer finite værdier', () {
      final p = LightDataProcessing(rMEQ: 7);
      final w = p.getTimeWindows();
      for (final entry in w.entries) {
        expect(entry.value.isFinite, isTrue,
            reason: 'Forventet finite for ${entry.key}, fik ${entry.value}');
      }
    });

    final p0 = LightDataProcessing(rMEQ: 0);
    test('estimateDLMO anvender forventet formel', () {
      final meq = 50.0;
      final expected = (209.023 - meq) / 7.288;
      expect(p0.estimateDLMO(meq), closeTo(expected, 1e-6));
    });

    test('estimateTau anvender forventet formel', () {
      final meq = 10.0;
      final expected = (24.97514314 - meq) / 0.01714266123;
      expect(p0.estimateTau(meq), closeTo(expected, 1e-6));
    });

    test('calculateBoostStart anvender forventet formel', () {
      final tau = 24.0;
      final dlmo = 20.0;
      final shift = tau - 24.0;
      final offset = 2.6 + 0.06666666667 * sqrt(9111 + 15000 * shift);
      final expected = dlmo - offset;
      expect(p0.calculateBoostStart(tau, dlmo), closeTo(expected, 1e-6));
    });

    group('evaluateLightExposure', () {
      final p12 = LightDataProcessing(rMEQ: 12);
      test('returnerer korrekt struktur', () {
        final res = p12.evaluateLightExposure(
          melanopicEDI: 50,
          time: DateTime(2025, 6, 27, 12, 0),
        );
        expect(res.keys.toSet(), {'score', 'interval', 'recommendation'});
      });
    });
  });
}
