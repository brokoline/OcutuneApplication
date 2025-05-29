import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer_registor_choices_model.dart';
import '../models/custumer_register_questions_model.dart';

class QuestionRepository {
  final String baseUrl = 'https://ocutune2025.ddns.net';

  Future<QuestionModel?> getQuestionByPosition(int position) async {
    final questionsUrl = Uri.parse('$baseUrl/questions');
    final choicesUrl = Uri.parse('$baseUrl/choices');

    try {
      final responses = await Future.wait([
        http.get(questionsUrl),
        http.get(choicesUrl),
      ]);

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final questions = jsonDecode(responses[0].body) as List;
        final choices = jsonDecode(responses[1].body) as List;

        final question = questions.firstWhere(
              (q) => q['position'] == position,
          orElse: () => null,
        );

        if (question == null) return null;

        final questionId = question['id'];
        final filteredChoices =
        choices.where((c) => c['question_id'] == questionId).toList();

        if (filteredChoices.isEmpty) return null;

        final answerChoices = filteredChoices
            .map<ChoiceModel>((c) => ChoiceModel.fromJson(c))
            .toList();

        return QuestionModel(
          id: questionId.toString(),
          question: question['question_text'],
          answers: answerChoices,
        );
      }
    } catch (e) {
      print('Fejl ved hentning af spørgsmål: $e');
    }

    return null;
  }
}
