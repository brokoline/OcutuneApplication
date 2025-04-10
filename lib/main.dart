import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← nødvendigt for SystemChrome
import 'package:ocutune_light_logger/screens/register/register_screen.dart';
import 'package:ocutune_light_logger/screens/register/terms%20and%20policy/privacypolicy_screen.dart';
import 'package:ocutune_light_logger/screens/register/terms%20and%20policy/termsconditions_screen.dart';
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
      },
    );
  }
}
