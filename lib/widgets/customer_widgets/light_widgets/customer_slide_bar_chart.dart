// lib/widgets/customer_widgets/customer_light_slide_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'customer_light_daily_chart.dart';
import 'customer_light_monthly_chart.dart';
import 'customer_light_weekly_chart.dart';

//   1) Daglig lys-bar-graf   (henter selv via API: kræver rmeqScore + chronotype)
//   2) Ugentlig lys-bar-graf (henter selv via API: ingen ekstra parametre)
//   3) Månedlig lys-bar-graf  (henter selv via API: kræver rmeqScore + chronotype)
// Bemærk: Patient‐ID er hardcodet til “P3” i de enkelte “Customer”-widgets.
class CustomerLightSlideBarChart extends StatefulWidget {
  final int rmeqScore;
  final String chronotype;

  const CustomerLightSlideBarChart({
    super.key,
    required this.rmeqScore,
    required this.chronotype,
  });

  @override
  State<CustomerLightSlideBarChart> createState() =>
      _CustomerLightSlideBarChartState();
}

class _CustomerLightSlideBarChartState extends State<CustomerLightSlideBarChart> {
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1) DAGLIG GRAF → bruger rmeqScore + chronotype
    final dailyPage = CustomerLightDailyBarChart(
      rmeqScore: widget.rmeqScore,
      title: "Daglig lyseksponering",
    );

    // 2) UGENTLIG GRAF → ingen ekstra parametre
    final weeklyPage = const CustomerLightWeeklyBarChart();

    // 3) MÅNEDLIG GRAF → ingen ekstra parametre
    final monthlyPage = CustomerLightMonthlyBarChart(
    );

    final pages = <Widget>[
      dailyPage,
      weeklyPage,
      monthlyPage,
    ];

    return Column(
      children: [
        SizedBox(
          height: 280.h,
          child: PageView(
            controller: _pageController,
            children: pages,
          ),
        ),
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
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    width: isSelected ? 12.w : 8.w,
                    height: isSelected ? 12.w : 8.w,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white70 : Colors.white38,
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
