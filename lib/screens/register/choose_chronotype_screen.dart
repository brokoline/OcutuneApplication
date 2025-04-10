import 'package:flutter/material.dart';
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';

class ChooseChronotypeScreen extends StatefulWidget {
  const ChooseChronotypeScreen({super.key});

  @override
  State<ChooseChronotypeScreen> createState() => _ChooseChronotypeScreenState();
}

class _ChooseChronotypeScreenState extends State<ChooseChronotypeScreen> {
  String? selectedChronotype;

  final List<Map<String, String>> chronotypes = [
    {
      'title': 'Lark',
      'description': 'Feel energized and focused in the early morning hours and usually prefer an early bedtime.'
    },
    {
      'title': 'Dove',
      'description': 'Have a natural sleep-wake cycle that falls somewhere between being an early riser and a night owl.'
    },
    {
      'title': 'Owl',
      'description': 'Tend to be most alert and lively in the evening and often stay up late'
    },
  ];

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Already know your Chronotype?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Select your chronotype or continue with survey",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ...chronotypes.map((type) => _buildChronoCard(type)).toList(),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          // Navigate to info screen
                        },
                        child: const Text(
                          "What is a chronotype? Learn more",
                          style: TextStyle(
                            color: Colors.white70,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white54),
                              ),
                            ),
                            onPressed: () {
                              // Navigate to survey
                            },
                            child: const Text("Take Survey"),
                          ),
                        ),
                      ),
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
                onPressed: () {
                  if (selectedChronotype != null) {
                    // Go to next screen
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChronoCard(Map<String, String> type) {
    final isSelected = selectedChronotype == type['title'];
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedChronotype = type['title'];
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.white10 : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4.0, right: 12),
              child: Icon(Icons.brightness_2, color: Colors.white, size: 28),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type['title']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type['description']!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
