import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:ocutune_light_logger/widgets/customer_widgets/light_widgets/customer_light_daily_chart.dart';
import '../../../controller/chronotype_controller.dart';
import '../../../models/customer_model.dart';
import '../../../services/processing/dlmo_data_processing.dart';
import '../../../models/light_data_model.dart';
import '../../../widgets/customer_widgets/light_widgets/customer_light_recomandations_card.dart';

class CustomerOverviewScreen extends StatelessWidget {
  final Customer profile;
  final List<LightData> lightDataList;

  const CustomerOverviewScreen({
    super.key,
    required this.profile,
    required this.lightDataList,
  });

  @override
  Widget build(BuildContext context) {
    // Generér kunde-anbefalinger her
    final advancedCustomerRecs = generateAdvancedRecommendationsForCustomer(
      data: lightDataList,
      rMEQ: profile.rmeqScore,
    );

    final int rmeqScore = profile.rmeqScore;
    final chronoManager = ChronotypeManager(rmeqScore);
    final chronoLabel = chronoManager.getChronotypeLabel();
    final timeMap = chronoManager.getRecommendedTimes();
    final fmt = DateFormat('HH:mm');

    final List<String> detailRecommendations = [
      "Kronotype: $chronoLabel",
      "DLMO (Dim Light Melatonin Onset): ${fmt.format(timeMap['dlmo']!)}",
      "Opvågning (DLMO + 10 timer): ${fmt.format(timeMap['wake_time']!)}",
      "Sengetid (DLMO + 2 timer): ${fmt.format(timeMap['sleep_start']!)}",
      "Light-boost start: ${fmt.format(timeMap['lightboost_start']!)}",
      "Light-boost slut: ${fmt.format(timeMap['lightboost_end']!)}",
    ];


    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (_, __) {
        final int rmeq = profile.rmeqScore;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 6.h,
          ),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10.h),
              CustomerLightDailyBarChart(
                rmeqScore: rmeq,
              ),
              SizedBox(height: 40.h),
              CustomerLightRecommendationsCard(
                personalRecommendations: advancedCustomerRecs,
              ),
              CustomerLightRecommendationsCard(
                detailRecommendations: detailRecommendations,
              )
            ],
          ),
        );
      },
    );
  }
}
