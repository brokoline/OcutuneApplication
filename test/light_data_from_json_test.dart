// test/light_data_from_json_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ocutune_light_logger/models/light_data_model.dart';

void main() {
  group('LightData.fromJson - dato-parsing', () {
    test('Kan parse ISO8601 uden Z som UTC', () {
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
      expect(ld.timestamp.month, 6);
      expect(ld.timestamp.day, 27);
      expect(ld.timestamp.hour, 12);
    });

    test('Kan parse ISO8601 med Z som UTC', () {
      final json = {
        'captured_at': '2025-06-27T12:34:56Z',
        'melanopic_edi': 0,
        'illuminance': 0,
        'exposure_score': 0.0,
        'action_required': 0,
        'light_type': null,
      };

      final ld = LightData.fromJson(json);
      expect(ld.timestamp.year, 2025);
      expect(ld.timestamp.month, 6);
      expect(ld.timestamp.day, 27);
      // lightType fallback til 'Ukendt'
      expect(ld.lightType, 'Ukendt');
    });

    test('RFC1123 (“Fri, dd MMM yyyy HH:mm:ss GMT”) kaster FormatException', () {
      final json = {
        'captured_at': 'Fri, 27 Jun 2025 12:34:56 GMT',
        'melanopic_edi': 5,
        'illuminance': 10,
        'exposure_score': 0.0,
        'action_required': 1,
        'light_type': 'sleep',
      };

      expect(
            () => LightData.fromJson(json),
        throwsFormatException,
      );
    });
  });
}
