import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// 🧩 Skærme
import 'screens/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/choose_access_screen.dart';
import 'screens/simuleret_mitID_login/simulated_mitid_login_screen.dart';
import 'screens/customer/register/customer_registration_information/customer_register_screen.dart';
import 'screens/customer/register/terms_and_policy/customer_privacypolicy_screen.dart';
import 'screens/customer/register/terms_and_policy/customer_termsconditions_screen.dart';
import 'screens/customer/register/gender_age/customer_gender_age_screen.dart';
import 'screens/customer/register/chronotype_setup/customer_choose_chronotype_screen.dart';
import 'screens/customer/register/learn_about_chronotypes/customer_learn_about_chronotypes_screen.dart';
import 'screens/customer/register/learn_about_chronotypes/customer_details_about_chronotypes_screen.dart';
import 'screens/customer/register/registration_complete/customer_complete_setup_screen.dart';
import 'screens/customer/register/registration_steps/chronotype_survey/customer_question_1_screen.dart';
import 'screens/customer/register/registration_steps/chronotype_survey/customer_question_2_screen.dart';
import 'screens/customer/register/registration_steps/chronotype_survey/customer_question_3_screen.dart';
import 'screens/customer/register/registration_steps/chronotype_survey/customer_question_4_screen.dart';
import 'screens/customer/register/registration_steps/chronotype_survey/customer_question_5_screen.dart';
import 'screens/patient/patient_dashboard_screen.dart';
import 'screens/patient/activities/patient_activity_screen.dart';
import 'screens/patient/sensor_settings/patient_sensor_screen.dart';
import 'screens/clinician/root/clinician_root_screen.dart';
import 'widgets/messages/inbox_screen.dart';
import 'widgets/messages/message_thread_screen.dart';
import 'widgets/messages/new_message_screen.dart';

// 📦 Controllere
import 'controller/inbox_controller.dart';
import 'screens/clinician/root/clinician_root_controller.dart';

// 🎨 Tema
import 'theme/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kReleaseMode) {
    HttpOverrides.global = MyHttpOverrides();
  }

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

class OcutuneApp extends StatelessWidget {
  const OcutuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Tilpas hvis du bruger Figma/iOS mål
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
            '/simulated_login': (_) =>
            const SimulatedLoginScreen(title: 'Simuleret login'),
            '/register': (_) => const RegisterScreen(),
            '/privacy': (_) => const PrivacyPolicyScreen(),
            '/terms': (_) => const TermsConditionsScreen(),
            '/genderage': (_) => const CustomerGenderAgeScreen(),
            '/chooseChronotype': (_) => const CustomerChooseChronotypeScreen(),
            '/learn': (_) => const LearnAboutChronotypesScreen(),
            '/aboutChronotype': (context) {
              final typeKey =
              ModalRoute.of(context)!.settings.arguments as String;
              return AboutChronotypeScreen(chronotypeId: typeKey);
            },
            '/Q1': (_) => const QuestionOneScreen(),
            '/Q2': (_) => const QuestionTwoScreen(),
            '/Q3': (_) => const QuestionThreeScreen(),
            '/Q4': (_) => const QuestionFourScreen(),
            '/Q5': (_) => const QuestionFiveScreen(),
            '/doneSetup': (_) => const DoneSetupScreen(),
            '/patient/dashboard': (context) {
              final patientId =
              ModalRoute.of(context)!.settings.arguments as String;
              return PatientDashboardScreen(patientId: patientId);
            },
            '/clinician/inbox': (_) => ChangeNotifierProvider(
              create: (_) =>
                  InboxController(inboxType: InboxType.clinician),
              child: const InboxScreen(
                inboxType: InboxType.clinician,
                useClinicianAppBar: true,
                showNewMessageButton: true,
              ),
            ),
            '/patient/inbox': (_) => ChangeNotifierProvider(
              create: (_) =>
                  InboxController(inboxType: InboxType.patient),
              child: const InboxScreen(
                inboxType: InboxType.patient,
                useClinicianAppBar: false,
                showNewMessageButton: true,
              ),
            ),
            '/patient/message_detail': (context) {
              final threadId =
              ModalRoute.of(context)!.settings.arguments as String;
              return MessageThreadScreen(threadId: threadId);
            },
            '/patient/new_message': (_) => const NewMessageScreen(),
            '/clinician/message_detail': (context) {
              final threadId =
              ModalRoute.of(context)!.settings.arguments as String;
              return MessageThreadScreen(threadId: threadId);
            },
            '/clinician/new_message': (_) => const NewMessageScreen(),
            '/clinician': (_) => ClinicianRootScreen(),
            '/patient_sensor_settings': (context) {
              final patientId =
              ModalRoute.of(context)!.settings.arguments as String;
              return PatientSensorSettingsScreen(patientId: patientId);
            },
            '/patient/activities': (_) => PatientActivityScreen(),
          },
        ),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final inner = super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) {
        print('⚠️ [CERT] Godkendt manuelt for: $host');
        return true;
      };
    return _LoggingHttpClient(inner);
  }
}

class _LoggingHttpClient implements HttpClient {
  final HttpClient _inner;

  _LoggingHttpClient(this._inner);

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    print('🌐 [GET] $url');
    return _inner.getUrl(url);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    print('📡 [POST] $url');
    return _inner.postUrl(url);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    print('🧩 [OPEN] $method $url');
    return _inner.openUrl(method, url);
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);

  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Function.apply(_inner.noSuchMethod, [invocation]);
}
