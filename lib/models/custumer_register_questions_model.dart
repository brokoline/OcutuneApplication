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

  factory QuestionModel.fromJson(Map<String, dynamic> questionJson, List<dynamic> choiceJsonList) {
    return QuestionModel(
      id: questionJson['id'].toString(),
      question: questionJson['question_text'],
      answers: choiceJsonList
          .map((choiceJson) => ChoiceModel.fromJson(choiceJson))
          .toList(),
    );
  }
}
