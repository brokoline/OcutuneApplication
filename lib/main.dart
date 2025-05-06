import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ocutune_light_logger/screens/login_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/register_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/terms_and_policy/privacypolicy_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/terms_and_policy/termsconditions_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/gender_age_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/choose_chronotype_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/learn_about_chronotypes/learn_about_chronotypes_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/learn_about_chronotypes/about_chronotypes_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/question_one_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/question_two_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/peak_time_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/time_of_tiredness_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/morning_evening_type_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/done_setup_screen.dart';

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
        '/peakTime': (_) => const PeakTimeScreen(),
        '/timeOfTiredness': (_) => const TimeOfTirednessScreen(),
        '/morningEveningType': (_) => const MorningEveningTypeScreen(),
        '/doneSetup': (_) => const DoneSetupScreen(),
      },
    );
  }
}
