import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';
import '/widgets/ocutune_slider.dart';
import '../../../../services/services/user_data_service.dart';

class QuestionTwoScreen extends StatefulWidget {
  const QuestionTwoScreen({super.key});

  @override
  State<QuestionTwoScreen> createState() => QuestionTwoScreenState();
}

class QuestionTwoScreenState extends State<QuestionTwoScreen> {
  double sliderValue = 2;
  late Future<Map<String, dynamic>> _questionData;

  final List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.white,
    Colors.lightGreen,
    Colors.green,
  ];

  List<String> choices = [];

  @override
  void initState() {
    super.initState();
    currentQuestion = 2;
    _questionData = fetchQuestionData(2);
  }

  Future<Map<String, dynamic>> fetchQuestionData(int questionId) async {
    const baseUrl = 'https://ocutune.ddns.net';
    final questionsUrl = Uri.parse('$baseUrl/questions');
    final choicesUrl = Uri.parse('$baseUrl/choices');

    final responses = await Future.wait([
      http.get(questionsUrl),
      http.get(choicesUrl),
    ]);

    if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
      final questions = jsonDecode(responses[0].body) as List;
      final choicesData = jsonDecode(responses[1].body) as List;

      final question = questions.firstWhere(
            (q) => q['id'] == questionId,
        orElse: () => null,
      );

      if (question == null) {
        throw Exception("Spørgsmålet med ID $questionId blev ikke fundet.");
      }

      final filtered = choicesData.where((item) => item['question_id'] == questionId).toList();

      if (filtered.isEmpty) {
        throw Exception("Ingen valgmuligheder fundet til spørgsmål $questionId");
      }

      filtered.sort((a, b) => (a['score'] as int).compareTo(b['score'] as int));

      final choiceList = filtered.map((item) => item['choice_text'] as String).toList();
      final scoreMap = {
        for (var item in filtered)
          item['choice_text'] as String: item['score'] as int,
      };

      return {
        'text': question['question_text'],
        'choices': choiceList,
        'scores': scoreMap,
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
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _goToNext(Map<String, int> scoreMap) {
    final index = sliderValue.round();
    if (choices.isEmpty || index < 0 || index >= choices.length) {
      showError(context, "Vælg venligst en mulighed først");
      return;
    }

    final selectedChoice = choices[index];
    final score = scoreMap[selectedChoice] ?? 0;

    saveAnswer(selectedChoice, score);
    Navigator.pushNamed(context, '/Q3');
  }

  @override
  Widget build(BuildContext context) {
    final index = sliderValue.round();

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
                child: Text("Fejl: ${snapshot.error}", style: const TextStyle(color: Colors.white)),
              );
            } else if (!snapshot.hasData) {
              return const Center(
                child: Text("Ingen data tilgængelig.", style: TextStyle(color: Colors.white)),
              );
            } else {
              final questionText = snapshot.data!['text'];
              choices = List<String>.from(snapshot.data!['choices']);
              final scoreMap = Map<String, int>.from(snapshot.data!['scores']);

              return Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            questionText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          OcutuneSlider(
                            value: sliderValue,
                            labels: choices,
                            colors: colors,
                            onChanged: (val) {
                              setState(() => sliderValue = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: OcutuneButton(
                      type: OcutuneButtonType.floatingIcon,
                      onPressed: () => _goToNext(scoreMap),
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
