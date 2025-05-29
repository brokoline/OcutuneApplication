import 'package:flutter/material.dart';
import '../../models/customer_register_answers_model.dart';
import '../../models/customer_registor_choices_model.dart';
import '../../models/custumer_register_questions_model.dart';
import '../../repository/customer_questions_repository.dart';
import '../../services/services/api_services.dart';
import '../../state/customer_setup_state.dart';


class QuestionViewModel extends ChangeNotifier {
  int totalQuestionCount = 0;
  List<QuestionModel> questions = [];
  int currentIndex = 0;
  bool isLoading = true;

  Future<void> loadInitial() async {
    final rawQuestions = await ApiService.fetchQuestionsWithChoicesSmart(); // /questions
    final allChoices = await ApiService.fetchAllChoicesSmart();             // /choices

    final allParsed = rawQuestions
        .map((q) => QuestionModel.fromJson(q, allChoices))
        .toList();

    questions = [allParsed[0]];
    totalQuestionCount = allParsed.length;

    isLoading = false;
    notifyListeners();
  }



  Future<bool> nextQuestion() async {
    final nextIndex = currentIndex + 1;

    // Tjek om vi allerede har nået slutningen
    if (nextIndex >= totalQuestionCount) {
      debugPrint("🚫 Der er ikke flere spørgsmål – stopper flow");
      return false;
    }

    final next = await QuestionRepository().getQuestionByPosition(nextIndex);

    if (next != null) {
      questions.add(next);
      currentIndex++;
      notifyListeners();
      return true;
    } else {
      debugPrint("❌ Ingen spørgsmål fundet med position = $nextIndex");
      return false;
    }
  }

  /// Bruges når brugeren vælger et svar
  void answerQuestion(ChoiceModel choice) {
    final current = currentQuestion;

    final questionId = int.tryParse(current.id) ?? currentIndex;
    final choiceId = int.tryParse(choice.id);
    if (choiceId == null || choice.id == 'fallback') {
      debugPrint("❌ Ugyldigt valg-ID: '${choice.id}' – gemmer ikke svar");
      return;
    }


    final answer = AnswerModel(
      customerId: CustomerSetupState.instance.customerId,
      questionId: questionId, // fallback til index
      choiceId: choiceId,
      answerText: choice.text,
      questionTextSnap: current.question,
      createdAt: DateTime.now(),
    );

    CustomerSetupState.instance.setAnswer(current.id, answer);
  }

  void previous() {
    if (currentIndex > 0) {
      currentIndex--;
      notifyListeners();
    }
  }

  QuestionModel get currentQuestion => questions[currentIndex];

  QuestionLayoutType getLayoutTypeForCurrentQuestion() {
    switch (currentIndex) {
      case 0:
      case 4:
        return QuestionLayoutType.tiles;
      case 1:
      case 3:
        return QuestionLayoutType.buttons;
      default:
        return QuestionLayoutType.tiles;
    }
  }
}

enum QuestionLayoutType {
  tiles,
  buttons,
  centerAligned,
  horizontal,
  iconTiles,
}
