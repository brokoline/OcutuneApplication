// lib/utils/light_utils.dart

import '../models/light_data_model.dart';

/// En utility‐klasse til at gruppere rå LightData i time‐, uge‐ og
/// måned‐buckets. Alle dato/tid‐operationer sker i UTC‐regi, da selve
/// timestamps fra serveren gemmes uden isUtc=true.
class LightUtils {
  LightUtils._(); // Privat constructor – må ikke instantieres

  // --------------------------------------------------------------------------------
  // 1) DAILY BUCKETING: groupByHourOfDay
  //
  // Input: Liste af LightData, hvor d.capturedAt er en DateTime uden isUtc=true,
  //        men reelt repræsenterer et UTC‐timestamp.
  // Vi laver 24 buckets (0..23), læser hour‐feltet fra d.capturedAt.toUtc().hour,
  // konverterer d.ediLux → procent (0..100) og gennemsnit i hver time.
  //
  // Output: List<double> med længde 24, hvor index=h repræsenterer gennemsnitlig
  //         EDI% i timen [h:00–h:59] i UTC.
  static List<double> groupByHourOfDay(List<LightData> data) {
    // 1) Forbered 24 tomme lister (én for hver UTC‐time 0..23)
    final Map<int, List<double>> hourlyBuckets = {
      for (int i = 0; i < 24; i++) i: <double>[]
    };

    // 2) Loop over alle målinger og put dem i korrekt hour‐bucket baseret på UTC
    for (final d in data) {
      final DateTime tsUtc = d.capturedAt.toUtc();
      final int hour = tsUtc.hour; // 0..23 i UTC
      final double pct = (d.ediLux * 100.0).clamp(0.0, 100.0);
      hourlyBuckets[hour]!.add(pct);
    }

    // 3) Beregn gennemsnit pr. time (eller 0.0 hvis ingen målinger i den time)
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
  // Input: Liste af LightData (UTC‐timestamps). Vi henter .toUtc().weekday,
  //        som giver 1=mandag … 7=søndag. Konverterer d.ediLux → procent og
  //        gennemsnit i hver ugedag.
  //
  // Output: Map<int,double> med nøgler 0=mandag … 6=søndag, og værdier 0..100 %
  //         for gennemsnitlig EDI i denne ugedag i data.
  static Map<int, double> groupByWeekday(List<LightData> data) {
    // 1) Forbered map: 1..7 (mandag..søndag) → liste af procents
    final Map<int, List<double>> weekdayBuckets = {
      for (int wd = 1; wd <= 7; wd++) wd: <double>[]
    };

    // 2) Loop over data og tildel til bucket baseret på UTC‐ugedag
    for (final d in data) {
      final DateTime tsUtc = d.capturedAt.toUtc();
      final int wd = tsUtc.weekday; // 1..7 i UTC
      final double pct = (d.ediLux * 100.0).clamp(0.0, 100.0);
      weekdayBuckets[wd]!.add(pct);
    }

    // 3) Omsæt til result: keys 0..6 (mandag..søndag) med gennemsnitlig procent
    final Map<int, double> result = {};
    weekdayBuckets.forEach((weekday, bucket) {
      final int index = weekday - 1; // 0=mandag .. 6=søndag
      if (bucket.isEmpty) {
        result[index] = 0.0;
      } else {
        final double sum = bucket.reduce((a, b) => a + b);
        result[index] = (sum / bucket.length).clamp(0.0, 100.0);
      }
    });

    return result;
  }

  // --------------------------------------------------------------------------------
  // 3) MONTHLY BUCKETING: groupByDayOfMonth
  //
  // Input: Liste af LightData (UTC‐timestamps). Vi henter .toUtc().day,
  //        som giver dag‐i‐måned (1..31). Konverter d.ediLux → procent og
  //        gennemsnit pr. dag‐i‐måned.
  //
  // Output: Map<int,double> hvor nøglerne er de dage‐i‐måned (1..31) der rent faktisk
  //         forekommer i data, og værdier er gennemsnitlig EDI% for den dag.
  static Map<int, double> groupByDayOfMonth(List<LightData> data) {
    final Map<int, List<double>> domBuckets = {};

    // 1) Loop og put i buckets baseret på UTC‐dag
    for (final d in data) {
      final DateTime tsUtc = d.capturedAt.toUtc();
      final int dom = tsUtc.day; // 1..31 i UTC
      final double pct = (d.ediLux * 100.0).clamp(0.0, 100.0);
      domBuckets.putIfAbsent(dom, () => <double>[]).add(pct);
    }

    // 2) Byg result med gennemsnit for hver dag
    final Map<int, double> result = {};
    domBuckets.forEach((day, bucket) {
      final double sum = bucket.reduce((a, b) => a + b);
      result[day] = (sum / bucket.length).clamp(0.0, 100.0);
    });

    return result;
  }

  // --------------------------------------------------------------------------------
  // 4) OPTIONAL: Hvis du vil lave x‐aksen med tekstlige ugedagsnavne (“Man, Tir,…”),
  // kan du kalde denne (men den bruger ikke procent – den summerer bare lux):
  //
  // Input: Liste af LightData (UTC). Vi henter .toUtc().weekday, og
  //        summerer d.illuminance for hver hverdag. Output: Map<String,double>
  //        med keys “Man”..“Søn” og summeret illuminans.
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
    const List<String> names = ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'];

    for (final d in data) {
      final DateTime tsUtc = d.capturedAt.toUtc();
      final int wd = tsUtc.weekday; // 1..7 i UTC
      final String name = names[wd - 1];
      luxPerDay[name] = luxPerDay[name]! + d.illuminance;
    }

    return luxPerDay;
  }
}
