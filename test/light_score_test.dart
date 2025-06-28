// test/light_score_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ocutune_light_logger/services/processing/dlmo_data_processing.dart';
import 'package:ocutune_light_logger/models/light_data_model.dart';

void main() {
  // rMEQ‐værdien har ingen betydning for calculateLightScore(),
  // da dlmo‐intervallet bruger konstant 10 og sleep‐intervallet konstant 1
  final processor = LightDataProcessing(rMEQ: 12);

  group('calculateLightScore', () {
    test('daytime maxer ved ≥250 lux', () {
      expect(
        processor.calculateLightScore(500, 'daytime'),
        closeTo(100.0, 1e-6),
      );
      expect(
        processor.calculateLightScore(100, 'daytime'),
        closeTo((100 / 250) * 100, 1e-6),
      );
    });

    test('lightboost skaleres med 1316', () {
      expect(
        processor.calculateLightScore(1316, 'lightboost'),
        closeTo(100.0, 1e-6),
      );
      expect(
        processor.calculateLightScore(658, 'lightboost'),
        closeTo((658 / 1316) * 100, 1e-6),
      );
    });

    test('dlmo og sleep returnerer 100 for 0 input', () {
      expect(processor.calculateLightScore(0, 'dlmo'), equals(100.0));
      expect(processor.calculateLightScore(0, 'sleep'), equals(100.0));
    });

    test('dlmo og sleep clamped til 100 ved tærskelværdien', () {
      // dlmo‐tærskel = 10 → 10/10 = 1 → *100 = 100
      expect(
        processor.calculateLightScore(10, 'dlmo'),
        closeTo(100.0, 1e-6),
      );
      // sleep‐tærskel = 1 →  1/1 = 1 → *100 = 100
      expect(
        processor.calculateLightScore(1, 'sleep'),
        closeTo(100.0, 1e-6),
      );
    });

    test('dlmo og sleep skalerer proportionelt under tærskel', () {
      // dlmo‐under: 10/20 = 0.5 → *100 = 50
      expect(
        processor.calculateLightScore(20, 'dlmo'),
        closeTo((10 / 20) * 100, 1e-6),
      );
      // sleep‐under: 1/2 = 0.5 → *100 = 50
      expect(
        processor.calculateLightScore(2, 'sleep'),
        closeTo((1 / 2) * 100, 1e-6),
      );
    });

    test('ukendt interval giver 0', () {
      expect(processor.calculateLightScore(1000, 'foo'), equals(0.0));
    });
  });

  group('evaluateLightExposure', () {
    test('returnerer Map med nøglerne score, interval, recommendation', () {
      final now = DateTime(2025, 1, 1, 12, 0);
      final result = processor.evaluateLightExposure(
        melanopicEDI: 500,
        time: now,
      );
      expect(
        result.keys.toSet(),
        equals({'score', 'interval', 'recommendation'}),
      );
    });

    test('score er double, interval og recommendation er String', () {
      final result = processor.evaluateLightExposure(
        melanopicEDI: 10,
        time: DateTime(2025, 1, 1, 12, 0),
      );
      expect(result['score'], isA<double>());
      expect(result['interval'], isA<String>());
      expect(result['recommendation'], isA<String>());
    });
  });

  group('groupLuxByDay & groupLuxByWeekdayName', () {
    final mondayDt   = DateTime(2025, 1, 6, 10, 0);  // mandag
    final tuesdayDt  = DateTime(2025, 1, 7, 14, 0);  // tirsdag

    final dataForByDay = [
      // her bruger vi melanopicEdi som ediLux
      LightData(
        capturedAt: mondayDt,
        melanopicEdi: 100,
        illuminance: 0,
        lightType: '',
        exposureScore: 0.0,
        actionRequired: false,
      ),
      LightData(
        capturedAt: mondayDt.add(const Duration(hours: 2)),
        melanopicEdi: 200,
        illuminance: 0,
        lightType: '',
        exposureScore: 0.0,
        actionRequired: false,
      ),
      LightData(
        capturedAt: tuesdayDt,
        melanopicEdi: 50,
        illuminance: 0,
        lightType: '',
        exposureScore: 0.0,
        actionRequired: false,
      ),
    ];

    test('groupLuxByDay: gennemsnit pr. weekday (ediLux)', () {
      final byDay = processor.groupLuxByDay(dataForByDay);
      expect(byDay[1], closeTo(150.0, 1e-6)); // mandag: (100+200)/2
      expect(byDay[2], closeTo(50.0, 1e-6));  // tirsdag: (50)/1
    });

    test('groupLuxByWeekdayName: summerer illuminance pr. navn', () {
      final dataForByName = [
        LightData(
          capturedAt: mondayDt,
          melanopicEdi: 0,
          illuminance: 100,
          lightType: '',
          exposureScore: 0.0,
          actionRequired: false,
        ),
        LightData(
          capturedAt: mondayDt,
          melanopicEdi: 300,
          illuminance: 200,
          lightType: '',
          exposureScore: 0.0,
          actionRequired: false,
        ),
        LightData(
          capturedAt: tuesdayDt,
          melanopicEdi: 200,
          illuminance: 50,
          lightType: '',
          exposureScore: 0.0,
          actionRequired: false,
        ),
      ];

      final byName = processor.groupLuxByWeekdayName(dataForByName);
      expect(byName['Man'], closeTo(300.0, 1e-6));
      expect(byName['Tir'], closeTo(50.0, 1e-6));
      expect(byName['Ons'], equals(0.0));
    });
  });
}
