// lib/widgets/universal/ocutune_partner_carousel.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Auto-scrolling, farvefiltreret carousel med større logoer
class PartnersCarousel extends StatefulWidget {
  final List<String> assetPaths;
  const PartnersCarousel({Key? key, required this.assetPaths}) : super(key: key);

  @override
  State<PartnersCarousel> createState() => _PartnersCarouselState();
}

class _PartnersCarouselState extends State<PartnersCarousel> {
  late final PageController _ctrl;
  late final Timer _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    // viewportFraction < 1.0 viser delvist nabologoer,
    // sæt den til fx 0.8 eller 1.0 for kun ét logo i fuld bredde.
    _ctrl = PageController(viewportFraction: 0.8);

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_ctrl.hasClients) return;
      final next = (_current + 1) % widget.assetPaths.length;
      _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180.h, // højde øget så logoet kan vokse
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.assetPaths.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final isActive = i == _current;
              return AnimatedScale(
                scale: isActive ? 1.0 : 0.8,        // aktivt logo større
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white70,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      widget.assetPaths[i],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.assetPaths.length, (i) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              width: _current == i ? 14.w : 8.w,
              height: _current == i ? 14.w : 8.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _current == i ? Colors.white : Colors.white38,
              ),
            );
          }),
        ),
      ],
    );
  }
}
