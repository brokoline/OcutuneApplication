import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/state/customer_setup_state.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/customer_done_setup_screen.dart';

import '../../../../services/services/api_services.dart';
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
      debugPrint("❌ Ugyldigt valg-ID: '${selected.id}' – kan ikke gå videre");
      return;
    }

    final answer = AnswerModel(
      customerId: null,
      questionId: questionId,
      choiceId: choiceId,
      answerText: selected.text,
      questionTextSnap: q.question,
      createdAt: DateTime.now(),
    );

    CustomerSetupState.instance.setAnswer(
      viewModel.currentIndex.toString(),
      answer,
    );

    final success = await viewModel.nextQuestion();
    if (!mounted) return;

    if (!success) {
      try {
        final setup = CustomerSetupState.instance;

        // 🧾 Debug inputdata
        debugPrint("🧾 REGISTRERINGSTJEK:");
        debugPrint("  Email: ${setup.email}");
        debugPrint("  Password: ${setup.password}");
        debugPrint("  First name: ${setup.firstName}");
        debugPrint("  Last name: ${setup.lastName}");
        debugPrint("  Gender: ${setup.gender}");
        debugPrint("  Age: ${setup.age}");
        debugPrint("📦 Antal svar: ${setup.answers.length}");

        // 🔒 Valider registrering
        if (!setup.hasValidRegistrationData) {
          debugPrint("🚫 Manglende registreringsdata");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Udfyld alle oplysninger før registrering")),
          );
          return;
        }

        // 🔐 1. Registrer bruger
        final result = await ApiService.registerCustomer(
          email: setup.email!,
          password: setup.password!,
          firstName: setup.firstName!,
          lastName: setup.lastName!,
          gender: setup.gender!,
          birthYear: setup.age!,
          chronotypeKey: setup.chronotype,
        );

        debugPrint("📥 Register response: $result");

        if (!result.containsKey('id') || result['id'] == null) {
          throw Exception("❌ Manglende customerId i register-svar: $result");
        }

        final customerId = result['id'];
        final token = result['token'];

        setup.setCustomerId(customerId);
        if (token != null) {
          setup.token = token;
          debugPrint("🔐 Token gemt i setup: $token");
        }

        // 🔗 2. Knyt ID til svar
        setup.attachCustomerIdToAnswers(customerId);

        debugPrint("🚀 flushAnswersToBackend() KØRER");

        // 📤 3. Send svar
        final headers = {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        };

        for (final answer in setup.answers.values) {
          try {
            final payload = jsonEncode(answer.toJson());
            debugPrint("📤 [ANS] Payload: $payload");

            final response = await http.post(
              Uri.parse('https://ocutune2025.ddns.net/submit_answer'),
              headers: headers,
              body: payload,
            );

            debugPrint("📥 [ANS] Response: ${response.statusCode} → ${response.body}");

            if (response.statusCode != 200) {
              throw Exception('❌ Fejl ved svar: ${response.body}');
            }
          } catch (e) {
            debugPrint("❌ [ANS] Fejl: $e");
          }
        }

        // 🔢 4. Beregn score
        try {
          final scoreResponse = await http.post(
            Uri.parse('https://ocutune2025.ddns.net/calculate-score/$customerId'),
            headers: headers,
          );

          debugPrint("📥 [SCORE] Status: ${scoreResponse.statusCode}");
          debugPrint("📥 [SCORE] Body: ${scoreResponse.body}");

          if (scoreResponse.statusCode != 200) {
            throw Exception('❌ Fejl ved scoreberegning: ${scoreResponse.body}');
          }

          final scoreData = jsonDecode(scoreResponse.body);
          final totalScore = scoreData['total_score'];
          setup.totalScore = totalScore;

          debugPrint("🎯 Score beregnet: $totalScore");

          // 🧠 5. PATCH score og chronotype
          final patchResponse = await http.patch(
            Uri.parse('https://ocutune2025.ddns.net/customers/$customerId'),
            headers: headers,
            body: jsonEncode({
              'total_score': totalScore,
              if (setup.chronotype != null) 'chronotype_key': setup.chronotype,
            }),
          );

          debugPrint("📥 [PATCH] Status: ${patchResponse.statusCode}");
          debugPrint("📥 [PATCH] Body: ${patchResponse.body}");

          if (patchResponse.statusCode != 200) {
            throw Exception("❌ PATCH fejl: ${patchResponse.body}");
          }

          debugPrint("✅ Kunde opdateret med score + chronotype");
        } catch (e) {
          debugPrint("⚠️ Fejl under scoreberegning eller PATCH: $e");
        }

        // 🔄 6. Hent chronotype baseret på beregnet score
        final chronotypeData = await ApiService.fetchChronotypeByScoreFromBackend(customerId);

        setup.setChronotype(chronotypeData['type_key'] ?? 'ukendt');
        setup.setChronotypeText(chronotypeData['summary_text'] ?? 'Beskrivelse mangler');
        setup.setChronotypeImageUrl(chronotypeData['image_url'] ?? '');

        debugPrint("🧠 Chronotype sat: ${setup.chronotype}");

        // ✅ 7. Done-setup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerDoneSetupScreen()),
        );
      } catch (e, stack) {
        debugPrint("❌ Fejl under registrering/dataafsendelse: $e");
        debugPrint("📍 Stacktrace: $stack");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl: $e')),
        );
      }
    }
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
                "Spørgsmål ${viewModel.currentIndex + 1}/${viewModel.totalQuestionCount}",
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Builder(
                builder: (context) {
                  debugPrint('🧠 Spørgsmål: ${question.question}');
                  debugPrint('📋 Valgmuligheder: ${question.answers.map((a) => a.text).toList()}');
                  debugPrint('✅ Valgt: ${selectedAnswer?.text}');
                  debugPrint('📐 Layouttype: $layoutType');

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
}
