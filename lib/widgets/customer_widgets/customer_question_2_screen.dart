import 'package:flutter/material.dart';

import '/widgets/ocutune_button.dart';
import '/widgets/ocutune_slider.dart';

class CustomerQuestion2Widget extends StatelessWidget {
  final String questionText;
  final List<String> choices;
  final double sliderValue;
  final void Function(double) onSliderChanged;
  final VoidCallback onNext;

  const CustomerQuestion2Widget({
    super.key,
    required this.questionText,
    required this.choices,
    required this.sliderValue,
    required this.onSliderChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.red,
      Colors.orange,
      Colors.white,
      Colors.lightGreen,
      Colors.green,
    ];

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
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
                OcutuneSlider(
                  value: sliderValue,
                  labels: choices,
                  colors: colors,
                  onChanged: onSliderChanged,
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
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}
