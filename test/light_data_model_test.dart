// test/light_data_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ocutune_light_logger/models/light_data_model.dart';

void main() {
  group('LightData.fromJson + helpers', () {
    test('Kan parse ISO8601 uden Z', () {
      final json = {
        'captured_at': '2025-06-27T12:34:56',
        'melanopic_edi': 42,
        'illuminance': 100,
        'exposure_score': 0.0,
        'action_required': false,
        'light_type': 'daytime',
      };
      final ld = LightData.fromJson(json);
      expect(ld.timestamp.year, 2025);
      expect(ld.melanopicEdi, 42);
      expect(ld.illuminance, 100);
      expect(ld.lightType, 'daytime');
      expect(ld.actionRequired, isFalse);
    });

    test('averageScore håndterer tom liste og gennemsnit korrekt', () {
      expect(LightData.averageScore([]), 0.0);

      final data = [
        LightData(
          capturedAt: DateTime.now(),
          melanopicEdi: 50,
          illuminance: 0,
          lightType: '',
          exposureScore: 0.0,
          actionRequired: false,
        ),
        LightData(
          capturedAt: DateTime.now(),
          melanopicEdi: 250,
          illuminance: 0,
          lightType: '',
          exposureScore: 0.0,
          actionRequired: false,
        ),
      ];
      // calculatedScore: (50/250).clamp=0.2 + (250/250)=1 => avg=0.6
      expect(LightData.averageScore(data), closeTo(0.6, 1e-6));
    });

    test('weekdayAverage filtrerer korrekt', () {
      final now = DateTime(2025, 6, 27); // fredag = 5
      final d1 = LightData(capturedAt: now, melanopicEdi: 10, illuminance:0,
          lightType:'', exposureScore:0.0, actionRequired:false);
      final d2 = LightData(capturedAt: now.add(Duration(days:1)), melanopicEdi: 20, illuminance:0,
          lightType:'', exposureScore:0.0, actionRequired:false);
      expect(LightData.weekdayAverage([d1,d2], 5), LightData.averageScore([d1]));
    });
  });
}
