import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';
import '/widgets/ocutune_selectable_tile.dart';
import '../../../../services/services/user_data_service.dart';

class QuestionThreeScreen extends StatefulWidget {
  const QuestionThreeScreen({super.key});

  @override
  State<QuestionThreeScreen> createState() => _QuestionThreeScreenState();
}

class _QuestionThreeScreenState extends State<QuestionThreeScreen> {
  String? selectedOption;
  Map<String, int> choiceScores = {};
  late Future<Map<String, dynamic>> _questionData;

  @override
  void initState() {
    super.initState();
    currentQuestion = 3;
    _questionData = fetchQuestionData(3);
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
      final choices = jsonDecode(responses[1].body) as List;

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

      final scoreMap = {
        for (var c in filteredChoices)
          c['choice_text'] as String: c['score'] as int,
      };

      return {
        'text': question['question_text'],
        'choices': scoreMap.keys.toList(),
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

  void _goToNextScreen() {
    if (selectedOption != null) {
      final score = choiceScores[selectedOption!] ?? 0;
      saveAnswer(selectedOption!, score);
      Navigator.pushNamed(context, '/Q4');
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
            } else if (!snapshot.hasData) {
              return const Center(
                child: Text(
                  'Ingen data tilgængelig.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            } else {
              final questionText = snapshot.data!['text'];
              final options = snapshot.data!['choices'] as List<String>;
              choiceScores = Map<String, int>.from(snapshot.data!['scores']);

              return LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                      onTap: () {
                                        setState(() {
                                          selectedOption = option;
                                        });
                                      },
                                    );
                                  }),
                                  const SizedBox(height: 100),
                                ],
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: OcutuneButton(
                                  type: OcutuneButtonType.floatingIcon,
                                  onPressed: _goToNextScreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
