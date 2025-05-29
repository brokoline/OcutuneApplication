import 'customer_registor_choices_model.dart';

class QuestionModel {
  final String id;
  final String question;
  final List<ChoiceModel> answers;

  QuestionModel({
    required this.id,
    required this.question,
    required this.answers,
  });

  factory QuestionModel.fromJson(
      Map<String, dynamic> json,
      List<Map<String, dynamic>> allChoices,
      ) {
    final relevantChoices = allChoices
        .where((c) => c['question_id'].toString() == json['id'].toString())
        .toList();

    return QuestionModel(
      id: json['id'].toString(),
      question: json['question_text'] ?? '',
      answers: relevantChoices.map((c) => ChoiceModel.fromJson(c)).toList(),
    );
  }
}
