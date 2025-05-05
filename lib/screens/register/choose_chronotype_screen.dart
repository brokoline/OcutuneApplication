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
      'description':
      'Feel energized and focused in the early morning hours and usually prefer an early bedtime.',
      'image': 'assets/images/lark.png',
    },
    {
      'title': 'Dove',
      'description':
      'Natural sleep-wake cycle that falls somewhere between being an early riser and a night owl.',
      'image': 'assets/images/dove.png',
    },
    {
      'title': 'Owl',
      'description':
      'Har tendens til at være mest vågen og livlig om aftenen og er ofte oppe sent.',
      'image': 'assets/images/nightowl.png',
    },
  ];

  void _goToNextScreen() {
    if (selectedChronotype != null) {
      Navigator.pushNamed(context, '/learnAboutChronotypes');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a chronotype first")),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: Text(
                            "Already know your Chronotype?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            "Select your chronotype or continue with survey",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Chronotype cards
                        ...chronotypes.map((type) => _buildChronoCard(type)).toList(),

                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/learn'),
                            child: const Text(
                              "What is a chronotype? Learn more",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                Navigator.pushNamed(context, '/wakeUpTime');
                              },
                              child: const Text("Take Survey"),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: OcutuneButton(
                            type: OcutuneButtonType.floatingIcon,
                            onPressed: _goToNextScreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.white : Colors.white24),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? Colors.white10 : Colors.transparent,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Image.asset(
                type['image']!,
                width: 28,
                height: 28,
              ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
