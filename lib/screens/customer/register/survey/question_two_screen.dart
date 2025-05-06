import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';

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
    Colors.green
  ];

  @override
  void initState() {
    super.initState();
    _questionData = fetchQuestionData(2);
  }

  Future<Map<String, dynamic>> fetchQuestionData(int questionId) async {
    const baseUrl = 'https://ocutune.ddns.net'; // 10.0.2.2 for Android
    final url = Uri.parse('$baseUrl/questions');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final question = data.firstWhere(
            (q) => q['id'] == questionId,
        orElse: () => null,
      );

      if (question == null) {
        throw Exception("Question with ID $questionId not found.");
      }

      return {
        'text': question['question_text'],
        'choices': List<String>.from(question['choices']),
      };
    } else {
      throw Exception('Failed to load question (status ${response.statusCode})');
    }
  }

  void _goToNext() {
    Navigator.pushNamed(context, '/peakTime');
  }

  @override
  Widget build(BuildContext context) {
    final int index = sliderValue.round();

    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: lightGray,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _questionData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white));
                    } else if (!snapshot.hasData) {
                      return const Text("No question found.", style: TextStyle(color: Colors.white));
                    } else {
                      final questionText = snapshot.data!['text'];
                      final choices = snapshot.data!['choices'];

                      return Column(
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
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              color: colors[index],
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            ),
                            child: Text(choices[index]),
                          ),
                          const SizedBox(height: 24),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4.5,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                              activeTrackColor: colors[index],
                              inactiveTrackColor: Colors.white24,
                              thumbColor: colors[index],
                              overlayColor: colors[index].withOpacity(0.2),
                            ),
                            child: Slider(
                              value: sliderValue,
                              min: 0,
                              max: (choices.length - 1).toDouble(),
                              divisions: choices.length - 1,
                              onChanged: (value) {
                                setState(() => sliderValue = value);
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: OcutuneButton(
                type: OcutuneButtonType.floatingIcon,
                onPressed: _goToNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}