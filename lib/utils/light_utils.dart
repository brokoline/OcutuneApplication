// lib/utils/light_utils.dart

import '../models/light_data_model.dart';

// A utility class (not strictly necessary to instantiate) that
// provides functions for binning raw LightData into hourly,
// weekly, or monthly buckets, as well as generating recommendations.
class LightUtils {
  LightUtils._(); // private constructor to prevent instantiation

  // --------------------------------------------------------------------------------
  // 1) DAILY BUCKETING: groupByHourOfDay
  //
  // Take a List<LightData> and bin all readings into 24 buckets (hours 0..23).
  // Each bucket collects all ediLux readings that occurred during that hour.
  // We then convert each raw ediLux (0..1.0) into a percentage (0..100),
  // clamp it to [0,100], and average within each hour.
  //
  // Returns: a List<double> of length 24, where index=0 is the average EDI%
  //   for readings from 00:00–00:59, index=1 for 01:00–01:59, … index=23 for 23:00–23:59.
  // If no readings fell into a given hour, that slot is 0.0.
  static List<double> groupByHourOfDay(List<LightData> data) {
    // 1) Prepare 24 empty lists (one for each hour 0..23)
    final Map<int, List<double>> hourlyBuckets = {
      for (int i = 0; i < 24; i++) i: <double>[]
    };

    // 2) Assign each reading to the correct “hour” bucket
    for (final d in data) {
      final int hour = d.capturedAt.toLocal().hour;
      // Convert raw EDI (0.0..1.0) to a 0..100 scale and clamp:
      final double pct = (d.ediLux * 100.0).clamp(0.0, 100.0);
      hourlyBuckets[hour]!.add(pct);
    }

    // 3) Compute the average percentage for each hour (or 0.0 if empty)
    final List<double> averages = List<double>.filled(24, 0.0);
    for (int h = 0; h < 24; h++) {
      final List<double> bucket = hourlyBuckets[h]!;
      if (bucket.isEmpty) {
        averages[h] = 0.0;
      } else {
        final double sum = bucket.reduce((a, b) => a + b);
        averages[h] = (sum / bucket.length).clamp(0.0, 100.0);
      }
    }
    return averages;
  }

  // --------------------------------------------------------------------------------
  // 2) WEEKLY BUCKETING: groupByWeekday
  //
  // Take a List<LightData> and group by weekday (1=Monday…7=Sunday).
  // Convert ediLux → percentage (0..100) and average each weekday.
  //
  // Returns: a Map<int,double> where key=0 => Monday, ..., key=6 => Sunday,
  //   and value is the average EDI% (0..100) for that weekday. If no readings
  //   on a given weekday, its value is 0.0.
  static Map<int, double> groupByWeekday(List<LightData> data) {
    // 1) Map of weekday (1..7) → list of edi% values
    final Map<int, List<double>> weekdayBuckets = {
      for (int wd = 1; wd <= 7; wd++) wd: <double>[]
    };

    for (final d in data) {
      final int wd = d.capturedAt.toLocal().weekday; // 1..7
      final double pct = (d.ediLux * 100.0).clamp(0.0, 100.0);
      weekdayBuckets[wd]!.add(pct);
    }

    // 2) Build result map with keys shifted to 0..6
    final Map<int, double> result = {};
    weekdayBuckets.forEach((weekday, bucket) {
      if (bucket.isEmpty) {
        result[weekday - 1] = 0.0;
      } else {
        final double sum = bucket.reduce((a, b) => a + b);
        result[weekday - 1] = (sum / bucket.length).clamp(0.0, 100.0);
      }
    });

    return result; // keys: 0 (Mon) … 6 (Sun)
  }

  // --------------------------------------------------------------------------------
  // 3) MONTHLY BUCKETING: groupByDayOfMonth
  //
  // Take a List<LightData> and group by day-of-month (1..31).
  // Convert ediLux → percentage (0..100) and average each day.
  //
  // Returns: a Map<int,double> where each key is the day-of-month (1..31 that
  //   actually appears in the data), and the value is the average EDI% for that day.
  static Map<int, double> groupByDayOfMonth(List<LightData> data) {
    final Map<int, List<double>> domBuckets = {};

    for (final d in data) {
      final int dom = d.capturedAt.toLocal().day; // 1..31
      final double pct = (d.ediLux * 100.0).clamp(0.0, 100.0);
      domBuckets.putIfAbsent(dom, () => <double>[]).add(pct);
    }

    final Map<int, double> result = {};
    domBuckets.forEach((day, bucket) {
      final double sum = bucket.reduce((a, b) => a + b);
      result[day] = (sum / bucket.length).clamp(0.0, 100.0);
    });

    return result; // keys: only those days (1..31) that exist in raw data
  }

  // --------------------------------------------------------------------------------
  // 4) OPTIONAL: If you’d like to show a “weekday‐labelled” x-axis (e.g. “Mon, Tue…”),
  // you can transform the Map<int,double> from groupByWeekday into a list in the
  // correct order and supply custom titles later. For now, the raw Map<int,double>
  // is sufficient for building a bar chart.
  //
  // 5) ADDITIONAL: groupLuxByWeekdayName
  //
  // If instead you want to sum actual illuminance (lux) by Danish weekday names:
  // “Man” (Monday) … “Søn” (Sunday). This method will produce keys of type String.
  static Map<String, double> groupLuxByWeekdayName(List<LightData> data) {
    final Map<String, double> luxPerDay = {
      'Man': 0.0,
      'Tir': 0.0,
      'Ons': 0.0,
      'Tor': 0.0,
      'Fre': 0.0,
      'Lør': 0.0,
      'Søn': 0.0,
    };
    final List<String> names = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];

    for (final d in data) {
      final int wd = d.capturedAt.toLocal().weekday; // 1..7
      final String name = names[wd - 1];
      luxPerDay[name] = luxPerDay[name]! + d.illuminance;
    }

    return luxPerDay;
  }
}
