import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';



class WakeUpTimeScreen extends StatefulWidget {
  const WakeUpTimeScreen({super.key});

  @override
  State<WakeUpTimeScreen> createState() => _WakeUpTimeScreenState();
}

class _WakeUpTimeScreenState extends State<WakeUpTimeScreen> {
  String? selectedOption;
  late Future<Map<String, dynamic>> _questionData;

  @override
  void initState() {
    super.initState();
    _questionData = fetchQuestionData(1);
  }

  Future<Map<String, dynamic>> fetchQuestionData(int questionId) async {
    const baseUrl = 'http://192.168.64.6:5000'; // 10.0.2.2 for Android
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

  void _goToNextScreen() {
    if (selectedOption != null) {
      Navigator.pushNamed(context, '/tirednessSlider');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an option first")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: lightGray,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _questionData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        );
                      } else if (!snapshot.hasData) {
                        return const Text(
                          "No question found.",
                          style: TextStyle(color: Colors.white),
                        );
                      } else {
                        final questionText = snapshot.data!['text'];
                        final choices = snapshot.data!['choices'];

                        return Column(
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
                            ...choices.map((option) => _buildOption(option)).toList(),
                            const SizedBox(height: 100),
                          ],
                        );
                      }
                    },
                  ),
                ),
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
        ),
      ),
    );
  }

  Widget _buildOption(String option) {
    final isSelected = selectedOption == option;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOption = option;
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.white10 : Colors.transparent,
        ),
        child: Text(
          option,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
