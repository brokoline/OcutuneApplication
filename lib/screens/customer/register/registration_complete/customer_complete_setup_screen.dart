// lib/screens/customer/register/registration_complete/customer_complete_setup_screen.dart

import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ocutune_light_logger/theme/colors.dart';
import '../../../../services/services/customer_data_service.dart';

class DoneSetupScreen extends StatefulWidget {
  const DoneSetupScreen({Key? key}) : super(key: key);

  @override
  State<DoneSetupScreen> createState() => _DoneSetupScreenState();
}

class _DoneSetupScreenState extends State<DoneSetupScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _orbitController;
  late final Animation<double> _scaleAnim;

  String chronotype = "";
  String chronotypeText = "";
  String chronotypeImageUrl = "";

  @override
  void initState() {
    super.initState();
    debugPrint("🔄 initState() - starter animationer og fetch");

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _prepareAndSubmit();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  Future<void> _prepareAndSubmit() async {
    debugPrint("🚀 _prepareAndSubmit() kaldt");
    final scores = currentCustomerResponse?.questionScores ?? <String, int>{};
    if (scores.isNotEmpty) {
      final total = scores.values.fold(0, (sum, v) => sum + v);
      debugPrint("📊 Lokalt beregnet score: $total");
      await fetchChronotypeFromServer(total);
    } else {
      final answers = currentCustomerResponse?.answers ?? <String>[];
      if (answers.isNotEmpty) {
        final title = answers.last;
        debugPrint("📥 Sidste svar-tekst (titel): $title");
        await fetchChronotypeByTitle(title);
      } else {
        debugPrint("⚠️ Ingen scores eller answers fundet i currentCustomerResponse");
      }
    }
    await submitCustomerResponse();
  }

  Future<void> fetchChronotypeFromServer(int score) async {
    final url = Uri.parse('https://ocutune2025.ddns.net/chronotypes/by-score/$score');
    debugPrint("🌐 Henter chronotype med score: $score → $url");
    try {
      final response = await http.get(url);
      debugPrint("📥 Response: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Opdater global respons immutabelt
        final resp = currentCustomerResponse;
        if (resp != null) {
          currentCustomerResponse = resp.copyWith(
            chronotypeKey: data['type_key'] as String?,
          );
        }

        setState(() {
          chronotype        = data['title']        as String? ?? 'Ukendt kronotype';
          chronotypeText    = data['summary_text'] as String? ?? 'Beskrivelse mangler';
          chronotypeImageUrl = data['image_url']   as String? ?? '';
        });
      } else {
        setState(() {
          chronotype     = 'Ukendt';
          chronotypeText = 'Kunne ikke hente kronotype';
        });
      }
    } catch (e) {
      debugPrint("❌ Fejl under fetchChronotypeFromServer: $e");
      setState(() {
        chronotype     = 'Fejl';
        chronotypeText = 'Noget gik galt: $e';
      });
    }
  }

  Future<void> fetchChronotypeByTitle(String title) async {
    final url = Uri.parse('https://ocutune2025.ddns.net/chronotypes');
    debugPrint("🌐 Henter chronotype via titel: $title → $url");
    try {
      final response = await http.get(url);
      debugPrint("📥 Response: ${response.statusCode} ${response.body}");
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        final match = data.firstWhere(
              (c) => c['title'] == title,
          orElse: () => null,
        );
        if (match != null) {
          final resp = currentCustomerResponse;
          if (resp != null) {
            currentCustomerResponse = resp.copyWith(
              chronotypeKey: match['type_key'] as String?,
            );
          }
          setState(() {
            chronotype        = match['title']        as String? ?? title;
            chronotypeText    = match['summary_text'] as String? ?? 'Beskrivelse mangler';
            chronotypeImageUrl = match['image_url']   as String? ?? '';
          });
        } else {
          setState(() {
            chronotype     = title;
            chronotypeText = 'Ingen beskrivelse fundet';
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Fejl under fetchChronotypeByTitle: $e");
      setState(() {
        chronotype     = title;
        chronotypeText = 'Kunne ikke hente data';
      });
    }
  }

  void _goToHome(BuildContext context) {
    debugPrint("➡️ Går til /home");
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Widget _orbitingStar({
    required double angleOffset,
    required double radius,
    required double minSize,
    required double maxSize,
    required double opacity,
  }) {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (_, __) {
        final angleDeg = (_orbitController.value * 360 + angleOffset) % 360;
        final angle    = angleDeg * (pi / 180);
        final dx       = radius * cos(angle);
        final dy       = radius * sin(angle);
        final size     = minSize + (maxSize - minSize) * (1 - sin(angle).clamp(-1.0, 1.0));
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Opacity(
            opacity: opacity,
            child: Icon(Icons.star, size: size, color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: generalBackground,
      appBar: AppBar(
        backgroundColor: generalBackground,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _scaleAnim,
                        builder: (context, child) => Transform.scale(
                          scale: _scaleAnim.value,
                          child: child,
                        ),
                        child: chronotypeImageUrl.isNotEmpty
                            ? Image.network(
                          chronotypeImageUrl,
                          width: 100,
                          height: 100,
                          errorBuilder: (c, e, st) =>
                          const Icon(Icons.broken_image, size: 80, color: Colors.white),
                        )
                            : const Icon(Icons.image, size: 80, color: Colors.white),
                      ),
                      _orbitingStar(angleOffset: 0, radius: 60, minSize: 8, maxSize: 16, opacity: 0.8),
                      _orbitingStar(angleOffset: 120, radius: 75, minSize: 6, maxSize: 14, opacity: 0.6),
                      _orbitingStar(angleOffset: 240, radius: 65, minSize: 6, maxSize: 12, opacity: 0.5),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  chronotype,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  chronotypeText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Du er nu klar til at starte din lyslogning!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _goToHome(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Kom i gang",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
