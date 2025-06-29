// lib/widgets/meq_question_page.dart
import 'package:flutter/material.dart';

import '../../models/meq_survey_model.dart';

class MeqQuestionPage extends StatelessWidget {
  final MeqQuestion question;
  final int? selectedChoiceIndex;
  final void Function(int choiceIndex) onChoiceSelected;

  const MeqQuestionPage({
    super.key,
    required this.question,
    this.selectedChoiceIndex,
    required this.onChoiceSelected,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(
            question.choices.length,
                (index) {
              final choice = question.choices[index];
              final isSelected = selectedChoiceIndex == index;
              return GestureDetector(
                onTap: () => onChoiceSelected(index),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? accent.withOpacity(0.1) : Colors.white,
                    border: Border.all(
                      color: isSelected ? accent : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (!isSelected)
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected ? accent : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          choice.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
