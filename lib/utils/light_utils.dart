// lib/utils/light_utils.dart

import 'package:flutter/material.dart';

import '../models/light_data_model.dart';

/// En utility‐klasse til at gruppere rå LightData i time‐, uge‐ og
/// måned‐buckets. Alle gruppering sker i lokal tid (dvs. .toLocal()).
///
/// Metoderne returnerer RÅ gennemsnits‐lux (ikke procenter).
class LightUtils {
  LightUtils._(); // Privat constructor – må ikke instantieres

  // --------------------------------------------------------------------------------
  // DAILY BUCKETING: groupByHourOfDay
  //
  // Input:  Liste af LightData, hvor d.capturedAt er en DateTime (oprindeligt UTC).
  // Handling: Vi kalder d.capturedAt.toLocal().hour for at hente den lokale time (0..23).
  //           Vi samler alle ediLux‐værdier i time‐buckets.
  // Output: List<double> med længde 24, hvor index = lokal time (0=00:00–00:59, …).
  //         Hver værdi er gennemsnitlig lux i den time. Hvis ingen målinger i time, returneres 0.0.
  static List<double> groupByHourOfDay(List<LightData> data) {
    // 1) Opret 24 tomme lister (én for hver lokal time 0..23)
    List<List<double>> buckets = List.generate(24, (_) => <double>[]);

    // 2) Loop alle målinger og fordel dem i buckets baseret på lokal time
    for (final d in data) {
      final lokalTid = d.capturedAt.toLocal();
      final int hour = lokalTid.hour; // 0..23 i lokal tid
      buckets[hour].add(d.ediLux);    // her antager vi, at ediLux er i lux‐skala
    }

    // 3) Beregn gennemsnit pr. bucket (hvis tom, returnér 0.0)
    return List<double>.generate(24, (i) {
      final bucket = buckets[i];
      if (bucket.isEmpty) return 0.0;
      final double sumLux = bucket.reduce((a, b) => a + b);
      final double avgLux = sumLux / bucket.length;
      return avgLux;
    });
  }

  // --------------------------------------------------------------------------------
  // WEEKLY BUCKETING: groupByWeekdayLux
  //
  // Vis kun for at have mulighed for ugentligt/monthly – ikke nødvendig for dagligt.
  static Map<int, double> groupByWeekdayLux(List<LightData> data) {
    final Map<int, List<double>> buckets = {
      for (var i = 0; i < 7; i++) i: <double>[]
    };

    for (final d in data) {
      final lokalTid = d.capturedAt.toLocal();
      final int weekdayIndex = lokalTid.weekday - 1; // 1=Mandag→0 … 7=Søndag→6
      buckets[weekdayIndex]!.add(d.ediLux);
    }

    final Map<int, double> result = {};
    for (var i = 0; i < 7; i++) {
      final bucket = buckets[i]!;
      if (bucket.isEmpty) {
        result[i] = 0.0;
      } else {
        final double sumLux = bucket.reduce((a, b) => a + b);
        final double avgLux = sumLux / bucket.length;
        result[i] = avgLux;
      }
    }
    return result;
  }

  // --------------------------------------------------------------------------------
  // MONTHLY BUCKETING: groupByDayOfMonthLux
  //
  // Samme princip: dag 1..31 i lokal tid → gennemsnitlig lux.
  static Map<int, double> groupByDayOfMonthLux(List<LightData> data) {
    final Map<int, List<double>> buckets = {};

    for (final d in data) {
      final lokalTid = d.capturedAt.toLocal();
      final int day = lokalTid.day; // 1..31 i lokal tid
      buckets.putIfAbsent(day, () => <double>[]).add(d.ediLux);
    }

    final Map<int, double> result = {};
    buckets.forEach((day, bucket) {
      if (bucket.isEmpty) {
        result[day] = 0.0;
      } else {
        final double sumLux = bucket.reduce((a, b) => a + b);
        final double avgLux = sumLux / bucket.length;
        result[day] = avgLux;
      }
    });
    return result;
  }

