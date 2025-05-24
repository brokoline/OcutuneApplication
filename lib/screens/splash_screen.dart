import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/theme/colors.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:ocutune_light_logger/services/offline_sync_manager.dart';
import 'package:ocutune_light_logger/services/services/network_listener_service.dart';
import 'package:ocutune_light_logger/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(Duration.zero, _initializeApp);
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🔧 Initialiserer lokal SQLite...');
      await OfflineStorageService.init();
      debugPrint('✅ Lokal storage klar');

      debugPrint('🔁 Synkroniserer usendte data...');
      await OfflineSyncManager.syncAll();
      debugPrint('✅ Synk-forsøg færdig');

      debugPrint('📶 Starter netværksovervågning...');
      NetworkListenerService.start();
      debugPrint('✅ Klar til at starte appen!');

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Init-fejl: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                color: Colors.white70,
                'assets/logo/logo_ocutune.png',
                width: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Colors.white70),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
