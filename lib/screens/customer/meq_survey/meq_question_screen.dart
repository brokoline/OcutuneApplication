// lib/screens/customer/meq_survey/customer_meq_questions_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_selectable_tile.dart';
import 'package:ocutune_light_logger/widgets/universal/ocutune_next_step_button.dart';
import '../../../services/auth_storage.dart';
import 'meq_question_controller.dart';

class CustomerMeqQuestionsScreen extends StatefulWidget {
  const CustomerMeqQuestionsScreen({super.key});

  @override
  State<CustomerMeqQuestionsScreen> createState() =>
      _CustomerMeqQuestionsScreenState();
}

class _CustomerMeqQuestionsScreenState
    extends State<CustomerMeqQuestionsScreen> {
  int? _selectedChoiceId;

  @override
  void initState() {
    super.initState();
    final ctrl = context.read<MeqQuestionController>();
    ctrl.reset();          // **Ryd alle gamle spørgsmål og svar**
    ctrl.fetchQuestions(); // Hent dem fra serveren igen
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12.w),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  void _onBack(MeqQuestionController ctrl) {
    if (ctrl.currentQuestionIndex > 0) {
      ctrl.previousQuestion();
      setState(() => _selectedChoiceId = null);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onNext(MeqQuestionController ctrl) async {
    if (_selectedChoiceId == null) {
      _showError("Vælg venligst en mulighed først");
      return;
    }

    final qid = ctrl.currentQuestion.id;
    ctrl.recordAnswer(qid, _selectedChoiceId!);

    if (ctrl.isLastQuestion) {
      final cid = await AuthStorage.getCustomerId();
      if (cid == null) {
        _showError("Kunne ikke finde customerId i lokal storage");
        return;
      }
      try {
        await ctrl.submitAnswers(cid.toString());
        Navigator.of(context).pushReplacementNamed('/meqResult');
      } catch (e) {
        _showError("Kunne ikke gemme svar: $e");
      }
    } else {
      ctrl.nextQuestion();
      setState(() => _selectedChoiceId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeqQuestionController>(
      builder: (context, ctrl, _) {
        if (ctrl.questions.isEmpty) {
          return Scaffold(
            backgroundColor: generalBackground,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final idx   = ctrl.currentQuestionIndex + 1;
        final total = ctrl.questions.length;
        final q     = ctrl.currentQuestion;
        _selectedChoiceId ??= ctrl.getSavedChoice(q.id);

        return WillPopScope(
          onWillPop: () async {
            _onBack(ctrl);
            return false;
          },
          child: Scaffold(
            backgroundColor: generalBackground,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(100.h),
              child: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: generalBackground,
                elevation: 0,
                centerTitle: true,
                toolbarHeight: 100.h,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white70),
                  onPressed: () => _onBack(ctrl),
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo/logo_ocutune.png',
                      height: 35.h,
                      color: Colors.white70,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Spørgsmål $idx/$total',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
                          q.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 22.h),
                        ...q.choices.map((c) => Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: OcutuneSelectableTile(
                            text: c.text,
                            selected: _selectedChoiceId == c.id,
                            onTap: () => setState(() => _selectedChoiceId = c.id),
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
                      onPressed: () => _onNext(ctrl),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
