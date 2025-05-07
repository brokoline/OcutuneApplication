import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/theme/colors.dart';
import '/models/user_data_service.dart';
import '/models/user_response.dart';

class DoneSetupScreen extends StatefulWidget {
  const DoneSetupScreen({super.key});

  @override
  State<DoneSetupScreen> createState() => _DoneSetupScreenState();
}

class _DoneSetupScreenState extends State<DoneSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _orbitController;
  late Animation<double> _scaleAnim;

  String chronotype = "";
  String chronotypeText = "";
  String chronotypeImageUrl = "";

  @override
  void initState() {
    super.initState();

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

  Future<void> _prepareAndSubmit() async {
    if ((currentUserResponse?.scores ?? []).isNotEmpty) {
      final total = currentUserResponse!.scores.fold(0, (a, b) => a + b);
      await fetchChronotypeFromServer(total);
    } else if ((currentUserResponse?.answers ?? []).isNotEmpty) {
      final title = currentUserResponse!.answers.last;
      await fetchChronotypeByTitle(title);
    }

    await submitUserResponse();
  }

  Future<void> fetchChronotypeFromServer(int score) async {
    final url = Uri.parse('https://ocutune.ddns.net/chronotypes/by-score/$score');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        currentUserResponse?.chronotypeKey = data['type_key'];

        setState(() {
          chronotype = data['title'] ?? 'Ukendt kronotype';
          chronotypeText = data['summary_text'] ?? 'Beskrivelse mangler';
          chronotypeImageUrl = data['image_url'] ?? '';
        });
      } else {
        setState(() {
          chronotype = 'Ukendt';
          chronotypeText = 'Kunne ikke hente kronotype';
        });
      }
    } catch (e) {
      setState(() {
        chronotype = 'Fejl';
        chronotypeText = 'Noget gik galt: $e';
      });
    }
  }

  Future<void> fetchChronotypeByTitle(String title) async {
    final url = Uri.parse('https://ocutune.ddns.net/chronotypes');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final match = data.firstWhere((c) => c['title'] == title, orElse: () => null);

        if (match != null) {
          currentUserResponse?.chronotypeKey = match['type_key']; // 🟢 nu korrekt
          setState(() {
            chronotype = match['title'] ?? title;
            chronotypeText = match['summary_text'] ?? 'Beskrivelse mangler';
            chronotypeImageUrl = match['image_url'] ?? '';
          });
        } else {
          setState(() {
            chronotype = title;
            chronotypeText = 'Beskrivelse ikke fundet';
          });
        }
      }
    } catch (_) {
      setState(() {
        chronotype = title;
        chronotypeText = 'Kunne ikke hente data';
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  void _goToHome(BuildContext context) {
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
        final angle = angleDeg * (pi / 180);
        final dx = radius * cos(angle);
        final dy = radius * sin(angle);
        final size = minSize +
            (maxSize - minSize) * (1 - sin(angle).clamp(-1.0, 1.0));

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
      backgroundColor: lightGray,
      appBar: AppBar(
        backgroundColor: lightGray,
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
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnim.value,
                            child: child,
                          );
                        },
                        child: chronotypeImageUrl.isNotEmpty
                            ? Image.network(
                          chronotypeImageUrl,
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) =>
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
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
