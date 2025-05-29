import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
            fontSize: 25.sp,
          ),
          child: Text(labels[index]),
        ),
        SizedBox(height: 24.h),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4.5.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
            activeTrackColor: color,
            inactiveTrackColor: Colors.white24,
            thumbColor: color,
            overlayColor: Color.fromRGBO(color.red, color.green, color.blue, 0.2),
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
