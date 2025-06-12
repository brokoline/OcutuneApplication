// lib/utils/light_utils.dart

import 'package:flutter/material.dart';
import '../models/light_data_model.dart';

// En utility‐klasse til at gruppere rå LightData i time‐, uge‐ og
// måned‐buckets. Alle gruppering sker i lokal tid (dvs. .toLocal()).
// Metoderne returnerer enten rå gennemsnits‐ediLux (ikke procenter),
// eller rå gennemsnits‐procenter baseret på ediLux*100, alt efter behov.
class LightUtils {
  LightUtils._(); // Privat constructor – må ikke instantieres

  // --------------------------------------------------------------------------------
  // 1) DAILY BUCKETING: groupByHourOfDay
  //
  // Input:  Liste af LightData, hvor d.capturedAt er en DateTime (oprindeligt UTC).
  // Handling: Vi kalder d.capturedAt.toLocal().hour for at hente den lokale time (0..23),
  //           derefter samler vi alle ediLux‐værdier i time‐buckets.
  // Output: List<double> med længde 24, hvor index = lokal time (0..23). Hver værdi
  //         er gennemsnitlig ediLux (melanopicEdi som double) i den time. Hvis ingen
  //         målinger i en given time, returneres 0.0.
  static List<double> groupByHourOfDay(List<LightData> data) {
    // 1) Opret 24 tomme lister (én per lokal time 0..23)
    final List<List<double>> buckets = List.generate(24, (_) => <double>[]);

    // 2) Loop alle målinger og fordel dem i buckets baseret på lokal time
    for (final d in data) {
      final lokalTid = d.capturedAt.toLocal();
      final int hour = lokalTid.hour; // 0..23 i lokal tid
      buckets[hour].add(d.ediLux);
    }

    // 3) Beregn gennemsnit pr. bucket (hvis tom, retur 0.0)
    return List<double>.generate(24, (i) {
      final bucket = buckets[i];
      if (bucket.isEmpty) return 0.0;
      final double sumLux = bucket.reduce((a, b) => a + b);
      return sumLux / bucket.length;
    });
  }

  // --------------------------------------------------------------------------------
  // 2) WEEKLY BUCKETING (RÅ LUX): groupByWeekdayLux
  //
  // Input:  Liste af LightData.
  // Handling: Vi kalder d.capturedAt.toLocal().weekday → 1=Mandag..7=Søndag i lokal tid,
  //           derefter samler vi alle ediLux‐værdier i buckets.
  // Output: Map<int,double> med nøgler 0=Mandag..6=Søndag og værdier = gennemsnitlig ediLux.
  static Map<int, double> groupByWeekdayLux(List<LightData> data) {
    final Map<int, List<double>> buckets = { for (var i = 0; i < 7; i++) i: <double>[] };

    for (final d in data) {
      final lokalTid = d.capturedAt.toLocal();
      final int weekdayIndex = lokalTid.weekday - 1; // Mandag=1→0 … Søndag=7→6
      buckets[weekdayIndex]!.add(d.ediLux);
    }

    final Map<int, double> result = {};
    for (var i = 0; i < 7; i++) {
      final bucket = buckets[i]!;
      if (bucket.isEmpty) {
        result[i] = 0.0;
      } else {
        final double sumLux = bucket.reduce((a, b) => a + b);
        result[i] = sumLux / bucket.length;
      }
    }
    return result;
  }

  // --------------------------------------------------------------------------------
  // 3) MONTHLY BUCKETING (RÅ LUX): groupByDayOfMonthLux
  //
  // Input:  Liste af LightData.
  // Handling: Vi kalder d.capturedAt.toLocal().day → 1..31 i lokal tid, samler
  //           ediLux‐værdier i buckets.
  // Output: Map<int,double> med nøgler = dag i måneden (1..31), værdier = gennemsnitlig ediLux.
  static Map<int, double> groupByDayOfMonthLux(List<LightData> data) {
    final Map<int, List<double>> buckets = {};

    for (final d in data) {
      final lokalTid = d.capturedAt.toLocal();
      final int day = lokalTid.day; // 1..31
      buckets.putIfAbsent(day, () => <double>[]).add(d.ediLux);
    }

    final Map<int, double> result = {};
    buckets.forEach((day, bucket) {
      if (bucket.isEmpty) {
        result[day] = 0.0;
      } else {
        final double sumLux = bucket.reduce((a, b) => a + b);
        result[day] = sumLux / bucket.length;
      }
    });

    return result;
  }

