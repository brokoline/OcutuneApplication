// lib/models/meq_survey_model.dart

class MeqChoice {
  final int id;
  final String text;
  final int score;

  MeqChoice({
    required this.id,
    required this.text,
    required this.score,
  });

  factory MeqChoice.fromJson(Map<String, dynamic> json) {
    return MeqChoice(
      id: json['id'] as int,
      text: json['choice_text'] as String,
      score: json['score'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'choice_text': text,
      'score': score,
    };
  }
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

  factory MeqQuestion.fromJson(Map<String, dynamic> json) {
    final raw = json['choices'] as List<dynamic>;
    return MeqQuestion(
      id: json['id'] as int,
      questionText: json['question_text'] as String,
      choices: raw
          .map((c) => MeqChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'choices': choices.map((c) => c.toJson()).toList(),
    };
  }
}

class MeqAnswer {
  final int id;
  final int participantId;
  final int questionId;
  final int choiceId;
  final int score;
  final DateTime createdAt;

  MeqAnswer({
    required this.id,
    required this.participantId,
    required this.questionId,
    required this.choiceId,
    required this.score,
    required this.createdAt,
  });

  factory MeqAnswer.fromJson(Map<String, dynamic> json) {
    return MeqAnswer(
      id: json['id'] as int,
      participantId: json['participant_id'] as int,
      questionId: json['question_id'] as int,
      choiceId: json['choice_id'] as int,
      score: json['score'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_id': participantId,
      'question_id': questionId,
      'choice_id': choiceId,
      'score': score,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
