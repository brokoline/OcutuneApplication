import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_selectable_tile.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_next_step_button.dart';

import '../../../../../services/services/customer_data_service.dart';
import '../../../../widgets/customer_widgets/customer_app_bar.dart';

class QuestionFiveScreen extends StatefulWidget {
  const QuestionFiveScreen({Key? key}) : super(key: key);

  @override
  State<QuestionFiveScreen> createState() => _QuestionFiveScreenState();
}

class _QuestionFiveScreenState extends State<QuestionFiveScreen> {
  String? selectedOption;
  Map<String, int> choiceScores = {};
  late Future<Map<String, dynamic>> _questionData;

  @override
  void initState() {
    super.initState();
    currentQuestion = 5;
    _questionData = fetchQuestionData(5);
  }

  Future<Map<String, dynamic>> fetchQuestionData(int questionId) async {
    const baseUrl      = 'https://ocutune2025.ddns.net/api';
    final questionsUrl = Uri.parse('$baseUrl/questions');
    final choicesUrl   = Uri.parse('$baseUrl/choices');

    final responses = await Future.wait([
      http.get(questionsUrl),
      http.get(choicesUrl),
    ]);

    if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
      final List<dynamic> questions = jsonDecode(responses[0].body) as List<dynamic>;
      final List<dynamic> choices   = jsonDecode(responses[1].body) as List<dynamic>;

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
            SizedBox(width: 12.w),
            Expanded(child: Text(message, style: TextStyle(color: Colors.white, fontSize: 14.sp))),
          ],
        ),
      ),
    );
  }

  void _goToNextScreen() {
    if (selectedOption != null) {
      final score = choiceScores[selectedOption!] ?? 0;
      saveAnswer(selectedOption!, score);
      Navigator.pushNamed(context, '/doneSetup');
    } else {
      showError(context, "Vælg venligst en mulighed først");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: const CustomerAppBar(
        showBackButton: true,
        title: 'Spørgsmål 5/5',
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
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
              );
            } else {
              final data        = snapshot.data!;
              final questionText = data['text']    as String;
              final options      = List<String>.from(data['choices'] as List);
              choiceScores       = Map<String,int>.from(data['scores'] as Map);

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          questionText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 22.h),
                        ...options.map((option) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 6.h),
                            child: OcutuneSelectableTile(
                              text: option,
                              selected: selectedOption == option,
                              onTap: () => setState(() => selectedOption = option),
                            ),
                          );
                        }).toList(),
                        SizedBox(height: 100.h),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 24.h,
                    right: 24.w,
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
