import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Question {
  final String text;
  final List<String> options;
  final Map<String, int> scores;

  Question({required this.text, required this.options, required this.scores});
}

class QuestionController with ChangeNotifier {
  final String baseUrl = 'https://ocutune2025.ddns.net/api';
  List<Question> questions = [];
  int currentQuestionIndex = 0;

  Future<void> fetchQuestions() async {
    final questionsUrl = Uri.parse('$baseUrl/questions');
    final choicesUrl = Uri.parse('$baseUrl/choices');

    final responses = await Future.wait([
      http.get(questionsUrl),
      http.get(choicesUrl),
    ]);

    if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
      final questionsData = jsonDecode(responses[0].body) as List<dynamic>;
      final choicesData = jsonDecode(responses[1].body) as List<dynamic>;

      questions = questionsData.map((q) {
        final filteredChoices = choicesData
            .where((c) => c['question_id'] == q['id'])
            .toList();

        final scoreMap = {
          for (var c in filteredChoices)
            c['choice_text'] as String: c['score'] as int
        };

        return Question(
          text: q['question_text'] as String,
          options: scoreMap.keys.toList(),
          scores: scoreMap,
        );
      }).toList();

      notifyListeners();
    } else {
      throw Exception("Kunne ikke hente spørgsmål eller valgmuligheder.");
    }
  }

  Question get currentQuestion => questions[currentQuestionIndex];

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      currentQuestionIndex++;
      notifyListeners();
    }
  }

  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;
}
