
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/state/customer_setup_state.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/customer_done_setup_screen.dart';

import '../../../../viewmodel/customer/customer_questions_viewmodel.dart';
import '../../../../models/customer_register_answers_model.dart';
import '../../../../models/customer_registor_choices_model.dart';
import '../../../../widgets/customer_widgets/customer_question_1_screen.dart';
import '../../../../widgets/customer_widgets/customer_question_2_screen.dart';
import '../../../../widgets/customer_widgets/customer_question_3_screen.dart';
import '../../../../widgets/customer_widgets/customer_question_4_screen.dart';
import '../../../../widgets/customer_widgets/customer_question_5_screen.dart';

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

    final questionId = int.tryParse(q.id) ?? viewModel.currentIndex;
    final choiceId = int.tryParse(selected.id);

    if (selected.id == 'fallback' || choiceId == null) {
      debugPrint("❌ Ugyldigt valg-ID: '\${selected.id}' – kan ikke gå videre");
      return;
    }

    final answer = AnswerModel(
      customerId: null, // ❗️ Ikke sat endnu – skal tilføjes efter registrering
      questionId: questionId,
      choiceId: choiceId,
      answerText: selected.text,
      questionTextSnap: q.question,
      createdAt: DateTime.now(),
    );

    CustomerSetupState.instance.setAnswer(q.id, answer); // 🧠 Kun gem lokalt

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
              title: Text(
                "Spørgsmål ${viewModel.currentIndex + 1}/${viewModel.questions.length}",
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Builder(
                builder: (context) {
                  debugPrint('🧠 Spørgsmål: \${question.question}');
                  debugPrint('📋 Valgmuligheder: \${question.answers.map((a) => a.text).toList()}');
                  debugPrint('✅ Valgt: \${selectedAnswer?.text}');
                  debugPrint('📐 Layouttype: \$layoutType');

                  return buildQuestionLayout(
                    questionId: question.id,
                    layoutType: layoutType,
                    question: question.question,
                    options: question.answers,
                    selected: selectedAnswer,
                    onSelect: (val) => setState(() => selectedAnswer = val),
                    onNext: selectedAnswer != null ? _goToNextScreen : null,
                    onBack: viewModel.previous,
                    showBackButton: viewModel.currentIndex > 0,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget buildQuestionLayout({
  required String questionId,
  required QuestionLayoutType layoutType,
  required String question,
  required List<ChoiceModel> options,
  required ChoiceModel? selected,
  required void Function(ChoiceModel) onSelect,
  required VoidCallback? onNext,
  required VoidCallback? onBack,
  required bool showBackButton,
}) {
  switch (questionId) {
    case '1':
      return CustomerQuestion1Widget(
        questionText: question,
        choices: options.map((o) => o.text).toList(),
        selectedOption: selected?.text,
        onSelect: (text) {
          final choice = options.firstWhere((o) => o.text == text);
          onSelect(choice);
        },
        onNext: onNext ?? () {},
      );
    case '2':
      return CustomerQuestion2Widget(
        questionText: question,
        choices: options.map((o) => o.text).toList(),
        sliderValue: selected != null ? options.indexOf(selected).toDouble() : 2,
        onSliderChanged: (val) {
          final index = val.round().clamp(0, options.length - 1);
          onSelect(options[index]);
        },
        onNext: onNext ?? () {},
      );
    case '3':
      return CustomerQuestion3Widget(
        questionText: question,
        choices: options.map((o) => o.text).toList(),
        selectedOption: selected?.text,
        onSelect: (text) {
          final choice = options.firstWhere((o) => o.text == text);
          onSelect(choice);
        },
        onNext: onNext ?? () {},
      );
    case '4':
      return CustomerQuestion4Widget(
        questionText: question,
        choices: options.map((o) => o.text).toList(),
        selectedOption: selected?.text,
        onSelect: (text) {
          final choice = options.firstWhere((o) => o.text == text);
          onSelect(choice);
        },
        onNext: onNext ?? () {},
      );
    case '5':
      return CustomerQuestion5Widget(
        questionText: question,
        choices: options.map((o) => o.text).toList(),
        selectedOption: selected?.text,
        onSelect: (text) {
          final choice = options.firstWhere((o) => o.text == text);
          onSelect(choice);
        },
        onNext: onNext ?? () {},
      );
    default:
      return Center(
        child: Text(
          "Ukendt spørgsmål",
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
      );
  }
}
