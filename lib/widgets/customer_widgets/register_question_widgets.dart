// widgets/question_widgets.dart – opdateret med OcutuneQuestionCard m.m.

import 'package:flutter/material.dart';
import '../../models/customer_registor_choices_model.dart';

const primaryColor = Color(0xFF00BFA5); // fallback hvis ikke defineret
const darkGray = Color(0xFF2C2C2C); // fallback hvis ikke defineret

class QuestionText extends StatelessWidget {
  final String text;

  const QuestionText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class SelectableTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SelectableTile({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: selected ? primaryColor.withOpacity(0.2) : darkGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? primaryColor : Colors.grey.shade700,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? primaryColor : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class OcutuneQuestionCard extends StatelessWidget {
  final String question;
  final List<ChoiceModel> options;
  final ChoiceModel? selected;
  final void Function(ChoiceModel) onSelect;
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final bool showBackButton;

  const OcutuneQuestionCard({
    super.key,
    required this.question,
    required this.options,
    required this.selected,
    required this.onSelect,
    required this.onNext,
    required this.onBack,
    required this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(question, style: const TextStyle(fontSize: 18, color: Colors.white)),
        const SizedBox(height: 20),
        ...options.map((choice) => SelectableTile(
          label: choice.text, // ✅ matcher det forventede
          selected: selected?.id == choice.id,
          onTap: () => onSelect(choice),
        )),
        const SizedBox(height: 20),
        Row(
          children: [
            if (showBackButton)
              ElevatedButton(onPressed: onBack, child: const Text("Tilbage")),
            const Spacer(),
            ElevatedButton(onPressed: onNext, child: const Text("Næste")),
          ],
        ),
      ],
    );
  }
}
