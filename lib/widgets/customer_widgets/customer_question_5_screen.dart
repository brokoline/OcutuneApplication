import 'package:flutter/material.dart';
import '/widgets/ocutune_button.dart';
import '/widgets/ocutune_selectable_tile.dart';

class CustomerQuestion5Widget extends StatelessWidget {
  final String questionText;
  final List<String> choices;
  final String? selectedOption;
  final void Function(String) onSelect;
  final VoidCallback onNext;

  const CustomerQuestion5Widget({
    super.key,
    required this.questionText,
    required this.choices,
    required this.selectedOption,
    required this.onSelect,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    questionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...choices.map((option) {
                    return OcutuneSelectableTile(
                      text: option,
                      selected: selectedOption == option,
                      onTap: () => onSelect(option),
                    );
                  }),
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
            onPressed: onNext,
          ),
        ),
      ],
    );
  }
}
