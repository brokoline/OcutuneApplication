import 'dart:math';
import 'package:flutter/material.dart';
import '/theme/colors.dart';

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

        // Størrelsen afhænger af vertikal position (illusion af dybde)
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
                // ✨ Stjerner og effekter
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 🌟 Pulserende hovedstjerne
                      AnimatedBuilder(
                        animation: _scaleAnim,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnim.value,
                            child: child,
                          );
                        },
                        child: const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                      // ✨ Kredsstjerner med rotation og skalering
                      _orbitingStar(
                          angleOffset: 0,
                          radius: 60,
                          minSize: 8,
                          maxSize: 16,
                          opacity: 0.8),
                      _orbitingStar(
                          angleOffset: 120,
                          radius: 75,
                          minSize: 6,
                          maxSize: 14,
                          opacity: 0.6),
                      _orbitingStar(
                          angleOffset: 240,
                          radius: 65,
                          minSize: 6,
                          maxSize: 12,
                          opacity: 0.5),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Du er klar!",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Velkommen til din rejse mod bedre søvn og rytme.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
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
