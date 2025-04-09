import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← nødvendigt for SystemChrome
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
        scaffoldBackgroundColor: const Color(0xFF2D2D2D),
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
