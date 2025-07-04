import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MeqChoice {
  final int id;
  final String text;
  final int score;

  MeqChoice({ required this.id, required this.text, required this.score });

  factory MeqChoice.fromJson(Map<String, dynamic> json) {
    final rawText  = json['text'] ?? json['choice_text'];
    final txt      = (rawText is String) ? rawText : '';
    final rawScore = json['score'];
    final sc       = (rawScore is int) ? rawScore : 0;
    return MeqChoice(id: json['id'] as int, text: txt, score: sc);
  }
}

class MeqQuestion {
  final int id;
  final String text;
  final List<MeqChoice> choices;

  MeqQuestion({ required this.id, required this.text, required this.choices });

  factory MeqQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List<dynamic>? ?? [];
    final choices = rawChoices
        .map((cj) => MeqChoice.fromJson(cj as Map<String, dynamic>))
        .toList();
    final txt = (json['question_text'] is String)
        ? json['question_text'] as String
        : '';
    return MeqQuestion(id: json['id'] as int, text: txt, choices: choices);
  }
}


class MeqQuestionController with ChangeNotifier {
  static const _baseUrl = 'https://ocutune2025.ddns.net/api/meq';

  List<MeqQuestion> questions = [];
  int currentQuestionIndex = 0;
  final List<Map<String,int>> _answers = [];

  int _meqScore = 0;
  int get meqScore => _meqScore;

  MeqQuestion get currentQuestion => questions[currentQuestionIndex];
  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;


  void reset() {
    questions.clear();
    currentQuestionIndex = 0;
    _answers.clear();
    _meqScore = 0;
    notifyListeners();
  }


  Future<void> fetchQuestions() async {
    final uri = Uri.parse('$_baseUrl/questions');
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Kunne ikke hente spørgsmål: ${resp.statusCode}');
    }
    final list = jsonDecode(resp.body) as List<dynamic>;
    questions = list
        .map((e) => MeqQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }


  void recordAnswer(int questionId, int choiceId) {
    final choice = questions
        .firstWhere((q) => q.id == questionId)
        .choices
        .firstWhere((c) => c.id == choiceId);
    _answers.removeWhere((m) => m['question_id'] == questionId);
    _answers.add({
      'question_id': questionId,
      'choice_id': choiceId,
      'score': choice.score,
    });
  }


  int? getSavedChoice(int questionId) {
    final match = _answers.firstWhere(
          (m) => m['question_id'] == questionId,
      orElse: () => <String,int>{},
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


  Future<int> submitAnswers(int participantId, {bool isUpdate = false}) async {
    final uri = Uri.parse('$_baseUrl/answers');
    final payload = {
      'participant_id': participantId,
      'answers':        _answers,
    };

    if (kDebugMode) {
      print('MEQ DEBUG → ${isUpdate ? 'PUT' : 'POST'} $uri');
      print('MEQ DEBUG payload: ${jsonEncode(payload)}');
    }

    final res = isUpdate
        ? await http.put(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(payload),
    )
        : await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(payload),
    );

    if (res.statusCode != 200) {
      final action = isUpdate ? 'PUT' : 'POST';
      throw Exception(
          'Kunne ikke gemme svar ($action): ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _meqScore = (data['meq_score'] ?? 0) as int;
    notifyListeners();
    return _meqScore;
  }
}
