
import '../models/customer_register_answers_model.dart';
import '../services/services/api_services.dart';

class CustomerSetupState {
  static final CustomerSetupState instance = CustomerSetupState._internal();
  CustomerSetupState._internal();

  // --- Personlige oplysninger ---
  String? email;
  String? password;
  String? firstName;
  String? lastName;
  String? gender;
  int? age;
  String? chronotype;
  int? customerId;

  void setEmail(String value) => email = value;
  void setPassword(String value) => password = value;
  void setFirstName(String value) => firstName = value;
  void setLastName(String value) => lastName = value;
  void setGender(String value) => gender = value;
  void setAge(int value) => age = value;
  void setChronotype(String value) => chronotype = value;

  void setCustomerId(int id) {
    customerId = id;
  }

  // --- Midlertidig svaropsamling ---
  final Map<String, AnswerModel> _answers = {};

  void setAnswer(String questionId, AnswerModel answer) {
    _answers[questionId] = answer;
  }

  AnswerModel? getAnswer(String questionId) => _answers[questionId];

  List<AnswerModel> getAllAnswers() => _answers.values.toList();

  // --- Tilknyt ID efter registrering ---
  void attachCustomerIdToAnswers(int customerId) {
    for (var answer in _answers.values) {
      answer.attachCustomerId(customerId);
    }
  }

  // --- Send alle svar til backend efter registrering ---
  Future<void> flushAnswersToBackend() async {
    if (customerId == null) {
      throw Exception('Kan ikke sende svar – customerId mangler');
    }

    attachCustomerIdToAnswers(customerId!);

    for (final answer in _answers.values) {
      try {
        await ApiService.submitAnswerSmart(answer);
        print("✅ Svar sendt: ${answer.questionTextSnap}");
      } catch (e) {
        print("❌ Fejl ved afsendelse af svar: $e");
      }
    }

    // Når alle svar er sendt, beregn score i backend
    try {
      await ApiService.calculateBackendScore(customerId!);
      print("🎯 Score beregnet i backend for ID: $customerId");
    } catch (e) {
      print("⚠️ Fejl ved beregning af score: $e");
    }

    // Valgfrit: ryd svar når alt er sendt
    // _answers.clear();
  }

  // --- Nulstil alt efter registrering eller logout ---
  void reset() {
    email = null;
    password = null;
    firstName = null;
    lastName = null;
    gender = null;
    age = null;
    chronotype = null;
    customerId = null;
    _answers.clear();
  }
}
