import 'package:flutter/material.dart';
import '../../models/customer_register_answers_model.dart';
import '../../models/customer_registor_choices_model.dart';
import '../../models/custumer_register_questions_model.dart';
import '../../repository/customer_questions_repository.dart';
import '../../state/customer_setup_state.dart';

class QuestionViewModel extends ChangeNotifier {
  List<QuestionModel> questions = [];
  int currentIndex = 0;
  bool isLoading = true;

  Future<void> loadInitial() async {
    final first = await QuestionRepository().getQuestionByPosition(0);
    if (first != null) {
      questions = [first];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> nextQuestion() async {
    final nextIndex = currentIndex + 1;
    final next = await QuestionRepository().getQuestionByPosition(nextIndex);

    if (next != null) {
      questions.add(next);
      currentIndex++;
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  /// Bruges når brugeren vælger et svar
  void answerQuestion(ChoiceModel choice) {
    final current = currentQuestion;

    final answer = AnswerModel(
      customerId: CustomerSetupState.instance.customerId,
      questionId: int.parse(current.id),
      choiceId: int.parse(choice.id), // 👈 Dette er vigtigt
      answerText: choice.text,
      questionTextSnap: current.question,
      createdAt: DateTime.now(),
    );

    // Gem lokalt – submission til API kan ske senere
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