  // --------------------------------------------------------------------------------
  // 4) HJÆLPEMETODER TIL AT KONVERTERE “RÅ LUX‐MAP” → LISTER
  //
  // groupByWeekdayListLux(): Returnerer List<double> længde 7 i rækkefølge
  //   [Man, Tir, Ons, Tor, Fre, Lør, Søn], med gennemsnitlig ediLux (rå).
  static List<double> groupByWeekdayListLux(List<LightData> data) {
    final weekdayMap = groupByWeekdayLux(data);
    return List<double>.generate(7, (i) => weekdayMap[i] ?? 0.0);
  }

  // groupByDayOfMonthListLux(): Returnerer List<double> længde D, hvor D = antal
  // dage i lokal måned. Indholdet er gennemsnitlig ediLux pr. dag (1..D).
  static List<double> groupByDayOfMonthListLux(List<LightData> data) {
    final nowLocal = DateTime.now().toLocal();
    final daysInMonth = DateUtils.getDaysInMonth(nowLocal.year, nowLocal.month);
    final dayMap = groupByDayOfMonthLux(data);
    return List<double>.generate(daysInMonth, (i) => dayMap[i + 1] ?? 0.0);
  }

  // --------------------------------------------------------------------------------
  // 5) UGEDAG‐OG‐MÅNEDSBASERET BUCKETING (PROCENT): groupByWeekdayPct
  // Input:  Liste af LightData.
  // Handling: Samler ediLux‐værdier i lokal ugedag og omregner hver måling til procent
  // via (ediLux * 100).clamp(0..100). Derefter beregnes gennemsnit pr. ugedag.
  // Output: Map<int,double> med nøgler 0=Mandag..6=Søndag, værdier = gennemsnitlig procent (0..100).
  static Map<int, double> groupByWeekdayPct(List<LightData> data) {
    final Map<int, List<double>> buckets = { for (var i = 0; i < 7; i++) i: <double>[] };

    for (final d in data) {
      final lokalTid = d.capturedAt.toLocal();
      final int weekdayIndex = lokalTid.weekday - 1; // Mandag=1→0 … Søndag=7→6
      final double pct = (d.ediLux * 100.0).clamp(0.0, 100.0);
      buckets[weekdayIndex]!.add(pct);
    }

    final Map<int, double> result = {};
    for (var i = 0; i < 7; i++) {
      final bucket = buckets[i]!;
      if (bucket.isEmpty) {
        result[i] = 0.0;
      } else {
        final double sumPct = bucket.reduce((a, b) => a + b);
        // Clamp gennemsnittet til 0..100
        result[i] = (sumPct / bucket.length).clamp(0.0, 100.0);
      }
    }
    return result;
  }

  // --------------------------------------------------------------------------------
  // 6) MÅNEDSBASERET BUCKETING (PROCENT): groupByDayOfMonthPct
  //
  // Input:  Liste af LightData.
  // Handling: Samler ediLux i lokal dag i måneden, omregner hver til procent (ediLux*100,
  // clamp), beregner gennemsnit pr. dag.
  // Output: Map<int,double> med nøgler = dag i måneden (1..31), værdier = gennemsnitlig procent (0..100).
  static Map<int, double> groupByDayOfMonthPct(List<LightData> data) {
    final Map<int, List<double>> buckets = {};

    for (final d in data) {
      final lokalTid = d.capturedAt.toLocal();
      final int day = lokalTid.day; // 1..31
      final double pct = (d.ediLux * 100.0).clamp(0.0, 100.0);
      buckets.putIfAbsent(day, () => <double>[]).add(pct);
    }

    final Map<int, double> result = {};
    buckets.forEach((day, bucket) {
      if (bucket.isEmpty) {
        result[day] = 0.0;
      } else {
        final double sumPct = bucket.reduce((a, b) => a + b);
        result[day] = (sumPct / bucket.length).clamp(0.0, 100.0);
      }
    });
    return result;
  }
}
