import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_selectable_tile.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_next_step_button.dart';
import '../../../../../services/services/customer_data_service.dart';
import '../../../../widgets/customer_widgets/customer_app_bar.dart';
import 'question_controller.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  String? selectedOption;

  @override
  void initState() {
    super.initState();
    Provider.of<QuestionController>(context, listen: false).fetchQuestions();
  }

  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.red.shade700,
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          SizedBox(width: 12.w),
          Expanded(child: Text(message, style: TextStyle(color: Colors.white))),
        ],
      ),
    ));
  }

  void _goToNextScreen(QuestionController controller) {
    if (selectedOption != null) {
      final score = controller.currentQuestion.scores[selectedOption!]!;

      // VIGTIG: Opdater currentQuestion her:
      currentQuestion = controller.currentQuestionIndex + 1;

      saveAnswer(selectedOption!, score);

      if (controller.isLastQuestion) {
        Navigator.pushNamed(context, '/doneSetup');
      } else {
        controller.nextQuestion();
        setState(() => selectedOption = null);
      }
    } else {
      showError(context, "Vælg venligst en mulighed først");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuestionController>(
      builder: (context, controller, child) {
        if (controller.questions.isEmpty) {
          return Scaffold(
            backgroundColor: generalBackground,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final question = controller.currentQuestion;

        return Scaffold(
          backgroundColor: generalBackground,
          appBar: CustomerAppBar(
            showBackButton: true,
            title:
            'Spørgsmål ${controller.currentQuestionIndex + 1}/${controller.questions.length}',
          ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        question.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 22.h),
                      ...question.options.map((option) => Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: OcutuneSelectableTile(
                          text: option,
                          selected: selectedOption == option,
                          onTap: () =>
                              setState(() => selectedOption = option),
                        ),
                      )),
                      SizedBox(height: 100.h),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 24.h,
                  right: 24.w,
                  child: OcutuneButton(
                    type: OcutuneButtonType.floatingIcon,
                    onPressed: () => _goToNextScreen(controller),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
