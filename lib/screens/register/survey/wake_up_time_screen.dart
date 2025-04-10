import 'package:flutter/material.dart';
import '/theme/colors.dart';

class WakeUpTimeScreen extends StatefulWidget {
  const WakeUpTimeScreen({super.key});

  @override
  State<WakeUpTimeScreen> createState() => _WakeUpTimeScreenState();
}

class _WakeUpTimeScreenState extends State<WakeUpTimeScreen> {
  TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const Text(
                    "Considering your own individual rhythm,\nat what time would you get up if you were\nentirely free to plan your day?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white12,
                      ),
                      child: Text(
                        selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text(
                      "Previous",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Navigate to next screen
                      Navigator.pushNamed(context, '/nextSurveyStep');
                    },
                    icon: const Text(
                      "Next",
                      style: TextStyle(color: Colors.white),
                    ),
                    label: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
