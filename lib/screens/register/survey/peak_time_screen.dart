import 'package:flutter/material.dart';
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';

class PeakTimeScreen extends StatefulWidget {
  const PeakTimeScreen({super.key});

  @override
  State<PeakTimeScreen> createState() => _PeakTimeScreenState();
}

class _PeakTimeScreenState extends State<PeakTimeScreen> {
  String? selectedOption;

  final List<String> options = [
    "10:00 PM – 4:00 AM",
    "4:00 AM – 7:00 AM",
    "7:00 AM – 9:00 AM",
    "9:00 AM – 4:00 PM",
    "4:00 PM – 10:00 PM",
    "I never peak"
  ];

  void _goToNextScreen() {
    if (selectedOption != null) {
      Navigator.pushNamed(context, '/timeOfTiredness');
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
                        "At what time of the day do you think that you reach your “feeling best” peak?",
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
