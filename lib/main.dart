// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ocutune_light_logger/screens/customer/dashboard/activity/customer_activity_controller.dart';
import 'package:ocutune_light_logger/screens/customer/dashboard/activity/customer_activity_screen.dart';
import 'package:ocutune_light_logger/screens/customer/meq_survey/meq_question_controller.dart';
import 'package:ocutune_light_logger/screens/customer/meq_survey/meq_question_screen.dart';
import 'package:ocutune_light_logger/screens/customer/meq_survey/meq_result_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/chronotype_survey/customer_rmeq_questions_screen.dart';
import 'package:ocutune_light_logger/screens/customer/register/chronotype_survey/question_controller.dart';
import 'package:ocutune_light_logger/screens/login/choose_access/choose_access_controller.dart';
import 'package:ocutune_light_logger/screens/login/choose_access/choose_access_screen.dart';
import 'package:ocutune_light_logger/screens/login/login_controller.dart';
import 'package:ocutune_light_logger/screens/login/simuleret_mitID_login/simulated_mitid_login_controller.dart';
import 'package:ocutune_light_logger/screens/patient/activities/patient_activity_controller.dart';
import 'package:provider/provider.dart';

import 'package:ocutune_light_logger/services/services/app_initializer.dart';

// Imports for screens, controllers mm
import 'screens/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/simuleret_mitID_login/simulated_mitid_login_screen.dart';

import 'package:ocutune_light_logger/screens/customer/customer_root_controller.dart';
import 'package:ocutune_light_logger/screens/customer/dashboard/customer_root_screen.dart';
import 'screens/customer/register/customer_registration_information/customer_register_screen.dart';
import 'screens/customer/register/terms_and_policy/customer_privacypolicy_screen.dart';
import 'screens/customer/register/terms_and_policy/customer_termsconditions_screen.dart';
import 'screens/customer/register/gender_age/customer_gender_age_screen.dart';
import 'screens/customer/register/chronotype_setup/customer_choose_chronotype_screen.dart';
import 'screens/customer/register/learn_about_chronotypes/customer_learn_about_chronotypes_screen.dart';
import 'screens/customer/register/learn_about_chronotypes/customer_details_about_chronotypes_screen.dart';
import 'screens/customer/register/registration_complete/customer_complete_setup_screen.dart';

import 'screens/patient/patient_dashboard_screen.dart';
import 'screens/patient/activities/patient_activity_screen.dart';
import 'screens/patient/sensor_settings/patient_sensor_screen.dart';
import 'widgets/messages/inbox_screen.dart';
import 'widgets/messages/message_thread_screen.dart';
import 'widgets/messages/new_message_screen.dart';

import 'screens/clinician/root/clinician_root_screen.dart';
import 'controller/inbox_controller.dart';
import 'screens/clinician/root/clinician_root_controller.dart';

import 'theme/colors.dart';

import 'services/processing/data_processing_manager.dart';
import 'viewmodel/clinician/patient_detail_viewmodel.dart';


@pragma('vm:entry-point')
void startCallback() {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInitializer.initialize();
  runApp(const OcutuneApp());
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
          ChangeNotifierProvider(create: (_) => LoginController()),
          ChangeNotifierProvider(create: (_) => ChooseAccessController()),
          ChangeNotifierProvider(create: (_) => ClinicianDashboardController()),
          ChangeNotifierProvider(create: (_) => SimulatedLoginController()),
          ChangeNotifierProvider<DataProcessingManager>(
            create: (_) => DataProcessingManager(),
          ),
          ChangeNotifierProvider<PatientDetailViewModel>(
            create: (_) => PatientDetailViewModel(''),
          ),
          ChangeNotifierProvider(create: (_) => QuestionController()),
          ChangeNotifierProvider(create: (_) => MeqQuestionController()),
          // Du kan tilføje CustomerRootController her, hvis du vil
          ChangeNotifierProvider(create: (_) => CustomerActivityController()),
          // ChangeNotifierProvider(create: (_) => CustomerRootController()),
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
            '/genderage': (_) => const CustomerGenderAgeScreen(),
            '/chooseChronotype': (_) => const CustomerChooseChronotypeScreen(),
            '/learn': (_) => const LearnAboutChronotypesScreen(),
            '/aboutChronotype': (context) {
              final typeKey = ModalRoute.of(context)!.settings.arguments as String;
              return AboutChronotypeScreen(chronotypeId: typeKey);
            },
            '/questions': (_) => const QuestionScreen(),
            '/meq_survey': (_) => const CustomerMeqQuestionsScreen(),
            '/meqResult': (ctx) =>  MeqResultScreen(),
            '/doneSetup': (_) => const DoneSetupScreen(),
            '/patient/dashboard': (context) {
              final patientId = ModalRoute.of(context)!.settings.arguments as String;
              return ChangeNotifierProvider<PatientDetailViewModel>(
                create: (_) => PatientDetailViewModel(patientId),
                child: PatientDashboardScreen(patientId: patientId),
              );
            },
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
            '/patient_sensor_settings': (context) {
              final patientId = ModalRoute.of(context)!.settings.arguments as String;
              return PatientSensorSettingsScreen(patientId: patientId);
            },
            '/patient/activities': (context) => ChangeNotifierProvider<PatientActivityController>(
              create: (_) => PatientActivityController()..init(),
              child: const PatientActivityScreen(),
            ),
            '/clinician/inbox': (_) => ChangeNotifierProvider(
              create: (_) => InboxController(inboxType: InboxType.clinician),
              child: const InboxScreen(
                inboxType: InboxType.clinician,
                useClinicianAppBar: true,
                showNewMessageButton: true,
              ),
            ),
            '/clinician/message_detail': (context) {
              final threadId = ModalRoute.of(context)!.settings.arguments as String;
              return MessageThreadScreen(threadId: threadId);
            },
            '/clinician/new_message': (_) => const NewMessageScreen(),
            '/clinician': (_) => ClinicianRootScreen(),
            '/customerDashboard': (_) => ChangeNotifierProvider<CustomerRootController>(
              create: (_) => CustomerRootController(),
              child: const CustomerRootScreen(),
            ),
            '/customer/activities': (context) => const CustomerActivityScreen(),
          },
        ),
      ),
    );
  }
}
