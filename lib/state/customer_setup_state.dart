import '../models/customer_register_answers_model.dart';

class CustomerSetupState {
  static final CustomerSetupState instance = CustomerSetupState._internal();
  CustomerSetupState._internal();

  // --- Personlige oplysninger ---
  String? gender;
  int? age;
  String? chronotype;
  int? customerId;

  void setCustomerId(int id) {
    customerId = id;
  }
  void setGender(String value) => gender = value;
  void setAge(int value) => age = value;
  void setChronotype(String value) => chronotype = value;

  // --- Midlertidig svaropsamling ---
  final Map<String, AnswerModel> _answers = {};

  void setAnswer(String questionId, AnswerModel answer) {
    _answers[questionId] = answer;
  }

  AnswerModel? getAnswer(String questionId) => _answers[questionId];

  List<AnswerModel> getAllAnswers() => _answers.values.toList();

  // --- Efter registrering ---
  void attachCustomerIdToAnswers(int customerId) {
    for (var answer in _answers.values) {
      answer.attachCustomerId(customerId);
    }
  }

  // --- Ryd state efter gennemført registrering ---
  void reset() {
    gender = null;
    age = null;
    chronotype = null;
    _answers.clear();
  }
}
