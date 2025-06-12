import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';

import '../../../models/diagnose_model.dart';
import '../../../models/light_data_model.dart';
import '../../../models/patient_model.dart';
import '../../../theme/colors.dart';
import '../../../viewmodel/clinician/patient_detail_viewmodel.dart';
import '../patient_light_data_widgets/light_recommendations_card.dart';
import 'clinician_patient_diagnose_card.dart';



class CombinedPatientInfoCard extends StatelessWidget {
  final Patient patient;
  final List<Diagnosis> diagnoses;

  const CombinedPatientInfoCard({
    super.key,
    required this.patient,
    required this.diagnoses,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PatientDetailViewModel>(context, listen: true);
    final int rmeqScore = viewModel.rmeqScore.toInt();
    final List<LightData> lightData = viewModel.rawLightData;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
          collapsedBackgroundColor: generalBox,
          backgroundColor: generalBox,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          trailing: Icon(Icons.expand_more, color: Colors.white70),
          title: Text(
            'Patientoplysninger',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Navn', '${patient.firstName} ${patient.lastName}'),
                  _infoRow('CPR', patient.cpr ?? ''),
                  if (patient.street?.isNotEmpty ?? false)
                    _infoRow('Adresse', patient.street!),
                  if (patient.zipCode != null && patient.city != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: _iconRow(
                        null,
                        '${patient.zipCode} ${patient.city}',
                        customIcon: Icon(Ionicons.location_outline, size: 20.sp, color: Colors.white70),
                      ),
                    ),
                  SizedBox(height: 16.h),
                  _sectionTitle('Kontaktinformation'),
                  if (patient.phone?.isNotEmpty ?? false)
                    _iconRow(Icons.phone, patient.phone!),
                  if (patient.email?.isNotEmpty ?? false)
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: _iconRow(Icons.email, patient.email!),
                    ),
                ],
              ),
            ),
            LightRecommendationsCard(
              title: 'Kronotype anbefalinger',
              rmeqScore: rmeqScore,
              lightData: lightData,
              showChronotype: true,
            ),
            SizedBox(height: 10.h),
            DiagnosisCard(diagnoses: diagnoses),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _iconRow(IconData? icon, String value, {Widget? customIcon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.w, top: 2.h),
          child: customIcon ?? Icon(icon, size: 20.sp, color: Colors.white70),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.white70, fontSize: 15.sp, height: 1.4),
          ),
        ),
      ],
    );
  }
}
