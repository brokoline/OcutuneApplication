// lib/models/meq_question.dart


class MeqChoice {
  final String text;
  final int score;
  MeqChoice({required this.text, required this.score});
}

class MeqQuestion {
  final int id;
  final String questionText;
  final List<MeqChoice> choices;

  MeqQuestion({
    required this.id,
    required this.questionText,
    required this.choices,
  });
}
