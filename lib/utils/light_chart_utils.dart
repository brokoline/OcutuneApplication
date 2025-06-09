// utils/light_chart_utils.dart
import 'package:flutter/material.dart';

/// Hjælper til at generere farver for hver timesegment i donut-grafen
class LightChartUtils {
  /// Faste thresholds (lux)
  static const double lowThreshold = 20.0;
  static const double dlmoThreshold = 10.0;
  static const double daytimeThreshold = 250.0;
  static const double boostThreshold = 1316.0;

  /// Farver
  static const Color lowColor = Color(0xFF0D47A1);      // mørkeblå
  static const Color midColor = Color(0xFF64B5F6);      // lyseblå
  static const Color periodColor = Color(0xFFFFEB3B);   // gul
  static const Color boostColor = Color(0xFFFF9800);    // orange
  static const Color futureColor = Color.fromRGBO(255, 255, 255, 0.08);

  /// Returnerer en liste af 24 farver til PieChart-segmenterne.
  /// [hourlyLux] skal indeholde 24 værdier (lux per time).
  /// [now] definerer, hvor mange timer er målt.
  /// [dlmo], [boostStart], [boostEnd], [sleepStart], [sleepEnd] definerer perioder.
  static List<Color> segmentColors(
      List<double> hourlyLux,
      DateTime now,
      double dlmo,
      double boostStart,
      double boostEnd,
      double sleepStart,
      double sleepEnd,
      ) {
    final colors = <Color>[];
    final measuredHours = now.hour + 1;

    for (int h = 0; h < 24; h++) {
      final lux = hourlyLux[h];
      Color c;
      if (h < measuredHours) {
        // Lightboost-periode
        if (h >= boostStart && h < boostEnd) {
          c = lux >= boostThreshold ? boostColor : periodColor;
        }
        // Søvn- og DLMO-periode
        else if ((h >= dlmo && h < dlmo + 2) || (h >= sleepStart && h < sleepEnd)) {
          c = lux <= dlmoThreshold ? periodColor : lowColor;
        }
        // Dag-periode
        else {
          c = lux >= daytimeThreshold ? periodColor : lowColor;
        }
      } else {
        c = futureColor;
      }
      colors.add(c);
    }
    return colors;
  }
}