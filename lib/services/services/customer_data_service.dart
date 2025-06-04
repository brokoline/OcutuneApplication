// lib/services/services/customer_data_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/customer_response_model.dart';

CustomerResponse? currentCustomerResponse;

/// Hvilket spørgsmål vi er på lige nu
int currentQuestion = 0;

/// Gem basale brugeroplysninger (fra første registrerings-screen)
void updateBasicInfo({
  required String firstName,
  required String lastName,
  required String email,
  required String gender,
  required String birthYear,
}) {
  currentCustomerResponse = CustomerResponse(
    firstName:     firstName,
    lastName:      lastName,
    email:         email,
    gender:        gender,
    birthYear:     birthYear,
    answers:       <String>[],
    questionScores:<String,int>{},
    rmeqScore:     null,
    meqScore:      null,
    chronotype: null,
    password:      null,
  );
}

/// Tilføj/overskriv ét svar + score
void saveAnswer(String answer, int score) {
  final resp = currentCustomerResponse;
  if (resp == null) return;

  // 1) svar‐tekster
  final answers = resp.answers;
  if (answers.length >= currentQuestion) {
    answers[currentQuestion - 1] = answer;
  } else {
    answers.add(answer);
  }

  // 2) score‐map
  final qs = resp.questionScores;
  final key = 'q$currentQuestion';
  qs[key] = score;

  // 3) hvis de første 5 spørgsmål besvaret, genberegn rMEQ
  if (answers.length >= 5) {
    final sum = qs.entries
        .where((e) => int.parse(e.key.substring(1)) <= 5)
        .map((e) => e.value)
        .fold(0, (a, b) => a + b);

    // rebuild med ny rmeqScore
    currentCustomerResponse = resp.copyWith(rmeqScore: sum);
  }

  // debug-udskrift
  print('💾 Svar gemt: $answer (score $score) → Q$currentQuestion');
  print('📋 Alle scores: ${qs.toString()}');
  print('📊 Total score: ${qs.values.fold(0, (sum, v) => sum + v)}');
}

/// Sæt kronotype-nøgle
void setChronotypeKey(String key) {
  final resp = currentCustomerResponse;
  if (resp == null) return;

  currentCustomerResponse = resp.copyWith(
    chronotype: key,
  );
}

/// Sender hele pakken til backend
Future<void> submitCustomerResponse() async {
  final resp = currentCustomerResponse;
  if (resp == null) return;

  final url      = Uri.parse('https://ocutune2025.ddns.net/api/auth/register');
  final jsonBody = json.encode(resp.toJson());

  print("📤 Upload data til $url");
  print("📦 Payload: $jsonBody");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonBody,
  );

  if (response.statusCode == 409) {
    throw Exception("Denne e-mail er allerede registreret.");
  }
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception("Fejl ved upload: ${response.body}");
  }

  print("✅ Data sendt og modtaget korrekt");
}
