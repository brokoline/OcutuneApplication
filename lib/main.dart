import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ocutune_light_logger/screens/login_screen.dart';
import 'package:ocutune_light_logger/screens/choose_access_screen.dart';

import 'package:ocutune_light_logger/screens/customer/register/register_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/terms_and_policy/privacypolicy_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/terms_and_policy/termsconditions_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/gender_age_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/choose_chronotype_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/learn_about_chronotypes/learn_about_chronotypes_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/learn_about_chronotypes/about_chronotypes_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/question_1_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/question_2_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/question_3_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/question_4_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/question_5_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/done_setup_screen.dart';



import 'package:ocutune_light_logger/theme/colors.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF2D2D2D),
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const OcutuneApp());
}

class OcutuneApp extends StatelessWidget {
  const OcutuneApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ocutune',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: darkGray,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => LoginScreen(),
        '/chooseAccess': (_) => ChooseAccessScreen(),
        '/register': (_) => const RegisterScreen(),
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/terms': (_) => const TermsConditionsScreen(),
        '/genderage': (_) => const GenderAgeScreen(),
        '/chooseChronotype': (_) => const ChooseChronotypeScreen(),
        '/learn': (_) => const LearnAboutChronotypesScreen(),
        '/aboutChronotype': (context) {
          final typeKey = ModalRoute.of(context)!.settings.arguments as String;
          return AboutChronotypeScreen(chronotypeId: typeKey);
        },
        '/Q1': (_) => const QuestionOneScreen(),
        '/Q2': (_) => const QuestionTwoScreen(),
        '/Q3': (_) => const QuestionThreeScreen(),
        '/Q4': (_) => const QuestionFourScreen(),
        '/Q5': (_) => const QuestionFiveScreen(),
        '/doneSetup': (_) => const DoneSetupScreen(),
      },
    );
  }
}
