import 'package:flutter/material.dart';
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';

class MorningEveningTypeScreen extends StatefulWidget {
  const MorningEveningTypeScreen({super.key});

  @override
  State<MorningEveningTypeScreen> createState() => _MorningEveningTypeScreenState();
}

class _MorningEveningTypeScreenState extends State<MorningEveningTypeScreen> {
  String? selectedOption;

  final List<String> options = [
    "Morning person",
    "Evening person",
  ];

  void _goToNextScreen() {
    if (selectedOption != null) {
      Navigator.pushNamed(context, '/doneSetup');
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Do you consider yourself a “morning” or an “evening” type?",
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
