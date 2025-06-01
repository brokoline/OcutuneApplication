// lib/widgets/clinician_widgets/patient_light_data_widgets/light_slide_bar_chart.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/light_data_model.dart';
import '../../../utils/light_utils.dart';

// De tre graf‐filer ligger i samme mappe som denne fil:
import 'light_daily_bar_chart.dart';
import 'light_weekly_bar_chart.dart';
import 'light_monthly_bar_chart.dart';

/// En “slide‐widget” (PageView) med tre sider:
///   1) Daglig lys‐bar‐graf (tager List<LightData> rawData og rmeqScore)
///   2) Ugentlig lys‐bar‐graf (tager Map<String,double> luxPerDay og rmeqScore)
///   3) Månedlig lys‐bar‐graf (tager List<LightData> rawData og rmeqScore)
///
/// Vi modtager én samlet liste af [LightData] og en [rmeqScore] fra parent.
/// Ugentlig‐grafen laver selv et Map<String,double> vha. LightUtils.groupByWeekday().
class LightSlideBarChart extends StatefulWidget {
  /// Rå liste af lysmålinger (én LightData pr. timestamp).
  final List<LightData> rawData;

  /// rMEQ‐score (bruges, når vi beder de enkelte grafer om anbefalet boost‐tid).
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
    // -----------------------------------------------
    // 1) DAGLIG GRAF: sender rawData + rmeqScore videre
    // -----------------------------------------------
    final Widget dailyPage = LightDailyBarChart(
      rawData: widget.rawData,
      rmeqScore: widget.rmeqScore,
    );

    // -----------------------------------------------
    // 2) UGENTLIG GRAF: skal bruge Map<String,double> + rmeqScore
    //    Først kalder vi LightUtils.groupByWeekday(rawData),
    //    som returnerer Map<int,double> (1 = mandag … 7 = søndag).
    //    Dernæst omsætter vi nøglerne 1..7 → 'Man','Tir',…'Søn'.
    // -----------------------------------------------
    // groupByWeekday skal være en static metode i LightUtils:
    //   static Map<int,double> groupByWeekday(List<LightData> data) { … }
    final Map<int, double> intWeekMap = LightUtils.groupByWeekday(widget.rawData);

    // Lav en Map<String,double> i fast, kendt rækkefølge:
    final Map<String, double> stringWeekMap = {
      'Man': intWeekMap[1] ?? 0.0,
      'Tir': intWeekMap[2] ?? 0.0,
      'Ons': intWeekMap[3] ?? 0.0,
      'Tor': intWeekMap[4] ?? 0.0,
      'Fre': intWeekMap[5] ?? 0.0,
      'Lør': intWeekMap[6] ?? 0.0,
      'Søn': intWeekMap[7] ?? 0.0,
    };

    final Widget weeklyPage = LightWeeklyBarChart(
      luxPerDay: stringWeekMap,
    );

    // -----------------------------------------------
    // 3) MÅNEDLIG GRAF: sender rawData + rmeqScore videre
    //    Fordi: LightMonthlyBarChart i din kode tager List<LightData> rawData
    //    og rmeqScore til at beregne DLMO og boost.
    // -----------------------------------------------
    final Widget monthlyPage = LightMonthlyBarChart(
      rawData: widget.rawData,
      rmeqScore: widget.rmeqScore,
    );

    // -----------------------------------------------
    // 4) Saml alle tre sider i en liste
    // -----------------------------------------------
    final List<Widget> pages = [
      dailyPage,
      weeklyPage,
      monthlyPage,
    ];

    return Column(
      children: [
        // ------------------------------------------------
        // PageView med fast højde (kan justeres efter ønske)
        // ------------------------------------------------
        SizedBox(
          height: 320.h,
          child: PageView(
            controller: _pageController,
            children: pages,
          ),
        ),

        // ------------------------------------------------
        // Lidt luft og en “dot‐indikator” forneden
        // ------------------------------------------------
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
                    currentPage = _pageController.page ?? _pageController.initialPage.toDouble();
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
