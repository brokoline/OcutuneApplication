import 'package:flutter/material.dart';
import '/theme/colors.dart';
import '/widgets/ocutune_button.dart';

class TirednessSliderScreen extends StatefulWidget {
  const TirednessSliderScreen({super.key});

  @override
  State<TirednessSliderScreen> createState() => _TirednessSliderScreenState();
}

class _TirednessSliderScreenState extends State<TirednessSliderScreen> {
  double sliderValue = 2;

  final List<String> labels = [
    "Very tired",
    "Tired",
    "Neutral",
    "Rested",
    "Very rested"
  ];

  final List<Color> colors = [
    Colors.red,
    Colors.orange,
    Colors.white,
    Colors.lightGreen,
    Colors.green
  ];

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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "During the first half hour after waking up,\nhow do you usually feel?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                        fontSize: 50,
                      ),
                      child: Text(labels[index]),
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
                        max: 4,
                        divisions: 4,
                        onChanged: (value) {
                          setState(() => sliderValue = value);
                        },
                      ),
                    ),
                  ],
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
