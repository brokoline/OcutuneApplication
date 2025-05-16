import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ocutune_light_logger/screens/login_screen.dart';
import 'package:ocutune_light_logger/screens/choose_access_screen.dart';

import 'package:ocutune_light_logger/screens/customer/register/customer_register_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/terms_and_policy/customer_privacypolicy_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/terms_and_policy/customer_termsconditions_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/customer_gender_age_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/customer_choose_chronotype_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/learn_about_chronotypes/customer_learn_about_chronotypes_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/learn_about_chronotypes/customer_about_chronotypes_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/customer_question_1_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/customer_question_2_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/customer_question_3_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/customer_question_4_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/customer_question_5_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/survey/customer_done_setup_screen.dart';

import 'package:ocutune_light_logger/screens/clinician/dashboard/clinician_dashboard_screen.dart.dart';
import 'package:ocutune_light_logger/screens/patient/messages/patient_new_message_screen.dart';

import 'package:ocutune_light_logger/screens/patient/patient_dashboard_screen.dart';
import 'package:ocutune_light_logger/screens/patient/sensor_settings/patient_sensor_settings_screen.dart';
import 'package:ocutune_light_logger/screens/patient/messages/patient_inbox_screen.dart';
import 'package:ocutune_light_logger/screens/patient/messages/patient_message_detail_screen.dart';
import 'package:ocutune_light_logger/screens/patient/activities/patient_activity_screen.dart';

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

        // den almene kunde registrerings-skærme
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

        // Patient og kliniker login
        '/patient/dashboard': (context) => const PatientDashboardScreen(),
        '/clinician/dashboard': (context) => const ClinicianDashboardScreen(),

        // Patient sider
        '/patient_sensor_settings': (context) => const PatientSensorSettingsScreen(),
        '/patient/inbox': (context) => const PatientInboxScreen(),
        '/patient/message_detail': (context) => const PatientMessageDetailScreen(),
        '/patient/new_message': (context) => const PatientNewMessageScreen(),
        '/patient/activities': (context) =>  PatientActivityScreen(),
      },
    );
  }
}
