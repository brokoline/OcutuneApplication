import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/offline_sync_manager.dart';
import 'package:ocutune_light_logger/services/network_listener_service.dart';

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

import 'package:ocutune_light_logger/screens/patient/patient_dashboard_screen.dart';
import 'package:ocutune_light_logger/screens/patient/sensor_settings/patient_sensor_settings_screen.dart';
import 'package:ocutune_light_logger/screens/patient/messages/patient_inbox_screen.dart';
import 'package:ocutune_light_logger/screens/patient/messages/patient_message_detail_screen.dart';
import 'package:ocutune_light_logger/screens/patient/messages/patient_new_message_screen.dart';
import 'package:ocutune_light_logger/screens/patient/activities/patient_activity_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF2D2D2D),
    statusBarIconBrightness: Brightness.light,
  ));

  try {
    print('🔧 Initialiserer lokal SQLite...');
    await OfflineStorageService.init();
    print('✅ Lokal storage klar');

    print('🔁 Synkroniserer usendte data...');
    await OfflineSyncManager.syncAll();
    print('✅ Synk-forsøg færdig');

    print('📶 Starter netværksovervågning...');
    NetworkListenerService.start();
    print('✅ Klar til at starte appen!');
  } catch (e) {
    print('❌ FEJL under opstart: $e');
  }

  runApp(
    ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => const OcutuneApp(),
    ),
  );
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

        // Kunde-registrering
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

        // Dashboards
        '/patient/dashboard': (_) => const PatientDashboardScreen(),
        '/clinician/dashboard': (_) => const ClinicianDashboardScreen(),

        // Patient-funktioner
        '/patient_sensor_settings': (_) => const PatientSensorSettingsScreen(),
        '/patient/inbox': (_) => const PatientInboxScreen(),
        '/patient/message_detail': (_) => const PatientMessageDetailScreen(),
        '/patient/new_message': (_) => const PatientNewMessageScreen(),
        '/patient/activities': (_) => PatientActivityScreen(),
      },
    );
  }
}
