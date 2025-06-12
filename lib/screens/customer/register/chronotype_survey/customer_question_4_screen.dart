// lib/screens/customer/register/registration_steps/chronotype_survey/customer_question_4_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_selectable_tile.dart';

import '../../../../../services/services/customer_data_service.dart';
import '../../../../../widgets/universal/ocutune_next_step_button.dart';

class QuestionFourScreen extends StatefulWidget {
  const QuestionFourScreen({Key? key}) : super(key: key);

  @override
  State<QuestionFourScreen> createState() => _QuestionFourScreenState();
}

class _QuestionFourScreenState extends State<QuestionFourScreen> {
  String? selectedOption;
  Map<String, int> choiceScores = {};
  late Future<Map<String, dynamic>> _questionData;

  @override
  void initState() {
    super.initState();
    currentQuestion = 4;
    _questionData = fetchQuestionData(4);
  }

  Future<Map<String, dynamic>> fetchQuestionData(int questionId) async {
    const baseUrl     = 'https://ocutune2025.ddns.net/api';
    final questionsUrl = Uri.parse('$baseUrl/questions');
    final choicesUrl   = Uri.parse('$baseUrl/choices');

    final responses = await Future.wait([
      http.get(questionsUrl),
      http.get(choicesUrl),
    ]);

    if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
      final questions = jsonDecode(responses[0].body) as List<dynamic>;
      final choices   = jsonDecode(responses[1].body) as List<dynamic>;

      final question = questions.firstWhere(
            (q) => q['id'] == questionId,
        orElse: () => null,
      );
      if (question == null) {
        throw Exception("Spørgsmålet med ID $questionId blev ikke fundet.");
      }

      final filteredChoices = choices
          .where((c) => c['question_id'] == questionId)
          .toList();
      if (filteredChoices.isEmpty) {
        throw Exception("Ingen valgmuligheder fundet til spørgsmål $questionId");
      }

      final scoreMap = <String,int>{
        for (var c in filteredChoices)
          c['choice_text'] as String: c['score'] as int,
      };

      return {
        'text':    question['question_text'] as String,
        'choices': scoreMap.keys.toList(),
        'scores':  scoreMap,
      };
    } else {
      throw Exception('Kunne ikke hente spørgsmål og/eller valgmuligheder.');
    }
  }

  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  void _goToNextScreen() {
    if (selectedOption != null) {
      final score = choiceScores[selectedOption!] ?? 0;
      saveAnswer(selectedOption!, score);
      Navigator.pushNamed(context, '/Q5');
    } else {
      showError(context, "Vælg venligst en mulighed først");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _questionData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Fejl: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            } else {
              final data         = snapshot.data!;
              final questionText = data['text']    as String;
              final options      = List<String>.from(data['choices'] as List);
              choiceScores       = Map<String,int>.from(data['scores'] as Map);

              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      children: [
                        Text(
                          questionText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ...options.map((option) {
                          return OcutuneSelectableTile(
                            text: option,
                            selected: selectedOption == option,
                            onTap: () => setState(() => selectedOption = option),
                          );
                        }).toList(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: OcutuneButton(
                      type: OcutuneButtonType.floatingIcon,
                      onPressed: _goToNextScreen,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
