import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:ocutune_light_logger/screens/splash_screen.dart';
import 'package:ocutune_light_logger/screens/simuleret_mitID_login/simulated_mitid_login_screen.dart';
import 'package:ocutune_light_logger/screens/login/login_screen.dart';
import 'package:ocutune_light_logger/screens/login/choose_access_screen.dart';
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
import 'package:ocutune_light_logger/screens/patient/patient_dashboard_screen.dart';
import 'package:ocutune_light_logger/screens/clinician/root/clinician_root_screen.dart';
import 'package:ocutune_light_logger/screens/patient/sensor_settings/patient_sensor_screen.dart';
import 'package:ocutune_light_logger/screens/patient/activities/patient_activity_screen.dart';
import 'package:ocutune_light_logger/widgets/messages/inbox_screen.dart';
import 'package:ocutune_light_logger/widgets/messages/message_thread_screen.dart';
import 'package:ocutune_light_logger/widgets/messages/new_message_screen.dart';

import 'package:ocutune_light_logger/controller/inbox_controller.dart';
import 'package:ocutune_light_logger/screens/clinician/root/clinician_root_controller.dart';
import 'package:ocutune_light_logger/theme/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⚠️ Midlertidig bypass af certifikatvalidering (kun til udvikling!)
  HttpOverrides.global = MyHttpOverrides();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF4C4C4C),
    statusBarIconBrightness: Brightness.light,
  ));

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Center(
      child: Text(
        '🚨 FEJL: ${details.exception}',
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  };

  runApp(const OcutuneApp());
}
// 🛠️ Klasse der deaktiverer certifikatvalidering (kun midlertidigt!)
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        print('⚠️ Certifikat for $host blev godkendt manuelt under udvikling.');
        return true;
      };
  }
}

class OcutuneApp extends StatelessWidget {
  const OcutuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ClinicianDashboardController()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ocutune',
          theme: ThemeData(
            scaffoldBackgroundColor: darkGray,
            brightness: Brightness.dark,
            fontFamily: 'Roboto',
          ),
          home: const SplashScreen(),
          routes: {
            '/login': (_) => LoginScreen(),
            '/chooseAccess': (_) => ChooseAccessScreen(),
            '/simulated_login': (_) => const SimulatedLoginScreen(title: 'Simuleret login'),
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
            '/patient/dashboard': (context) {
              final patientId = ModalRoute.of(context)!.settings.arguments as String;
              return PatientDashboardScreen(patientId: patientId);
            },
            '/clinician/inbox': (_) => ChangeNotifierProvider(
              create: (_) => InboxController(inboxType: InboxType.clinician),
              child: const InboxScreen(
                inboxType: InboxType.clinician,
                useClinicianAppBar: true,
                showNewMessageButton: true,
              ),
            ),
            '/patient/inbox': (_) => ChangeNotifierProvider(
              create: (_) => InboxController(inboxType: InboxType.patient),
              child: const InboxScreen(
                inboxType: InboxType.patient,
                useClinicianAppBar: false,
                showNewMessageButton: true,
              ),
            ),
            '/patient/message_detail': (context) {
              final threadId = ModalRoute.of(context)!.settings.arguments as String;
              return MessageThreadScreen(threadId: threadId);
            },
            '/patient/new_message': (_) => const NewMessageScreen(),
            '/clinician/message_detail': (context) {
              final threadId = ModalRoute.of(context)!.settings.arguments as String;
              return MessageThreadScreen(threadId: threadId);
            },
            '/clinician/new_message': (_) => const NewMessageScreen(),
            '/clinician': (_) => ClinicianRootScreen(),
            '/patient_sensor_settings': (context) {
              final patientId = ModalRoute.of(context)!.settings.arguments as String;
              return PatientSensorSettingsScreen(patientId: patientId);
            },
            '/patient/activities': (_) => PatientActivityScreen(),
          },
        ),
      ),
    );
  }
}
