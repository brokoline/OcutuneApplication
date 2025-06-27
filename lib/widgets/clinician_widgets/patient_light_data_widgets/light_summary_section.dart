import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodel/clinician/patient_detail_viewmodel.dart';
import '../../../../models/light_data_model.dart';
import '../../../services/processing/dlmo_data_processing.dart';

import 'clinician_recommandation_card.dart';
import 'light_slide_bar_chart.dart';

class LightSummarySection extends StatelessWidget {
  final String patientId;
  final int rmeqScore;

  // Valgfri MEQ‐score (kun til ScoreCard)
  final int? meqScore;

  const LightSummarySection({
    super.key,
    required this.patientId,
    required this.rmeqScore,
    this.meqScore,
  });

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<PatientDetailViewModel>(context);
    if (vm.isFetchingRaw && vm.rawLightData.isEmpty) {
      return SizedBox(
        height: 200.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Fejl under hentning
    if (vm.rawFetchError != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Center(
          child: Text(
            'Fejl ved hentning af lysdata: ${vm.rawFetchError}',
            style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Ingen data registreret
    if (!vm.isFetchingRaw && vm.rawLightData.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Text(
          'Ingen lysdata registreret endnu',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          textAlign: TextAlign.center,
        ),
      );
    }

    final List<LightData> allLightData = vm.rawLightData;

    // Generér kliniker-anbefalinger
    final List<String> clinicianRecs = LightDataProcessing(rMEQ: rmeqScore)
        .generateAdvancedRecommendations(
      data: allLightData,
      rMEQ: rmeqScore,
    );

    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Klinikers anbefalinger
          ClinicianRecommendationCard(
            recommendations: clinicianRecs,
          ),
          SizedBox(height: 20.h),

          // Graf: dag/uge/måned
          LightSlideBarChart(
            patientId: patientId,
            rmeqScore: rmeqScore,
          ),
        ],
      ),
    );
  }
}
