// lib/screens/customer/meq_survey/meq_question_controller.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Én valgmulighed i MEQ-undersøgelsen
class MeqChoice {
  final int id;
  final String text;
  final int score;

  MeqChoice({
    required this.id,
    required this.text,
    required this.score,
  });

  /// Tager højde for at backend kan kalde tekst-feltet enten 'text' eller 'choice_text'
  factory MeqChoice.fromJson(Map<String, dynamic> json) {
    final rawText  = json['text'] ?? json['choice_text'];
    final txt       = rawText is String ? rawText : '';
    final rawScore = json['score'];
    final sc        = rawScore is int ? rawScore : 0;
    return MeqChoice(
      id:    json['id']    as int,
      text:  txt,
      score: sc,
    );
  }
}

/// Ét MEQ-spørgsmål med alle dets valg
class MeqQuestion {
  final int id;
  final String text;
  final List<MeqChoice> choices;

  MeqQuestion({
    required this.id,
    required this.text,
    required this.choices,
  });

  factory MeqQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List<dynamic>? ?? [];
    final choiceList = rawChoices
        .map((cj) => MeqChoice.fromJson(cj as Map<String, dynamic>))
        .toList();

    final questionText = json['question_text'];
    final txt = questionText is String ? questionText : '';

    return MeqQuestion(
      id:      json['id'] as int,
      text:    txt,
      choices: choiceList,
    );
  }
}

/// Controller, der henter spørgsmål, gemmer svar + score, og poster dem til serveren
class MeqQuestionController with ChangeNotifier {
  final String baseUrl = 'https://ocutune2025.ddns.net/api/meq';

  List<MeqQuestion> questions = [];
  int currentQuestionIndex = 0;
  final List<Map<String, int>> _answers = [];

  // Den beregnede score fra backend
  int _meqScore = 0;
  int get meqScore => _meqScore;

  MeqQuestion get currentQuestion => questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;

  /// Henter GET /questions (inkl. indlejrede choices)
  Future<void> fetchQuestions() async {
    final uri  = Uri.parse('$baseUrl/questions');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Kunne ikke hente MEQ-spørgsmål: ${resp.statusCode}');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    questions = list
        .map((e) => MeqQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  /// Gemmer brugerens valg + score
  void recordAnswer(int questionId, int choiceId) {
    final question = questions.firstWhere((q) => q.id == questionId);
    final choice   = question.choices.firstWhere((c) => c.id == choiceId);

    _answers.removeWhere((m) => m['question_id'] == questionId);
    _answers.add({
      'question_id': questionId,
      'choice_id':   choiceId,
      'score':       choice.score,
    });
  }

  /// Finder et tidligere gemt valg, så det kan blive markeret ved back-navigation
  int? getSavedChoice(int questionId) {
    final match = _answers.firstWhere(
          (m) => m['question_id'] == questionId,
      orElse: () => <String, int>{},
    );
    return match['choice_id'];
  }

  void nextQuestion() {
    if (!isLastQuestion) {
      currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      currentQuestionIndex--;
      notifyListeners();
    }
  }

  /// Sender POST /answers → opdaterer `_meqScore`, notifies og returnerer scoren
  Future<int> submitAnswers(String participantId) async {
    final uri = Uri.parse('$baseUrl/answers');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'participant_id': participantId,
        'answers':        _answers,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(
          'Serveren returnerede status ${res.statusCode}: ${res.body}'
      );
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    // Null-sikker parsing med default 0
    _meqScore = (data['meq_score'] ?? 0) as int;
    notifyListeners();
    return _meqScore;
  }
}
