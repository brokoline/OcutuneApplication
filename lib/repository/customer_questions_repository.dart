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

      print('📥 [API] GET /questions → ${responses[0].statusCode}');
      print('📥 [API] GET /choices   → ${responses[1].statusCode}');

      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final questions = jsonDecode(responses[0].body) as List;
        final choices = jsonDecode(responses[1].body) as List;

        print('🔍 Antal spørgsmål: ${questions.length}');
        print('🔍 Antal valgmuligheder: ${choices.length}');

        final question = questions.firstWhere(
              (q) => q['position'] == position,
          orElse: () {
            print('❌ Ingen spørgsmål fundet med position = $position');
            return null;
          },
        );

        if (question == null) return null;

        final questionId = question['id'];
        print('✅ Spørgsmål fundet: ID = $questionId, tekst = ${question['question_text']}');

        final filteredChoices = choices
            .where((c) => c['question_id'] == questionId)
            .toList();

        if (filteredChoices.isEmpty) {
          print('⚠️ Ingen valgmuligheder fundet til question_id = $questionId');
          return null;
        }

        final answerChoices = filteredChoices
            .map<ChoiceModel>((c) => ChoiceModel.fromJson(c))
            .toList();

        print('✅ Antal valgmuligheder: ${answerChoices.length}');

        return QuestionModel(
          id: questionId.toString(),
          question: question['question_text'],
          answers: answerChoices,
        );
      } else {
        print('❌ Fejlstatus: questions = ${responses[0].statusCode}, choices = ${responses[1].statusCode}');
      }
    } catch (e) {
      print('💥 Undtagelse ved hentning af spørgsmål: $e');
    }

    return null;
  }
}