  // --------------------------------------------------------------------------------
  // OPTIONAL: Hjælpemetoder til at konvertere Map → List, hvis man ønsker det
  static List<double> groupByWeekdayListLux(List<LightData> data) {
    final weekdayMap = groupByWeekdayLux(data);
    return List<double>.generate(7, (i) => weekdayMap[i] ?? 0.0);
  }

  static List<double> groupByDayOfMonthListLux(List<LightData> data) {
    final nowLocal = DateTime.now().toLocal();
    final daysInMonth =
    DateUtils.getDaysInMonth(nowLocal.year, nowLocal.month);
    final dayMap = groupByDayOfMonthLux(data);
    return List<double>.generate(daysInMonth, (i) => dayMap[i + 1] ?? 0.0);
  }



// --------------------------------------------------------------------------------
  // 2) WEEKLY BUCKETING: groupByWeekday
  //
  // Input:  Liste af LightData (timestamps som UTC bag kulisserne).
  // Handling: Vi kalder d.capturedAt.toLocal().weekday, som giver 1=Mandag..7=Søndag
  //         i dansk tidszone. Vi konverterer d.ediLux til procent (0..100) og gennemsnit.
  // Output: Map<int,double> med nøgler 0=Mandag..6=Søndag, hvor værdien er gennemsnitlig procent‐lux.
  static Map<int, double> groupByWeekday(List<LightData> data) {
    // 1) Forbered midlertidige buckets for ugedage 0..6
    Map<int, List<double>> buckets = { for (var i = 0; i < 7; i++) i: <double>[] };

    // 2) Loop over data og tilføj til korrekt bucket baseret på lokal ugedag
    for (final d in data) {
      final lokalTid = d.capturedAt.toLocal();
      final int weekdayIndex = lokalTid.weekday - 1; // Mandag=1→0, … Søndag=7→6
      final double pct = (d.ediLux * 100.0).clamp(0.0, 100.0);
      buckets[weekdayIndex]!.add(pct);
    }

    // 3) Beregn gennemsnit pr. ugedag (hvis tom, 0.0)
    Map<int, double> result = {};
    for (var i = 0; i < 7; i++) {
      final bucket = buckets[i]!;
      if (bucket.isEmpty) {
        result[i] = 0.0;
      } else {
        final sum = bucket.reduce((a, b) => a + b);
        result[i] = (sum / bucket.length).clamp(0.0, 100.0);
      }
    }

    return result;
  }

  // --------------------------------------------------------------------------------
  // 3) MONTHLY BUCKETING: groupByDayOfMonth
  //
  // Input:  Liste af LightData (timestamps i UTC-format).
  // Handling: Vi kalder d.capturedAt.toLocal().day, som giver dag i måneden (1..31)
  //         i dansk lokal tid. Vi konverterer d.ediLux→procent (0..100) og gennemsnit.
  // Output: Map<int,double> med nøglerne = dag i måneden (1..max31), og værdien = gennemsnitlig procent‐lux.
  static Map<int, double> groupByDayOfMonth(List<LightData> data) {
    // 1) Brug et midlertidigt map, hvor nøglen er dag‐i‐måned (1..31)
    final Map<int, List<double>> buckets = {};

    for (final d in data) {
      final lokalTid = d.capturedAt.toLocal();
      final int day = lokalTid.day; // 1..31 i lokal tid
      final double pct = (d.ediLux * 100.0).clamp(0.0, 100.0);
      buckets.putIfAbsent(day, () => <double>[]).add(pct);
    }

    // 2) Beregn gennemsnit for hver dag og returnér som Map<int,double>
    final Map<int, double> result = {};
    buckets.forEach((day, bucket) {
      final sum = bucket.reduce((a, b) => a + b);
      result[day] = (sum / bucket.length).clamp(0.0, 100.0);
    });

    return result;
  }
}
