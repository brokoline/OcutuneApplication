import 'package:intl/intl.dart';
import '../models/light_data_model.dart';

/// Generér anbefalinger baseret på patientens lysdata
List<String> generateRecommendations(List<LightData> data) {
  List<String> recs = [];

  final lowMorning = data.where((d) =>
  d.capturedAt.hour >= 6 && d.capturedAt.hour <= 10 &&
      d.melanopicEdi < 150).length;

  final eveningLight = data.where((d) =>
  d.capturedAt.hour >= 20 && d.melanopicEdi > 50).length;

  final redFlags = data.where((d) => d.actionRequired).length;

  if (lowMorning > 3) {
    recs.add("Øg lysniveauet i morgentimerne (kl. 6–10)");
  }

  if (eveningLight > 2) {
    recs.add("Reducer lys om aftenen efter kl. 20");
  }

  if (redFlags > 5) {
    recs.add("Flere kritiske målinger – overvej manuel justering");
  }

  if (recs.isEmpty) {
    recs.add("Ingen kritiske fund – eksponering ser god ud ✅");
  }

  return recs;
}

/// Samler total lux pr. ugedag (bruges til søjlediagram)
Map<String, double> groupLuxByDay(List<LightData> data) {
  final Map<String, double> luxPerDay = {
    'Man': 0,
    'Tir': 0,
    'Ons': 0,
    'Tor': 0,
    'Fre': 0,
    'Lør': 0,
    'Søn': 0,
  };

  for (final d in data) {
    final weekday = DateFormat.E('da_DK').format(d.capturedAt);
    if (luxPerDay.containsKey(weekday)) {
      luxPerDay[weekday] = luxPerDay[weekday]! + d.illuminance;
    }
  }

  return luxPerDay;
}
