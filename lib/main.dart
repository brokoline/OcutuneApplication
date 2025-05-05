import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← nødvendigt for SystemChrome
import 'package:ocutune_light_logger/screens/customer_register/choose_chronotype_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/learn_about_chronotypes/about_dove_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/learn_about_chronotypes/about_lark_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/learn_about_chronotypes/about_night_owl_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/learn_about_chronotypes/learn_about_chronotypes_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/gender_age_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/register_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/done_setup_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/survey/morning_evening_type_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/survey/peak_time_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/survey/time_of_tiredness_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/survey/question_two_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/survey/question_one_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/terms_and_policy/privacypolicy_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/terms_and_policy/termsconditions_screen.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'screens/login_screen.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF2D2D2D),
    statusBarIconBrightness: Brightness.light,
  ));

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

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
        '/login': (context) => LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/terms': (context) => const TermsConditionsScreen(),
        '/genderage': (context) => const GenderAgeScreen(),
        '/chooseChronotype': (context) => const ChooseChronotypeScreen(),
        '/learn': (context) => const LearnAboutChronotypesScreen(),
        '/learnLark': (context) => const AboutLarkScreen(),
        '/learnDove': (context) => const AboutDoveScreen(),
        '/learnNightOwl': (context) => const AboutNightOwlScreen(),
        '/Q1': (context) => const QuestionOneScreen(),
        '/Q2': (context) => const QuestionTwoScreen(),
        '/peakTime': (context) => const PeakTimeScreen(),
        '/timeOfTiredness': (context) => const TimeOfTirednessScreen(),
        '/morningEveningType': (context) => const MorningEveningTypeScreen(),
        '/doneSetup': (context) => const DoneSetupScreen(),
      },
    );
  }
}
