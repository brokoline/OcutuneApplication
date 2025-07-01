import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'light_daily_bar_chart.dart';
import 'light_weekly_bar_chart.dart';
import 'light_monthly_bar_chart.dart';

//   1) Daglig lys-bar-graf   (henter selv via API: kræver patientId + rmeqScore)
//   2) Ugentlig lys-bar-graf (henter selv via API: kræver kun patientId)
//   3) Månedlig lys-bar-graf  (henter selv via API: kræver patientId + rmeqScore)
class LightSlideBarChart extends StatefulWidget {
  final String patientId;
  final int rmeqScore;

  const LightSlideBarChart({
    super.key,
    required this.patientId,
    required this.rmeqScore,
  });

  @override
  State<LightSlideBarChart> createState() => _LightSlideBarChartState();
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
    // 1) DAGLIG GRAF → henter selv via API (patientId + rmeqScore)
    final dailyPage = LightDailyBarChart(
      patientId: widget.patientId,
      rmeqScore: widget.rmeqScore,
    );

    // 2) UGENTLIG GRAF → henter selv via API (kun patientId)
    final weeklyPage = LightWeeklyBarChart(
      patientId: widget.patientId,
    );

    // 3) MÅNEDLIG GRAF → henter selv via API (patientId + rmeqScore)
    final monthlyPage = LightMonthlyBarChart(
      patientId: widget.patientId,
    );

    // 4) Saml de tre sider i en PageView
    final pages = <Widget>[
      dailyPage,
      weeklyPage,
      monthlyPage,
    ];

    return Column(
      children: [
        SizedBox(
          height: 270.h,
          child: PageView(
            controller: _pageController,
            children: pages,
          ),
        ),
        SizedBox(height: 1.h),
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
                    currentPage = _pageController.page ??
                        _pageController.initialPage.toDouble();
                  }
                  final isSelected = currentPage.round() == index;
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
