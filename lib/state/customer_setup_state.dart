import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/customer_register_answers_model.dart';

class CustomerSetupState {
  static final CustomerSetupState instance = CustomerSetupState._internal();
  CustomerSetupState._internal();

  // --- Personlige oplysninger ---
  String? email;
  String? password;
  String? firstName;
  String? lastName;
  String? gender;
  int? age;
  int? customerId;
  String? token;

  // --- Chronotype-data og score ---
  int? totalScore;
  String? chronotype;
  String? chronotypeText;
  String? chronotypeImageUrl;

  // --- Svaropsamling ---
  final Map<String, AnswerModel> _answers = {};

  // --- Settere ---
  void setEmail(String value) => email = value;
  void setPassword(String value) => password = value;
  void setFirstName(String value) => firstName = value;
  void setLastName(String value) => lastName = value;
  void setGender(String value) => gender = value;
  void setAge(int value) => age = value;
  void setCustomerId(int id) => customerId = id;
  void setChronotype(String value) => chronotype = value;
  void setChronotypeText(String value) => chronotypeText = value;
  void setChronotypeImageUrl(String value) => chronotypeImageUrl = value;
  void setTotalScore(int value) => totalScore = value;

  bool get hasValidRegistrationData {
    return email != null &&
        password != null &&
        firstName != null &&
        lastName != null &&
        gender != null &&
        age != null &&
        age! > 0;
  }

  void setAnswer(String questionId, AnswerModel answer) {
    _answers[questionId] = answer;
  }

  AnswerModel? getAnswer(String questionId) => _answers[questionId];
  List<AnswerModel> getAllAnswers() => _answers.values.toList();
  Map<String, AnswerModel> get answers => _answers;

  void attachCustomerIdToAnswers(int? id) {
    if (id == null) return;
    for (final answer in _answers.values) {
      answer.customerId = id;
    }
  }

  // --- SEND TIL BACKEND OG GEM SCORE + PATCH ---
  Future<void> flushAnswersToBackend() async {
    if (customerId == null || token == null) {
      throw Exception('❌ Mangler customerId eller token');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    attachCustomerIdToAnswers(customerId!);

    for (final answer in _answers.values) {
      try {
        final response = await http.post(
          Uri.parse('https://ocutune2025.ddns.net/submit_answer'),
          headers: headers,
          body: jsonEncode(answer.toJson()),
        );

        if (response.statusCode != 200) {
          debugPrint("❌ Fejl ved svar (${answer.questionId}): ${response.body}");
          continue;
        }

        debugPrint("✅ Svar sendt: ${answer.questionTextSnap}");
      } catch (e) {
        debugPrint("❌ Fejl ved afsendelse af svar: $e");
      }
    }

    // 🔢 Beregn total score og PATCH til backend
    try {
      final scoreResponse = await http.post(
        Uri.parse('https://ocutune2025.ddns.net/calculate-score/$customerId'),
        headers: headers,
      );

      if (scoreResponse.statusCode != 200) {
        throw Exception('❌ Fejl ved beregning af score: ${scoreResponse.body}');
      }

      final scoreData = jsonDecode(scoreResponse.body);
      final totalScore = scoreData['total_score'];
      this.totalScore = totalScore;

      debugPrint("🎯 Total score: $totalScore");

      // 🧠 PATCH score og evt. chronotype
      final patchResponse = await http.patch(
        Uri.parse('https://ocutune2025.ddns.net/customers/$customerId'),
        headers: headers,
        body: jsonEncode({
          'total_score': totalScore,
          if (chronotype != null) 'chronotype_key': chronotype,
        }),
      );

      if (patchResponse.statusCode != 200) {
        debugPrint("⚠️ Fejl ved opdatering af kunde: ${patchResponse.body}");
      } else {
        debugPrint("✅ Kunde opdateret med score + chronotype");
      }
    } catch (e) {
      debugPrint("⚠️ Fejl i scoreberegning/opdatering: $e");
    }
  }

  void reset() {
    email = null;
    password = null;
    firstName = null;
    lastName = null;
    gender = null;
    age = null;
    customerId = null;
    token = null;
    totalScore = null;
    chronotype = null;
    chronotypeText = null;
    chronotypeImageUrl = null;
    _answers.clear();
  }
}
