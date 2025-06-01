// lib/widgets/clinician_widgets/patient_light_data_widgets/light_slide_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';

// De tre graf‐filer ligger i samme mappe som denne fil:
import 'light_daily_bar_chart.dart';
import 'light_weekly_bar_chart.dart';
import 'light_monthly_bar_chart.dart';

// En “slide‐widget” (PageView) med tre sider:
//   1) Daglig lys‐bar‐graf  (tager List<LightData> rawData + rmeqScore)
//   2) Ugentlig lys‐bar‐graf(tager List<LightData> rawData)
//   3) Månedlig lys‐bar‐graf (tager List<LightData> rawData + rmeqScore)
//
// Vi modtager én samlet liste af [LightData] og en [rmeqScore] fra parent.
// Ugentlig‐grafen laver nu selv et “groupByWeekday” internt.
class LightSlideBarChart extends StatefulWidget {
  // Hele listen af lysmålinger (én LightData pr. timestamp).
  final List<LightData> rawData;

  // rMEQ‐score (bruges, når vi beder daglig og månedlig graf om boost‐tid).
  final int rmeqScore;

  const LightSlideBarChart({
    Key? key,
    required this.rawData,
    required this.rmeqScore,
  }) : super(key: key);

  @override
  _LightSlideBarChartState createState() => _LightSlideBarChartState();
}

class _LightSlideBarChartState extends State<LightSlideBarChart> {
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ──────────────────────────────────────────────────────────
    // 1) DAGLIG GRAF → sender både rawData + rmeqScore videre
    final Widget dailyPage = LightDailyBarChart(
      rawData: widget.rawData,
      rmeqScore: widget.rmeqScore,
    );

    // ──────────────────────────────────────────────────────────
    // 2) UGENTLIG GRAF → sender rawData direkte (indenfor
    //    LightWeeklyBarChart filtreres per ugedag selv)
    final Widget weeklyPage = LightWeeklyBarChart(
      rawData: widget.rawData,
    );

    // ──────────────────────────────────────────────────────────
    // 3) MÅNEDLIG GRAF → sender rawData + rmeqScore videre
    final Widget monthlyPage = LightMonthlyBarChart(
      rawData: widget.rawData,
      rmeqScore: widget.rmeqScore,
    );

    // ──────────────────────────────────────────────────────────
    // 4) Saml de tre sider
    final List<Widget> pages = [
      dailyPage,
      weeklyPage,
      monthlyPage,
    ];

    return Column(
      children: [
        // PageView med fast højde (juster efter ønske)
        SizedBox(
          height: 320.h,
          child: PageView(
            controller: _pageController,
            children: pages,
          ),
        ),

        // Dot‐indikator forneden
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            pages.length,
                (index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double currentPage = 0;
                  if (_pageController.hasClients) {
                    currentPage =
                        _pageController.page ?? _pageController.initialPage.toDouble();
                  }
                  final bool isSelected = currentPage.round() == index;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    width: isSelected ? 12.w : 8.w,
                    height: isSelected ? 12.w : 8.w,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
