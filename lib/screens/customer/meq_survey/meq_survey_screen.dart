// lib/screens/meq_test_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/meq_survey_model.dart';
import '../../../services/services/api_services.dart';
import '../../../widgets/meq_widgets/meq_question_page.dart';


class MeqSurveyScreen extends StatefulWidget {
  final int participantId; // f.eks. modtaget fra login

  const MeqSurveyScreen({super.key, required this.participantId});

  @override
  MeqSurveyScreenState createState() => MeqSurveyScreenState();
}

class MeqSurveyScreenState extends State<MeqSurveyScreen> {
  late Future<List<MeqQuestion>> _futureQuestions;
  final Map<int, Map<String, int>> _answers = {};
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _futureQuestions = ApiService.fetchMeqQuestions();
    _pageController = null;
  }

  void _handleAnswer({
    required int questionId,
    required int choiceIndex,
    required int score,
  }) {
    setState(() {
      _answers[questionId] = {
        'choiceIndex': choiceIndex,
        'score': score,
      };
    });
  }

  void _goToPage(int pageIndex) {
    if (_pageController == null) return;
    _pageController!.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitAllAnswers() async {
    // 1) Først bygger vi en JSON-struktur med alle besvarelser
    //    Vi skal bruge question_id, choice_id og score for hver.
    //    Men bilmærke: Vi har gemt choiceIndex og score, men mangler choice_id.
    //
    //    For at løse det har vi to muligheder:
    //    a) I MeqQuestionPage returnere vi også MeqChoice.id i onAnswer
    //       (det er simplere – så slipper vi for at regne choiceIndex om til choice_id).
    //    b) Vi kan slå det op ved at tage questions[questionId - 1].choices[choiceIndex].id.
    //       (det forudsætter at id’erne i listen er i nøjagtig samme rækkefølge og at questionId-1 matcher index).
    //
    //    Her vælger vi *b)*: vi har adgang til alle spørgsmålene i lokal variabel questions,
    //    så vi kan finde choiceId ud fra index:
    //
    final questions = await _futureQuestions;
    List<Map<String, dynamic>> answerPayload = [];

    _answers.forEach((questionId, answerData) {
      int idx = answerData['choiceIndex']!;
      int scoreVal = answerData['score']!;

      // Find selve MeqChoice.id via questionId og idx:
      MeqQuestion theQuestion = questions.firstWhere((q) => q.id == questionId);
      int choiceId = theQuestion.choices[idx].id;

      answerPayload.add({
        'question_id': questionId,
        'choice_id': choiceId,
        'score': scoreVal,
      });
    });

    // 2) Byg JSON:
    final body = jsonEncode({
      'participant_id': widget.participantId,
      'answers': answerPayload,
    });

    // 3) Send POST til save_meq_answers.php
    final url = Uri.parse('https://myserver.com/api/save_meq_answers.php');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: body,
      );

      if (response.statusCode == 200) {
        // Parse evt. serverens respons
        final jsonResp = jsonDecode(response.body);
        if (jsonResp['status'] == 'OK') {
          // Vis en dialog og gå evt. tilbage
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Tak!'),
              content: const Text('Dine svar er gemt.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Luk dialog
                    Navigator.of(context).pop(); // Luk test-skærm
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          throw Exception('Serverfejl: ${jsonResp['error'] ?? 'Ukendt fejl'}');
        }
      } else {
        throw Exception('HTTP fejl: ${response.statusCode}');
      }
    } catch (e) {
      // Hvis der sker en fejl under gem,
      // kan du f.eks. vise en Snackbar eller AlertDialog:
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Fejl'),
          content: Text('Kunne ikke gemme svar: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MEQ-Test'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<MeqQuestion>>(
        future: _futureQuestions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Fejl ved hentning af spørgsmål:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Ingen spørgsmål fundet.'));
          } else {
            final questions = snapshot.data!;
            _pageController ??= PageController(initialPage: 0);
            final totalQuestions = questions.length;

            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: totalQuestions,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      final alreadySelectedIndex =
                      _answers[question.id]?['choiceIndex'];
                      return MeqQuestionPage(
                        question: question,
                        selectedChoiceIndex: alreadySelectedIndex,
                        onChoiceSelected: (choiceIndex) {
                          _handleAnswer(
                            questionId: question.id,
                            choiceIndex: choiceIndex,
                            score: question.choices[choiceIndex].score,
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          final currentPage =
                              _pageController?.page?.round() ?? 0;
                          if (currentPage > 0) {
                            _goToPage(currentPage - 1);
                          }
                        },
                        child: const Text('Tilbage'),
                      ),
                      Builder(builder: (context) {
                        final currentPage =
                        _pageController?.hasClients == true
                            ? _pageController!.page?.round() ?? 0
                            : 0;
                        return Text(
                          'Spørgsmål ${currentPage + 1} / $totalQuestions',
                          style: const TextStyle(fontSize: 16),
                        );
                      }),
                      ElevatedButton(
                        onPressed: () {
                          final currentPage =
                              _pageController?.page?.round() ?? 0;
                          if (currentPage < totalQuestions - 1) {
                            _goToPage(currentPage + 1);
                          } else {
                            _submitAllAnswers();
                          }
                        },
                        child: Text(
                          (_pageController?.hasClients == true
                              ? _pageController!.page?.round() ?? 0
                              : 0) <
                              totalQuestions - 1
                              ? 'Næste'
                              : 'Afslut',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
