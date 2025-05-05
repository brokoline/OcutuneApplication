import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← nødvendigt for SystemChrome
import 'package:ocutune_light_logger/screens/customer_register/choose_chronotype_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/learn_about_chronotypes/about_dove_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/learn_about_chronotypes/about_lark_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/learn_about_chronotypes/about_night_owl_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/learn_about_chronotypes/learn_about_chronotypes_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/profile_setup_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/register_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/done_setup_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/survey/morning_evening_type_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/survey/peak_time_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/survey/time_of_tiredness_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/survey/tiredness_slider_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/survey/wake_up_time_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/terms_and_policy/privacypolicy_screen.dart';
import 'package:ocutune_light_logger/screens/customer_register/terms_and_policy/termsconditions_screen.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'screens/login_screen.dart';

void main() {
  // Sikrer korrekt farve og ikonkontrast i statusbaren (top bar)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF2D2D2D), // matcher din baggrund
    statusBarIconBrightness: Brightness.light, // hvide ikoner
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
        '/profile': (context) => const ProfileSetupScreen(),
        '/chooseChronotype': (context) => const ChooseChronotypeScreen(),
        '/learn': (context) => const LearnAboutChronotypesScreen(),
        '/learnLark': (context) => const AboutLarkScreen(),
        '/learnDove': (context) => const AboutDoveScreen(),
        '/learnNightOwl': (context) => const AboutNightOwlScreen(),
        '/wakeUpTime': (context) => const WakeUpTimeScreen(),
        '/tirednessSlider': (context) => const TirednessSliderScreen(),
        '/peakTime': (context) => const PeakTimeScreen(),
        '/timeOfTiredness': (context) => const TimeOfTirednessScreen(),
        '/morningEveningType': (context) => const MorningEveningTypeScreen(),
        '/doneSetup': (context) => const DoneSetupScreen(),
      },
    );
  }
}
