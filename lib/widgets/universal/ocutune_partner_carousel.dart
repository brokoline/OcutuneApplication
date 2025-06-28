// lib/widgets/universal/simple_logo_carousel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SimpleLogoCarousel extends StatefulWidget {
  final List<String> logos;
  const SimpleLogoCarousel({super.key, required this.logos});

  @override
  State<SimpleLogoCarousel> createState() => _SimpleLogoCarouselState();
}

class _SimpleLogoCarouselState extends State<SimpleLogoCarousel> {
  late final PageController _controller;
  late final Timer _timer;
  int _current = 0;

  final Set<String> _filterFiles = {
    'partner_belid_lighting_group.png',
    'partner_good_light_group.png',
  };

  final Map<String, double> _sizeOverrides = {
    'partner_dtu.png': 0.4,
  };

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 1.0);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients) return;
      final next = (_current + 1) % widget.logos.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.logos.length,
      onPageChanged: (i) => setState(() => _current = i),
      itemBuilder: (_, i) {
        final path = widget.logos[i];
        final filename = path.split('/').last;
        final baseWidth = 0.8.sw;
        final multiplier = _sizeOverrides[filename] ?? 1.0;
        final width = baseWidth * multiplier;

        Widget img = Image.asset(
          path,
          width: width,
          fit: BoxFit.contain,
        );

        if (_filterFiles.contains(filename)) {
          return Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.white70,
                BlendMode.srcIn,
              ),
              child: img,
            ),
          );
        }

        // Ellers returnér originalt
        return Center(child: img);
      },
    );
  }
}
