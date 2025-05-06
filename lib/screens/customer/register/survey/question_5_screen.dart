import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';

class QuestionFiveScreen extends StatefulWidget {
  const QuestionFiveScreen({super.key});

  @override
  State<QuestionFiveScreen> createState() => _QuestionFiveScreenState();
}

class _QuestionFiveScreenState extends State<QuestionFiveScreen> {
  String? selectedOption;
  late Future<Map<String, dynamic>> _questionData;

  @override
  void initState() {
    super.initState();
    _questionData = fetchQuestionData(5);
  }

  Future<Map<String, dynamic>> fetchQuestionData(int questionId) async {
    const baseUrl = 'https://ocutune.ddns.net';
    final url = Uri.parse('$baseUrl/questions');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      final question = data.firstWhere(
            (q) => q['id'] == questionId,
        orElse: () => null,
      );

      if (question == null) {
        throw Exception("Spørgsmålet med ID $questionId blev ikke fundet.");
      }

      final choices = question['choices'];
      if (choices == null || choices is! List) {
        throw Exception("Svarmuligheder mangler eller er i forkert format.");
      }

      return {
        'text': question['question_text'] ?? 'Ingen spørgsmåls-tekst.',
        'choices': List<String>.from(choices),
      };
    } else {
      throw Exception('Kunne ikke hente data (statuskode: ${response.statusCode})');
    }
  }

  void _goToNextScreen() {
    if (selectedOption != null) {
      Navigator.pushNamed(context, '/doneSetup');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vælg venligst en type først")),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder<Map<String, dynamic>>(
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
                  final options = snapshot.data!['choices'];

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Column(
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
                            ...options.map((option) => _buildOption(option)).toList(),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
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
