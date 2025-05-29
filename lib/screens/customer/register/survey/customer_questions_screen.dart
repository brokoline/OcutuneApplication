import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/state/customer_setup_state.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/customer_done_setup_screen.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/register_question_widgets.dart';

import '../../../../services/services/api_services.dart';
import '../../../../viewmodel/customer/customer_questions_viewmodel.dart';
import '../../../../models/customer_register_answers_model.dart';
import '../../../../models/customer_registor_choices_model.dart';

class CustomerQuestionsScreen extends StatefulWidget {
  const CustomerQuestionsScreen({super.key});

  @override
  State<CustomerQuestionsScreen> createState() => _CustomerQuestionsScreenState();
}

class _CustomerQuestionsScreenState extends State<CustomerQuestionsScreen> {
  late QuestionViewModel viewModel;
  ChoiceModel? selectedAnswer;

  @override
  void initState() {
    super.initState();
    viewModel = QuestionViewModel();
    viewModel.loadInitial();
  }

  Future<void> _goToNextScreen() async {
    final q = viewModel.currentQuestion;
    final selected = selectedAnswer;
    if (selected == null) return;

    final answer = AnswerModel(
      customerId: CustomerSetupState.instance.customerId, // optional, tilføjes senere
      questionId: int.parse(q.id),
      choiceId: int.parse(selected.id),
      answerText: selected.text,
      questionTextSnap: q.question,
      createdAt: DateTime.now(),
    );

    CustomerSetupState.instance.setAnswer(q.id, answer);
    await ApiService.submitAnswer(answer);

    final success = await viewModel.nextQuestion();
    if (!mounted) return;

    if (!success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CustomerDoneSetupScreen()),
      );
    }

    setState(() => selectedAnswer = null);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<QuestionViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading || viewModel.questions.isEmpty) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final question = viewModel.currentQuestion;
          final layoutType = viewModel.getLayoutTypeForCurrentQuestion();

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              title: Text('Spørgsmål ${viewModel.currentIndex + 1}/${viewModel.questions.length}'),
            ),
            body: buildQuestionLayout(
              layoutType: layoutType,
              question: question.question,
              options: question.answers,
              selected: selectedAnswer,
              onSelect: (val) => setState(() => selectedAnswer = val),
              onNext: selectedAnswer != null ? _goToNextScreen : null,
              onBack: viewModel.previous,
              showBackButton: viewModel.currentIndex > 0,
            ),
          );
        },
      ),
    );
  }
}

Widget buildQuestionLayout({
  required QuestionLayoutType layoutType,
  required String question,
  required List<ChoiceModel> options,
  required ChoiceModel? selected,
  required void Function(ChoiceModel) onSelect,
  required VoidCallback? onNext,
  required VoidCallback? onBack,
  required bool showBackButton,
}) {
  switch (layoutType) {
    case QuestionLayoutType.tiles:
    default:
      return OcutuneQuestionCard(
        question: question,
        options: options,
        selected: selected,
        onSelect: onSelect,
        onNext: onNext,
        onBack: onBack,
        showBackButton: showBackButton,
      );
  }
}
