import 'package:flutter/material.dart';

class OcutuneSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final List<String> labels;
  final List<Color> colors;

  const OcutuneSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.labels,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final index = value.round().clamp(0, labels.length - 1);
    final color = colors[index.clamp(0, colors.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
          child: Text(labels[index]),
        ),
        const SizedBox(height: 24),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            activeTrackColor: color,
            inactiveTrackColor: Colors.white24,
            thumbColor: color,
            overlayColor: color.withAlpha(51),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: (labels.length - 1).toDouble(),
            divisions: labels.length - 1,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
