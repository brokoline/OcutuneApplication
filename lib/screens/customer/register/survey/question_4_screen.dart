import 'package:flutter/material.dart';
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';

class QuestionFourScreen extends StatefulWidget {
  const QuestionFourScreen({super.key});

  @override
  State<QuestionFourScreen> createState() => QuestionFourScreenState();
}

class QuestionFourScreenState extends State<QuestionFourScreen> {
  String? selectedOption;

  final List<String> options = [
    "8:00 PM – 9:00 PM",
    "9:00 PM – 10:15 PM",
    "10:15 PM – 12:45 AM",
    "12:45 AM – 2:00 AM",
    "2:00 AM – 3:00 AM",
    "Im fresh all day.."
  ];

  void _goToNextScreen() {
    if (selectedOption != null) {
      Navigator.pushNamed(context, '/morningEveningType');
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "What time in the evening do you\nfeel tired and in need of sleep?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ...options.map((option) => _buildOption(option)).toList(),
                      const SizedBox(height: 100),
                    ],
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
