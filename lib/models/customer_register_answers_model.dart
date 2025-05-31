class AnswerModel {
  int? customerId;
  final int questionId;
  final int choiceId;
  final String answerText;
  final String questionTextSnap;
  final DateTime? createdAt;

  AnswerModel({
    this.customerId,
    required this.questionId,
    required this.choiceId,
    required this.answerText,
    required this.questionTextSnap,
    this.createdAt,
  });

  void attachCustomerId(int id) {
    customerId = id;
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'question_id': questionId,
      'choice_id': choiceId,
      'answer_text': answerText,
      'question_text_snap': questionTextSnap,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      customerId: json['customer_id'],
      questionId: json['question_id'],
      choiceId: json['choice_id'],
      answerText: json['answer_text'],
      questionTextSnap: json['question_text_snap'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }
}
